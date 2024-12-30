-- Add function to calculate order due date from tasks
CREATE OR REPLACE FUNCTION calculate_order_due_date()
RETURNS TRIGGER AS $$
BEGIN
  -- Update production order's due date if it's not set
  IF (
    SELECT due_date IS NULL 
    FROM production_orders 
    WHERE id = NEW.production_order_id
  ) THEN
    UPDATE production_orders
    SET due_date = (
      SELECT MAX(due_date)
      FROM tasks
      WHERE production_order_id = NEW.production_order_id
    )
    WHERE id = NEW.production_order_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update order due date when tasks change
DROP TRIGGER IF EXISTS update_order_due_date ON tasks;
CREATE TRIGGER update_order_due_date
  AFTER INSERT OR UPDATE OF due_date ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION calculate_order_due_date();