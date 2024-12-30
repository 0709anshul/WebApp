-- Create function to calculate order due date
CREATE OR REPLACE FUNCTION calculate_order_due_date()
RETURNS TRIGGER AS $$
DECLARE
  latest_due_date date;
BEGIN
  -- Get the latest due date from tasks
  SELECT MAX(due_date)
  INTO latest_due_date
  FROM tasks
  WHERE production_order_id = NEW.production_order_id;

  -- Update the production order's due date
  IF latest_due_date IS NOT NULL THEN
    UPDATE production_orders
    SET due_date = latest_due_date
    WHERE id = NEW.production_order_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;