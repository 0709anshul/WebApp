-- Update existing order due dates
UPDATE production_orders po
SET due_date = (
  SELECT MAX(due_date)
  FROM tasks t
  WHERE t.production_order_id = po.id
);