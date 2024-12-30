-- Drop the trigger and function from the previous migration
DROP TRIGGER IF EXISTS update_order_due_date ON tasks;
DROP FUNCTION IF EXISTS calculate_order_due_date;