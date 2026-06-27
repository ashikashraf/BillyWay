-- Phase 9.1: Optional Multi-Warehouse Settings

-- Add columns to company_settings
ALTER TABLE company_settings ADD COLUMN IF NOT EXISTS enable_multi_warehouse BOOLEAN DEFAULT false;
ALTER TABLE company_settings ADD COLUMN IF NOT EXISTS default_warehouse_id UUID;

-- If there is a default warehouse, this could be enforced via foreign key, but it's okay without it.
-- We can add a foreign key reference just to be safe.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_company_settings_warehouse'
    ) THEN
        ALTER TABLE company_settings 
        ADD CONSTRAINT fk_company_settings_warehouse 
        FOREIGN KEY (default_warehouse_id) REFERENCES warehouses(id) ON DELETE SET NULL;
    END IF;
END $$;
