-- Phase 3: Purchases and ITC Ledger Database Migration

-- 1. Create purchase_invoices table
CREATE TABLE IF NOT EXISTS purchase_invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    internal_ref_no VARCHAR(255) NOT NULL,
    vendor_bill_no VARCHAR(255),
    date DATE NOT NULL,
    due_date DATE,
    vendor_name VARCHAR(255) NOT NULL,
    gstin VARCHAR(15),
    supply_type VARCHAR(50) DEFAULT 'INTRA_STATE',
    subtotal NUMERIC DEFAULT 0,
    cgst NUMERIC DEFAULT 0,
    sgst NUMERIC DEFAULT 0,
    igst NUMERIC DEFAULT 0,
    cess NUMERIC DEFAULT 0,
    total_tax NUMERIC DEFAULT 0,
    total_amount NUMERIC DEFAULT 0,
    status VARCHAR(50) DEFAULT 'Unpaid',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Create purchase_invoice_items table
CREATE TABLE IF NOT EXISTS purchase_invoice_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    purchase_invoice_id UUID REFERENCES purchase_invoices(id) ON DELETE CASCADE,
    product_name VARCHAR(255) NOT NULL,
    hsn_sac_code VARCHAR(8),
    qty NUMERIC NOT NULL,
    rate NUMERIC NOT NULL,
    gst_rate NUMERIC DEFAULT 18.0,
    taxable_value NUMERIC DEFAULT 0,
    cgst_amount NUMERIC DEFAULT 0,
    sgst_amount NUMERIC DEFAULT 0,
    igst_amount NUMERIC DEFAULT 0,
    cess_amount NUMERIC DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Update itc_ledger table to link it to purchase_invoices
-- (We created the skeleton of itc_ledger in Phase 2)
-- We will use a trigger to automatically update the ITC ledger when a purchase is made.

CREATE OR REPLACE FUNCTION update_itc_ledger_on_purchase()
RETURNS TRIGGER AS $$
BEGIN
    -- Automatically insert into ITC Ledger if GST is involved
    IF NEW.total_tax > 0 AND NEW.gstin IS NOT NULL THEN
        INSERT INTO itc_ledger (
            purchase_invoice_id, 
            supplier_gstin, 
            itc_eligible, 
            itc_available
        ) VALUES (
            NEW.id,
            NEW.gstin,
            TRUE, -- By default assume eligible, user can block it later
            NEW.total_tax
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if exists to prevent duplicates on rerun
DROP TRIGGER IF EXISTS after_purchase_insert ON purchase_invoices;

-- Create the trigger
CREATE TRIGGER after_purchase_insert
AFTER INSERT ON purchase_invoices
FOR EACH ROW
EXECUTE FUNCTION update_itc_ledger_on_purchase();

-- 4. Enable RLS
ALTER TABLE purchase_invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_invoice_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all authenticated users to read purchases" ON purchase_invoices FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow all authenticated users to insert purchases" ON purchase_invoices FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow all authenticated users to update purchases" ON purchase_invoices FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Allow all authenticated users to delete purchases" ON purchase_invoices FOR DELETE TO authenticated USING (true);

CREATE POLICY "Allow all authenticated users to read purchase items" ON purchase_invoice_items FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow all authenticated users to insert purchase items" ON purchase_invoice_items FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow all authenticated users to update purchase items" ON purchase_invoice_items FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Allow all authenticated users to delete purchase items" ON purchase_invoice_items FOR DELETE TO authenticated USING (true);
