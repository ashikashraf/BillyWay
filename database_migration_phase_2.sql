-- Phase 2 GST Compliance Database Migration (Sales & Master Data)

-- 1. Updates to ledgers table (Customers/Suppliers)
ALTER TABLE ledgers ADD COLUMN IF NOT EXISTS gstin VARCHAR(15);
ALTER TABLE ledgers ADD COLUMN IF NOT EXISTS pan VARCHAR(10);
ALTER TABLE ledgers ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE ledgers ADD COLUMN IF NOT EXISTS state_code VARCHAR(2);

-- 2. Updates to products table
ALTER TABLE products ADD COLUMN IF NOT EXISTS hsn_sac_code VARCHAR(8);
ALTER TABLE products ADD COLUMN IF NOT EXISTS gst_rate NUMERIC DEFAULT 18.0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS is_service BOOLEAN DEFAULT false;

-- 3. Updates to sales_invoices table (The Core Invoice)
ALTER TABLE sales_invoices ADD COLUMN IF NOT EXISTS invoice_type VARCHAR(20) DEFAULT 'B2C'; -- B2B, B2C, EXPORT
ALTER TABLE sales_invoices ADD COLUMN IF NOT EXISTS supply_type VARCHAR(20) DEFAULT 'INTRA_STATE'; -- INTRA_STATE, INTER_STATE
ALTER TABLE sales_invoices ADD COLUMN IF NOT EXISTS irn VARCHAR(64);
ALTER TABLE sales_invoices ADD COLUMN IF NOT EXISTS qr_code_data TEXT;
ALTER TABLE sales_invoices ADD COLUMN IF NOT EXISTS reverse_charge BOOLEAN DEFAULT false;
ALTER TABLE sales_invoices ADD COLUMN IF NOT EXISTS place_of_supply VARCHAR(2);

-- 4. Updates to sales_invoice_items table (Item breakdown)
ALTER TABLE sales_invoice_items ADD COLUMN IF NOT EXISTS hsn_sac_code VARCHAR(8);
ALTER TABLE sales_invoice_items ADD COLUMN IF NOT EXISTS gst_rate NUMERIC DEFAULT 18.0;
ALTER TABLE sales_invoice_items ADD COLUMN IF NOT EXISTS taxable_value NUMERIC DEFAULT 0;
ALTER TABLE sales_invoice_items ADD COLUMN IF NOT EXISTS cgst_amount NUMERIC DEFAULT 0;
ALTER TABLE sales_invoice_items ADD COLUMN IF NOT EXISTS sgst_amount NUMERIC DEFAULT 0;
ALTER TABLE sales_invoice_items ADD COLUMN IF NOT EXISTS igst_amount NUMERIC DEFAULT 0;
ALTER TABLE sales_invoice_items ADD COLUMN IF NOT EXISTS cess_amount NUMERIC DEFAULT 0;

-- 5. New Table: itc_ledger (Input Tax Credit for Purchases)
CREATE TABLE IF NOT EXISTS itc_ledger (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    purchase_invoice_id UUID, -- Will link to purchase_invoices later
    supplier_gstin VARCHAR(15),
    itc_eligible BOOLEAN DEFAULT false,
    blockage_percentage NUMERIC DEFAULT 0,
    blockage_reason VARCHAR(255),
    itc_available NUMERIC DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
