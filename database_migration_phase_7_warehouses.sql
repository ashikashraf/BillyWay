-- Phase 7: Fully Warehouse-Aware Operations Database Migration

-- 1. Add warehouse_id to all primary billing documents
ALTER TABLE sales_invoices ADD COLUMN IF NOT EXISTS warehouse_id UUID;
ALTER TABLE purchase_invoices ADD COLUMN IF NOT EXISTS warehouse_id UUID;
ALTER TABLE credit_notes ADD COLUMN IF NOT EXISTS warehouse_id UUID;
ALTER TABLE debit_notes ADD COLUMN IF NOT EXISTS warehouse_id UUID;

-- 2. Update Trigger Function for Sales Invoices
CREATE OR REPLACE FUNCTION update_stock_on_sale()
RETURNS TRIGGER AS $$
DECLARE
    v_doc_no VARCHAR(255);
    v_warehouse_id UUID;
BEGIN
    SELECT invoice_number, warehouse_id INTO v_doc_no, v_warehouse_id 
    FROM sales_invoices WHERE id = NEW.sales_invoice_id;
    
    INSERT INTO stock_ledger (product_name, transaction_type, document_ref, qty_in, qty_out, warehouse_id)
    VALUES (NEW.product_name, 'SALE', v_doc_no, 0, NEW.qty, v_warehouse_id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Update Trigger Function for Purchase Invoices
CREATE OR REPLACE FUNCTION update_stock_on_purchase()
RETURNS TRIGGER AS $$
DECLARE
    v_doc_no VARCHAR(255);
    v_warehouse_id UUID;
BEGIN
    SELECT internal_ref_no, warehouse_id INTO v_doc_no, v_warehouse_id 
    FROM purchase_invoices WHERE id = NEW.purchase_invoice_id;
    
    INSERT INTO stock_ledger (product_name, transaction_type, document_ref, qty_in, qty_out, warehouse_id)
    VALUES (NEW.product_name, 'PURCHASE', v_doc_no, NEW.qty, 0, v_warehouse_id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Update Trigger Function for Credit Notes
CREATE OR REPLACE FUNCTION update_stock_on_sales_return()
RETURNS TRIGGER AS $$
DECLARE
    v_doc_no VARCHAR(255);
    v_warehouse_id UUID;
BEGIN
    SELECT note_number, warehouse_id INTO v_doc_no, v_warehouse_id 
    FROM credit_notes WHERE id = NEW.credit_note_id;
    
    INSERT INTO stock_ledger (product_name, transaction_type, document_ref, qty_in, qty_out, warehouse_id)
    VALUES (NEW.product_name, 'SALES_RETURN', v_doc_no, NEW.qty, 0, v_warehouse_id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Update Trigger Function for Debit Notes
CREATE OR REPLACE FUNCTION update_stock_on_purchase_return()
RETURNS TRIGGER AS $$
DECLARE
    v_doc_no VARCHAR(255);
    v_warehouse_id UUID;
BEGIN
    SELECT note_number, warehouse_id INTO v_doc_no, v_warehouse_id 
    FROM debit_notes WHERE id = NEW.debit_note_id;
    
    INSERT INTO stock_ledger (product_name, transaction_type, document_ref, qty_in, qty_out, warehouse_id)
    VALUES (NEW.product_name, 'PURCHASE_RETURN', v_doc_no, 0, NEW.qty, v_warehouse_id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
