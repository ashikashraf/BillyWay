-- Phase 4: Adjustments and Reporting Database Migration

-- 1. Create credit_notes table (Sales Returns & Adjustments)
CREATE TABLE IF NOT EXISTS credit_notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    note_number VARCHAR(255) NOT NULL,
    original_invoice_id UUID REFERENCES sales_invoices(id) ON DELETE SET NULL,
    original_invoice_number VARCHAR(255),
    date DATE NOT NULL,
    customer_name VARCHAR(255) NOT NULL,
    gstin VARCHAR(15),
    supply_type VARCHAR(50) DEFAULT 'INTRA_STATE',
    reason VARCHAR(255),
    subtotal NUMERIC DEFAULT 0,
    cgst NUMERIC DEFAULT 0,
    sgst NUMERIC DEFAULT 0,
    igst NUMERIC DEFAULT 0,
    cess NUMERIC DEFAULT 0,
    total_tax NUMERIC DEFAULT 0,
    total_amount NUMERIC DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS credit_note_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    credit_note_id UUID REFERENCES credit_notes(id) ON DELETE CASCADE,
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

-- 2. Create debit_notes table (Purchase Returns & Adjustments)
CREATE TABLE IF NOT EXISTS debit_notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    note_number VARCHAR(255) NOT NULL,
    original_invoice_id UUID REFERENCES purchase_invoices(id) ON DELETE SET NULL,
    original_invoice_number VARCHAR(255),
    vendor_bill_no VARCHAR(255),
    date DATE NOT NULL,
    vendor_name VARCHAR(255) NOT NULL,
    gstin VARCHAR(15),
    supply_type VARCHAR(50) DEFAULT 'INTRA_STATE',
    reason VARCHAR(255),
    subtotal NUMERIC DEFAULT 0,
    cgst NUMERIC DEFAULT 0,
    sgst NUMERIC DEFAULT 0,
    igst NUMERIC DEFAULT 0,
    cess NUMERIC DEFAULT 0,
    total_tax NUMERIC DEFAULT 0,
    total_amount NUMERIC DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS debit_note_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    debit_note_id UUID REFERENCES debit_notes(id) ON DELETE CASCADE,
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

-- 3. Enable RLS
ALTER TABLE credit_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_note_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE debit_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE debit_note_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all authenticated users to read credit notes" ON credit_notes FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow all authenticated users to insert credit notes" ON credit_notes FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow all authenticated users to read credit note items" ON credit_note_items FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow all authenticated users to insert credit note items" ON credit_note_items FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Allow all authenticated users to read debit notes" ON debit_notes FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow all authenticated users to insert debit notes" ON debit_notes FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow all authenticated users to read debit note items" ON debit_note_items FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow all authenticated users to insert debit note items" ON debit_note_items FOR INSERT TO authenticated WITH CHECK (true);
