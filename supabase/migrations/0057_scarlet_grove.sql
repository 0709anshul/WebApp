-- Add due_date column to production_orders
ALTER TABLE production_orders
ADD COLUMN IF NOT EXISTS due_date date;