-- Update the apply_task_template function to handle owner_id
CREATE OR REPLACE FUNCTION apply_task_template(
  p_template_id uuid,
  p_production_order_id uuid,
  p_start_date date DEFAULT CURRENT_DATE,
  p_owner_id uuid DEFAULT NULL
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
    p_production_order_id,
    p_start_date + SUM(duration_days) OVER (
      ORDER BY order_index
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ),
    duration_days,
    p_owner_id,
    COALESCE(details_template, name),
    'pending'::task_status
  FROM task_template_items
  WHERE template_id = p_template_id
  ORDER BY order_index
  RETURNING *;
END;
$$ LANGUAGE plpgsql;