-- Create task templates table
CREATE TABLE IF NOT EXISTS task_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- Create task template items table
CREATE TABLE IF NOT EXISTS task_template_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id uuid REFERENCES task_templates(id) ON DELETE CASCADE NOT NULL,
  name text NOT NULL,
  duration_days integer NOT NULL CHECK (duration_days > 0),
  order_index integer NOT NULL,
  details_template text,
  created_at timestamptz DEFAULT now() NOT NULL,
  UNIQUE (template_id, order_index)
);

-- Enable RLS
ALTER TABLE task_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_template_items ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "allow_read_templates"
  ON task_templates FOR SELECT
  TO authenticated
  USING (is_active = true);

CREATE POLICY "allow_staff_manage_templates"
  ON task_templates FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('admin', 'manager', 'staff')
    )
  );

CREATE POLICY "allow_read_template_items"
  ON task_template_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM task_templates
      WHERE task_templates.id = template_id
      AND task_templates.is_active = true
    )
  );

CREATE POLICY "allow_staff_manage_template_items"
  ON task_template_items FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('admin', 'manager', 'staff')
    )
  );

-- Function to apply template to order
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

-- Insert sample templates
INSERT INTO task_templates (name, description) VALUES
  ('Standard Production', 'Standard production process for most products'),
  ('Complex Production', 'Extended process for complex products'),
  ('Quick Production', 'Simplified process for simple products')
ON CONFLICT DO NOTHING;

-- Insert template items
WITH templates AS (
  SELECT id, name FROM task_templates
)
INSERT INTO task_template_items (template_id, name, duration_days, order_index)
SELECT
  t.id,
  item.name,
  item.duration,
  item.idx
FROM templates t
CROSS JOIN LATERAL (
  VALUES
    -- Standard Production
    ('Raw Material Inspection', 2, 1),
    ('Production Setup', 1, 2),
    ('Manufacturing', 3, 3),
    ('Quality Control', 2, 4),
    ('Packaging', 2, 5)
) AS item(name, duration, idx)
WHERE t.name = 'Standard Production'
UNION ALL
SELECT
  t.id,
  item.name,
  item.duration,
  item.idx
FROM templates t
CROSS JOIN LATERAL (
  VALUES
    -- Complex Production
    ('Raw Material Inspection', 3, 1),
    ('Lab Testing', 2, 2),
    ('Production Setup', 2, 3),
    ('Initial Production Run', 1, 4),
    ('Quality Check - Initial', 1, 5),
    ('Full Production', 4, 6),
    ('Quality Control', 3, 7),
    ('Packaging', 2, 8)
) AS item(name, duration, idx)
WHERE t.name = 'Complex Production'
UNION ALL
SELECT
  t.id,
  item.name,
  item.duration,
  item.idx
FROM templates t
CROSS JOIN LATERAL (
  VALUES
    -- Quick Production
    ('Quick Material Check', 1, 1),
    ('Production', 2, 2),
    ('Quality Check', 1, 3),
    ('Packaging', 1, 4)
) AS item(name, duration, idx)
WHERE t.name = 'Quick Production'
ON CONFLICT DO NOTHING;