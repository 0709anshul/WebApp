-- Create function to calculate order due date
CREATE OR REPLACE FUNCTION calculate_order_due_date()
RETURNS TRIGGER AS $$
BEGIN
  -- Update production order's due date based on latest task due date
  UPDATE production_orders
  SET due_date = (
    SELECT MAX(due_date)
    FROM tasks
    WHERE production_order_id = NEW.production_order_id
  )
  WHERE id = NEW.production_order_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update order due date when tasks change
DROP TRIGGER IF EXISTS update_order_due_date ON tasks;
CREATE TRIGGER update_order_due_date
  AFTER INSERT OR UPDATE OF start_date, duration_days ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION calculate_order_due_date();

-- Create trigger to update order due date when tasks are deleted
CREATE TRIGGER update_order_due_date_on_delete
  AFTER DELETE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION calculate_order_due_date();