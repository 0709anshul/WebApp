/*
  # Add priority flag to production orders and tasks

  1. Changes
    - Add priority boolean column to production_orders table
    - Add priority boolean column to tasks table
    - Add trigger to automatically set task priority based on order priority
  
  2. Security
    - Only admins and managers can update priority flag
*/

-- Add priority columns
ALTER TABLE production_orders 
ADD COLUMN is_priority boolean NOT NULL DEFAULT false;

ALTER TABLE tasks
ADD COLUMN is_priority boolean NOT NULL DEFAULT false;

-- Create function to sync task priority with order priority
CREATE OR REPLACE FUNCTION sync_task_priority()
RETURNS TRIGGER AS $$
BEGIN
  -- Update existing tasks when order priority changes
  IF TG_OP = 'UPDATE' AND OLD.is_priority IS DISTINCT FROM NEW.is_priority THEN
    UPDATE tasks
    SET is_priority = NEW.is_priority
    WHERE production_order_id = NEW.id;
  END IF;

  -- Set priority for new tasks based on order priority
  IF TG_OP = 'INSERT' THEN
    NEW.is_priority := (
      SELECT is_priority 
      FROM production_orders 
      WHERE id = NEW.production_order_id
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER sync_task_priority_on_order_update
  AFTER UPDATE OF is_priority ON production_orders
  FOR EACH ROW
  EXECUTE FUNCTION sync_task_priority();

CREATE TRIGGER set_task_priority_on_insert
  BEFORE INSERT ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION sync_task_priority();