-- Phase 2.1: Document Sequence Engine (GST & Legal Compliance)

DROP TABLE IF EXISTS document_sequences CASCADE;

-- 1. Create the Document Sequences table
CREATE TABLE IF NOT EXISTS document_sequences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_type VARCHAR(50) NOT NULL, -- e.g., 'SALES_INVOICE', 'PURCHASE_INVOICE', 'CREDIT_NOTE'
    financial_year VARCHAR(10) NOT NULL, -- e.g., '2026-27'
    prefix VARCHAR(20) NOT NULL, -- e.g., 'INV/'
    current_value INTEGER DEFAULT 0,
    branch_id UUID, -- Optional, if they want separate sequences per branch
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Ensure we only have one active sequence tracker per type, year, prefix, and branch.
    CONSTRAINT doc_seq_unique_idx UNIQUE NULLS NOT DISTINCT (document_type, financial_year, prefix, branch_id)
);

-- 2. Enable RLS on the table (Optional but good practice)
ALTER TABLE document_sequences ENABLE ROW LEVEL SECURITY;
-- Allow all authenticated users to read/update sequences (adjust policies as needed for your app's security model)
CREATE POLICY "Allow all authenticated users to read sequences" ON document_sequences FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow all authenticated users to insert sequences" ON document_sequences FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow all authenticated users to update sequences" ON document_sequences FOR UPDATE TO authenticated USING (true);


-- 3. Create the RPC Function to generate strictly sequential, gapless numbers
-- This function is ATOMIC, meaning if two users try to generate an invoice at the exact
-- same millisecond, the database will safely lock the row and give them unique sequential numbers.
CREATE OR REPLACE FUNCTION get_next_document_number(
    p_doc_type VARCHAR,
    p_fin_year VARCHAR,
    p_prefix VARCHAR,
    p_branch_id UUID DEFAULT NULL
) RETURNS VARCHAR AS $$
DECLARE
    v_next_val INTEGER;
    v_doc_number VARCHAR;
BEGIN
    -- Step 1: Insert a new sequence tracker if it doesn't exist for this Year/Type yet
    INSERT INTO document_sequences (document_type, financial_year, prefix, branch_id, current_value)
    VALUES (p_doc_type, p_fin_year, p_prefix, p_branch_id, 0)
    ON CONFLICT ON CONSTRAINT doc_seq_unique_idx DO NOTHING;

    -- Step 2: Atomically increment the sequence and lock the row to prevent race conditions
    UPDATE document_sequences
    SET current_value = current_value + 1,
        updated_at = NOW()
    WHERE document_type = p_doc_type
      AND financial_year = p_fin_year
      AND prefix = p_prefix
      AND (branch_id = p_branch_id OR (branch_id IS NULL AND p_branch_id IS NULL))
    RETURNING current_value INTO v_next_val;

    -- Step 3: Format the final string. 
    -- e.g. prefix="INV/" + fin_year="2026-27" + "/" + padded_number="0001"
    -- Result: INV/2026-27/0001
    -- (LPAD adds leading zeros to make it 4 digits long. E.g. 1 -> 0001, 15 -> 0015)
    v_doc_number := p_prefix || p_fin_year || '/' || LPAD(v_next_val::TEXT, 4, '0');
    
    RETURN v_doc_number;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
