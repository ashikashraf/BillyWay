-- Phase 5: Inventory & Stock Engine Database Migration

-- 1. Create stock_ledger table
CREATE TABLE IF NOT EXISTS stock_ledger (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_name VARCHAR(255) NOT NULL,
    transaction_type VARCHAR(50) NOT NULL, -- OPENING, SALE, PURCHASE, SALES_RETURN, PURCHASE_RETURN, ADJ
    document_ref VARCHAR(255),             -- invoice number, note number, etc.
    qty_in NUMERIC DEFAULT 0,
    qty_out NUMERIC DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enable RLS on stock_ledger
ALTER TABLE stock_ledger ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all authenticated users to read stock ledger" ON stock_ledger FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow all authenticated users to insert stock ledger" ON stock_ledger FOR INSERT TO authenticated WITH CHECK (true);

-- 2. Trigger Function for Sales Invoices (Reduces Stock)
CREATE OR REPLACE FUNCTION update_stock_on_sale()
RETURNS TRIGGER AS $$
DECLARE
    v_doc_no VARCHAR(255);
BEGIN
    -- Fetch the invoice number from parent table
    SELECT invoice_number INTO v_doc_no FROM sales_invoices WHERE id = NEW.sales_invoice_id;
    
    INSERT INTO stock_ledger (product_name, transaction_type, document_ref, qty_in, qty_out)
    VALUES (NEW.product_name, 'SALE', v_doc_no, 0, NEW.qty);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_stock_on_sale ON sales_invoice_items;
CREATE TRIGGER trg_update_stock_on_sale
AFTER INSERT ON sales_invoice_items
FOR EACH ROW
EXECUTE FUNCTION update_stock_on_sale();


-- 3. Trigger Function for Purchase Invoices (Increases Stock)
CREATE OR REPLACE FUNCTION update_stock_on_purchase()
RETURNS TRIGGER AS $$
DECLARE
    v_doc_no VARCHAR(255);
BEGIN
    SELECT internal_ref_no INTO v_doc_no FROM purchase_invoices WHERE id = NEW.purchase_invoice_id;
    
    INSERT INTO stock_ledger (product_name, transaction_type, document_ref, qty_in, qty_out)
    VALUES (NEW.product_name, 'PURCHASE', v_doc_no, NEW.qty, 0);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_stock_on_purchase ON purchase_invoice_items;
CREATE TRIGGER trg_update_stock_on_purchase
AFTER INSERT ON purchase_invoice_items
FOR EACH ROW
EXECUTE FUNCTION update_stock_on_purchase();


-- 4. Trigger Function for Credit Notes (Sales Return - Increases Stock)
CREATE OR REPLACE FUNCTION update_stock_on_sales_return()
RETURNS TRIGGER AS $$
DECLARE
    v_doc_no VARCHAR(255);
BEGIN
    SELECT note_number INTO v_doc_no FROM credit_notes WHERE id = NEW.credit_note_id;
    
    INSERT INTO stock_ledger (product_name, transaction_type, document_ref, qty_in, qty_out)
    VALUES (NEW.product_name, 'SALES_RETURN', v_doc_no, NEW.qty, 0);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_stock_on_sales_return ON credit_note_items;
CREATE TRIGGER trg_update_stock_on_sales_return
AFTER INSERT ON credit_note_items
FOR EACH ROW
EXECUTE FUNCTION update_stock_on_sales_return();


-- 5. Trigger Function for Debit Notes (Purchase Return - Reduces Stock)
CREATE OR REPLACE FUNCTION update_stock_on_purchase_return()
RETURNS TRIGGER AS $$
DECLARE
    v_doc_no VARCHAR(255);
BEGIN
    SELECT note_number INTO v_doc_no FROM debit_notes WHERE id = NEW.debit_note_id;
    
    INSERT INTO stock_ledger (product_name, transaction_type, document_ref, qty_in, qty_out)
    VALUES (NEW.product_name, 'PURCHASE_RETURN', v_doc_no, 0, NEW.qty);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_stock_on_purchase_return ON debit_note_items;
CREATE TRIGGER trg_update_stock_on_purchase_return
AFTER INSERT ON debit_note_items
FOR EACH ROW
EXECUTE FUNCTION update_stock_on_purchase_return();


-- 6. Helper View to calculate Real-time Stock per product
CREATE OR REPLACE VIEW current_stock_view AS
SELECT 
    product_name,
    SUM(qty_in) - SUM(qty_out) AS available_stock
FROM stock_ledger
GROUP BY product_name;
