-- Drop existing function first
DROP FUNCTION IF EXISTS apply_task_template(uuid, uuid, date, uuid);

-- Add owner_id column to task_template_items if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'task_template_items' AND column_name = 'owner_id'
  ) THEN
    ALTER TABLE task_template_items
    ADD COLUMN owner_id uuid REFERENCES auth.users(id);
  END IF;
END $$;

-- Recreate function with updated logic
CREATE OR REPLACE FUNCTION apply_task_template(
  template_id uuid,
  production_order_id uuid,
  start_date date DEFAULT CURRENT_DATE,
  default_owner_id uuid DEFAULT NULL
)
RETURNS SETOF tasks AS $$
BEGIN
  RETURN QUERY
  INSERT INTO tasks (
    production_order_id,
    start_date,
    duration_days,
    owner_id,
    details,
    status
  )
  SELECT
    production_order_id,
    start_date + SUM(duration_days) OVER (
      ORDER BY order_index
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ),
    duration_days,
    COALESCE(owner_id, default_owner_id),
    COALESCE(details_template, name),
    'pending'::task_status
  FROM task_template_items
  WHERE template_id = template_id
  ORDER BY order_index
  RETURNING *;
END;
$$ LANGUAGE plpgsql;