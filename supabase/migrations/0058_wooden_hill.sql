-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_tasks_production_order_id 
ON tasks(production_order_id);

CREATE INDEX IF NOT EXISTS idx_tasks_due_date 
ON tasks(due_date);