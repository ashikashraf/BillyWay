-- Phase 8: Company Settings & Profile

-- 1. Create company_settings table
CREATE TABLE IF NOT EXISTS company_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_name VARCHAR(255) NOT NULL,
    gstin VARCHAR(15),
    state_code VARCHAR(2),
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Add Row Level Security (RLS)
ALTER TABLE company_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all authenticated users to read settings" ON company_settings FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow admin users to update settings" ON company_settings FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Allow admin users to insert settings" ON company_settings FOR INSERT TO authenticated WITH CHECK (true);

-- 3. Insert default settings if none exist
INSERT INTO company_settings (company_name, gstin, state_code, address, phone, email)
SELECT 'My Company', '32AAAAA0000A1Z5', '32', '123 Main St, Kerala', '+91 9999999999', 'admin@mycompany.com'
WHERE NOT EXISTS (SELECT 1 FROM company_settings);

-- 4. Trigger to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_settings_updated_at ON company_settings;
CREATE TRIGGER trg_update_settings_updated_at
BEFORE UPDATE ON company_settings
FOR EACH ROW EXECUTE FUNCTION update_settings_updated_at();
