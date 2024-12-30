-- Add due_date column to production_orders if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'production_orders' AND column_name = 'due_date'
  ) THEN
    ALTER TABLE production_orders ADD COLUMN due_date date;
  END IF;
END $$;

-- Create indexes if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE tablename = 'tasks' AND indexname = 'idx_tasks_production_order_id'
  ) THEN
    CREATE INDEX idx_tasks_production_order_id ON tasks(production_order_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE tablename = 'tasks' AND indexname = 'idx_tasks_due_date'
  ) THEN
    CREATE INDEX idx_tasks_due_date ON tasks(due_date);
  END IF;
END $$;

-- Update existing order due dates in batches
DO $$ 
DECLARE
  batch_size INTEGER := 100;
  total_orders INTEGER;
  processed_orders INTEGER := 0;
BEGIN
  SELECT COUNT(*) INTO total_orders FROM production_orders;
  
  WHILE processed_orders < total_orders LOOP
    WITH latest_task_dates AS (
      SELECT 
        production_order_id,
        MAX(due_date) as latest_due_date
      FROM tasks
      GROUP BY production_order_id
      LIMIT batch_size
      OFFSET processed_orders
    )
    UPDATE production_orders po
    SET due_date = ltd.latest_due_date
    FROM latest_task_dates ltd
    WHERE po.id = ltd.production_order_id;
    
    processed_orders := processed_orders + batch_size;
  END LOOP;
END $$;