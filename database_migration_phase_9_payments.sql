-- Phase 9: Party Balances & Payments

-- 1. Add ledger_id to all billing tables to correctly link to the party
ALTER TABLE sales_invoices ADD COLUMN IF NOT EXISTS ledger_id UUID;
ALTER TABLE purchase_invoices ADD COLUMN IF NOT EXISTS ledger_id UUID;
ALTER TABLE credit_notes ADD COLUMN IF NOT EXISTS ledger_id UUID;
ALTER TABLE debit_notes ADD COLUMN IF NOT EXISTS ledger_id UUID;

-- 2. Create the unified party ledger for tracking Accounts Receivable / Payable
CREATE TABLE IF NOT EXISTS party_ledger_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ledger_id UUID NOT NULL,
    transaction_date DATE NOT NULL,
    document_type VARCHAR(50) NOT NULL, -- SALES_INVOICE, PURCHASE_INVOICE, PAYMENT_RECEIPT, PAYMENT_OUT, CREDIT_NOTE, DEBIT_NOTE
    document_id UUID,
    document_number VARCHAR(100),
    amount_dr NUMERIC DEFAULT 0, -- Increases Customer Balance, Decreases Vendor Balance (Debit)
    amount_cr NUMERIC DEFAULT 0, -- Decreases Customer Balance, Increases Vendor Balance (Credit)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Create the Payments table to record actual money received or paid
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payment_number VARCHAR(50) NOT NULL,
    ledger_id UUID NOT NULL,
    payment_type VARCHAR(20) NOT NULL, -- 'RECEIPT', 'PAYMENT'
    payment_mode VARCHAR(50) NOT NULL, -- 'CASH', 'BANK', 'UPI', 'CHEQUE'
    amount NUMERIC NOT NULL,
    payment_date DATE NOT NULL,
    reference_no VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Enable RLS
ALTER TABLE party_ledger_entries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all authenticated users to read party ledger" ON party_ledger_entries FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow admin users to insert party ledger" ON party_ledger_entries FOR INSERT TO authenticated WITH CHECK (true);

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all authenticated users to read payments" ON payments FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow admin users to insert payments" ON payments FOR INSERT TO authenticated WITH CHECK (true);

-- 5. Triggers to Auto-Post to Party Ledger

-- 5.1 Sales Invoice (Debit Customer: They owe you more money)
CREATE OR REPLACE FUNCTION trg_sales_party_ledger() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ledger_id IS NOT NULL THEN
        INSERT INTO party_ledger_entries (ledger_id, transaction_date, document_type, document_id, document_number, amount_dr, amount_cr)
        VALUES (NEW.ledger_id, NEW.date, 'SALES_INVOICE', NEW.id, NEW.invoice_number, NEW.total_amount, 0);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sales_party_ledger_after_insert ON sales_invoices;
CREATE TRIGGER trg_sales_party_ledger_after_insert
AFTER INSERT ON sales_invoices
FOR EACH ROW EXECUTE FUNCTION trg_sales_party_ledger();

-- 5.2 Purchase Invoice (Credit Vendor: You owe them more money)
CREATE OR REPLACE FUNCTION trg_purchase_party_ledger() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ledger_id IS NOT NULL THEN
        INSERT INTO party_ledger_entries (ledger_id, transaction_date, document_type, document_id, document_number, amount_dr, amount_cr)
        VALUES (NEW.ledger_id, NEW.date, 'PURCHASE_INVOICE', NEW.id, NEW.internal_ref_no, 0, NEW.total_amount);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_purchase_party_ledger_after_insert ON purchase_invoices;
CREATE TRIGGER trg_purchase_party_ledger_after_insert
AFTER INSERT ON purchase_invoices
FOR EACH ROW EXECUTE FUNCTION trg_purchase_party_ledger();

-- 5.3 Credit Note (Credit Customer: Reverses Sales Invoice, so they owe you less)
CREATE OR REPLACE FUNCTION trg_credit_note_party_ledger() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ledger_id IS NOT NULL THEN
        INSERT INTO party_ledger_entries (ledger_id, transaction_date, document_type, document_id, document_number, amount_dr, amount_cr)
        VALUES (NEW.ledger_id, NEW.date, 'CREDIT_NOTE', NEW.id, NEW.note_number, 0, NEW.total_amount);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_credit_note_party_ledger_after_insert ON credit_notes;
CREATE TRIGGER trg_credit_note_party_ledger_after_insert
AFTER INSERT ON credit_notes
FOR EACH ROW EXECUTE FUNCTION trg_credit_note_party_ledger();

-- 5.4 Debit Note (Debit Vendor: Reverses Purchase Invoice, so you owe them less)
CREATE OR REPLACE FUNCTION trg_debit_note_party_ledger() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ledger_id IS NOT NULL THEN
        INSERT INTO party_ledger_entries (ledger_id, transaction_date, document_type, document_id, document_number, amount_dr, amount_cr)
        VALUES (NEW.ledger_id, NEW.date, 'DEBIT_NOTE', NEW.id, NEW.note_number, NEW.total_amount, 0);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_debit_note_party_ledger_after_insert ON debit_notes;
CREATE TRIGGER trg_debit_note_party_ledger_after_insert
AFTER INSERT ON debit_notes
FOR EACH ROW EXECUTE FUNCTION trg_debit_note_party_ledger();

-- 5.5 Payments (Receiving money = Credit Customer. Paying money = Debit Vendor)
CREATE OR REPLACE FUNCTION trg_payments_party_ledger() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.payment_type = 'RECEIPT' THEN
        -- Receipt from Customer: They owe you less, so we Credit their account
        INSERT INTO party_ledger_entries (ledger_id, transaction_date, document_type, document_id, document_number, amount_dr, amount_cr)
        VALUES (NEW.ledger_id, NEW.payment_date, 'PAYMENT_RECEIPT', NEW.id, NEW.payment_number, 0, NEW.amount);
    ELSIF NEW.payment_type = 'PAYMENT' THEN
        -- Payment to Vendor: You owe them less, so we Debit their account
        INSERT INTO party_ledger_entries (ledger_id, transaction_date, document_type, document_id, document_number, amount_dr, amount_cr)
        VALUES (NEW.ledger_id, NEW.payment_date, 'PAYMENT_OUT', NEW.id, NEW.payment_number, NEW.amount, 0);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_payments_party_ledger_after_insert ON payments;
CREATE TRIGGER trg_payments_party_ledger_after_insert
AFTER INSERT ON payments
FOR EACH ROW EXECUTE FUNCTION trg_payments_party_ledger();

-- 6. Create View for Real-time Balances
CREATE OR REPLACE VIEW current_party_balances AS
SELECT 
    l.id as ledger_id,
    l.ledger_name,
    lg.group_name as ledger_group,
    COALESCE(SUM(ple.amount_dr), 0) as total_debit,
    COALESCE(SUM(ple.amount_cr), 0) as total_credit,
    -- For Sundry Debtors (Customers), Balance = DR - CR
    -- For Sundry Creditors (Vendors), Balance = CR - DR
    CASE 
        WHEN lg.group_name ILIKE '%Debtor%' OR lg.group_name ILIKE '%Customer%' THEN COALESCE(SUM(ple.amount_dr) - SUM(ple.amount_cr), 0)
        WHEN lg.group_name ILIKE '%Creditor%' OR lg.group_name ILIKE '%Vendor%' THEN COALESCE(SUM(ple.amount_cr) - SUM(ple.amount_dr), 0)
        ELSE COALESCE(SUM(ple.amount_dr) - SUM(ple.amount_cr), 0)
    END as current_balance
FROM ledgers l
LEFT JOIN ledger_groups lg ON l.ledger_group_id = lg.id
LEFT JOIN party_ledger_entries ple ON l.id = ple.ledger_id
GROUP BY l.id, l.ledger_name, lg.group_name;
