-- Phase 6: Inventory Transfers Database Migration

-- 1. Add warehouse tracking to stock_ledger
ALTER TABLE stock_ledger ADD COLUMN IF NOT EXISTS warehouse_id UUID;

-- Recreate the stock view to include warehouse tracking
DROP VIEW IF EXISTS current_stock_view;
CREATE VIEW current_stock_view AS
SELECT 
    product_name,
    warehouse_id,
    SUM(qty_in) - SUM(qty_out) AS available_stock
FROM stock_ledger
GROUP BY product_name, warehouse_id;


-- 2. Create stock_transfers table
CREATE TABLE IF NOT EXISTS stock_transfers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transfer_number VARCHAR(100) NOT NULL,
    date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    source_warehouse_id UUID NOT NULL,
    destination_warehouse_id UUID NOT NULL,
    status VARCHAR(50) DEFAULT 'PENDING', -- PENDING, COMPLETED, CANCELLED
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE stock_transfers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all authenticated users to read transfers" ON stock_transfers FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow all authenticated users to insert transfers" ON stock_transfers FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow all authenticated users to update transfers" ON stock_transfers FOR UPDATE TO authenticated USING (true);


-- 3. Create stock_transfer_items table
CREATE TABLE IF NOT EXISTS stock_transfer_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transfer_id UUID REFERENCES stock_transfers(id) ON DELETE CASCADE,
    product_name VARCHAR(255) NOT NULL,
    qty NUMERIC NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE stock_transfer_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all authenticated users to read transfer items" ON stock_transfer_items FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow all authenticated users to insert transfer items" ON stock_transfer_items FOR INSERT TO authenticated WITH CHECK (true);


-- 4. Trigger Function for Stock Transfers
-- This triggers when a transfer's status changes to 'COMPLETED'
CREATE OR REPLACE FUNCTION process_stock_transfer()
RETURNS TRIGGER AS $$
DECLARE
    item RECORD;
BEGIN
    -- Only process if status changed from something else to COMPLETED
    IF NEW.status = 'COMPLETED' AND (OLD.status IS DISTINCT FROM 'COMPLETED') THEN
        
        -- Loop through all items in this transfer
        FOR item IN SELECT * FROM stock_transfer_items WHERE transfer_id = NEW.id LOOP
            
            -- 1. Deduct from Source Warehouse
            INSERT INTO stock_ledger (
                product_name, transaction_type, document_ref, 
                qty_in, qty_out, warehouse_id
            )
            VALUES (
                item.product_name, 'TRANSFER_OUT', NEW.transfer_number, 
                0, item.qty, NEW.source_warehouse_id
            );

            -- 2. Add to Destination Warehouse
            INSERT INTO stock_ledger (
                product_name, transaction_type, document_ref, 
                qty_in, qty_out, warehouse_id
            )
            VALUES (
                item.product_name, 'TRANSFER_IN', NEW.transfer_number, 
                item.qty, 0, NEW.destination_warehouse_id
            );
            
        END LOOP;
        
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_process_stock_transfer ON stock_transfers;
CREATE TRIGGER trg_process_stock_transfer
AFTER UPDATE ON stock_transfers
FOR EACH ROW
EXECUTE FUNCTION process_stock_transfer();
