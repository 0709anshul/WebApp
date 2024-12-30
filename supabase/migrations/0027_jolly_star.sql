-- Add priority columns if they don't exist
DO $$ 
BEGIN
  -- Add columns if they don't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'production_orders' AND column_name = 'is_priority'
  ) THEN
    ALTER TABLE production_orders 
    ADD COLUMN is_priority boolean NOT NULL DEFAULT false;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'tasks' AND column_name = 'is_priority'
  ) THEN
    ALTER TABLE tasks
    ADD COLUMN is_priority boolean NOT NULL DEFAULT false;
  END IF;
END $$;

-- Drop existing triggers and function if they exist
DROP TRIGGER IF EXISTS sync_task_priority_on_order_update ON production_orders;
DROP TRIGGER IF EXISTS set_task_priority_on_insert ON tasks;
DROP FUNCTION IF EXISTS sync_task_priority();

-- Recreate function with updated logic
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