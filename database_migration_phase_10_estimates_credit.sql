-- Phase 10: Estimates Credit Flow

ALTER TABLE estimates 
ADD COLUMN payment_mode TEXT DEFAULT 'cash',
ADD COLUMN credit_days INT DEFAULT 0,
ADD COLUMN status TEXT DEFAULT 'cleared';

-- Ensure existing records have default values
UPDATE estimates 
SET payment_mode = 'cash', credit_days = 0, status = 'cleared'
WHERE payment_mode IS NULL;
