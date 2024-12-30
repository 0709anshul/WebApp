/*
  # Task Templates Schema

  1. New Tables
    - task_templates
      - id (uuid, primary key)
      - name (text)
      - description (text)
      - is_active (boolean)
      - created_at (timestamp)
      - updated_at (timestamp)
    
    - task_template_items
      - id (uuid, primary key)
      - template_id (uuid, foreign key)
      - name (text)
      - duration_days (integer)
      - order_index (integer)
      - details_template (text)
      - created_at (timestamp)

  2. Security
    - Enable RLS on both tables
    - Only Leumas staff can manage templates
    - All authenticated users can view templates
*/

-- Create tables
CREATE TABLE IF NOT EXISTS task_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS task_template_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id uuid REFERENCES task_templates(id) ON DELETE CASCADE,
  name text NOT NULL,
  duration_days integer NOT NULL CHECK (duration_days > 0),
  order_index integer NOT NULL,
  details_template text,
  created_at timestamptz DEFAULT now(),
  UNIQUE (template_id, order_index)
);

-- Enable RLS
ALTER TABLE task_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_template_items ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger
CREATE TRIGGER update_task_templates_updated_at
  BEFORE UPDATE ON task_templates
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create policies
DO $$ 
BEGIN
  -- Task templates policies
  CREATE POLICY "Anyone can view active templates"
    ON task_templates FOR SELECT
    TO authenticated
    USING (is_active = true);

  CREATE POLICY "Leumas staff can manage templates"
    ON task_templates FOR ALL
    TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM users u
        JOIN roles r ON u.role_id = r.id
        WHERE u.id = auth.uid()
        AND u.organization_id = (SELECT id FROM organizations WHERE name = 'Leumas')
        AND r.name IN ('admin', 'manager')
      )
    );

  -- Task template items policies
  CREATE POLICY "Anyone can view template items"
    ON task_template_items FOR SELECT
    TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM task_templates
        WHERE task_templates.id = template_id
        AND task_templates.is_active = true
      )
    );

  CREATE POLICY "Leumas staff can manage template items"
    ON task_template_items FOR ALL
    TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM users u
        JOIN roles r ON u.role_id = r.id
        WHERE u.id = auth.uid()
        AND u.organization_id = (SELECT id FROM organizations WHERE name = 'Leumas')
        AND r.name IN ('admin', 'manager')
      )
    );
END $$;

-- Helper function to apply template to a production order
CREATE OR REPLACE FUNCTION apply_task_template(
  p_template_id uuid,
  p_production_order_id uuid,
  p_start_date date DEFAULT CURRENT_DATE
)
RETURNS SETOF tasks AS $$
DECLARE
  v_current_date date := p_start_date;
  v_task_id uuid;
BEGIN
  FOR v_task_id IN
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
      v_current_date + SUM(duration_days) OVER (
        ORDER BY order_index
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
      ),
      duration_days,
      get_random_leumas_staff_id(),
      details_template,
      'pending'::task_status
    FROM task_template_items
    WHERE template_id = p_template_id
    ORDER BY order_index
    RETURNING id
  LOOP
    RETURN QUERY SELECT * FROM tasks WHERE id = v_task_id;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Insert sample templates
INSERT INTO task_templates (name, description) VALUES
  ('Standard Production', 'Standard production process for most products'),
  ('Complex Production', 'Extended process for complex products'),
  ('Quick Production', 'Simplified process for simple products');

-- Insert template items for Standard Production
WITH standard_template AS (
  SELECT id FROM task_templates WHERE name = 'Standard Production' LIMIT 1
)
INSERT INTO task_template_items (template_id, name, duration_days, order_index, details_template)
VALUES
  ((SELECT id FROM standard_template), 'Raw Material Inspection', 2, 1, 'Inspect all raw materials according to SOP-001'),
  ((SELECT id FROM standard_template), 'Production Setup', 1, 2, 'Setup production line according to product specifications'),
  ((SELECT id FROM standard_template), 'Manufacturing', 3, 3, 'Execute manufacturing process following SOP'),
  ((SELECT id FROM standard_template), 'Quality Control', 2, 4, 'Perform quality checks as per QC checklist'),
  ((SELECT id FROM standard_template), 'Packaging', 2, 5, 'Package product according to packaging specifications');

-- Insert template items for Complex Production
WITH complex_template AS (
  SELECT id FROM task_templates WHERE name = 'Complex Production' LIMIT 1
)
INSERT INTO task_template_items (template_id, name, duration_days, order_index, details_template)
VALUES
  ((SELECT id FROM complex_template), 'Raw Material Inspection', 3, 1, 'Detailed inspection of all raw materials'),
  ((SELECT id FROM complex_template), 'Lab Testing', 2, 2, 'Perform preliminary lab tests'),
  ((SELECT id FROM complex_template), 'Production Setup', 2, 3, 'Complex production line setup'),
  ((SELECT id FROM complex_template), 'Initial Production Run', 1, 4, 'Initial test batch production'),
  ((SELECT id FROM complex_template), 'Quality Check - Initial', 1, 5, 'Quality verification of test batch'),
  ((SELECT id FROM complex_template), 'Full Production', 4, 6, 'Main production run'),
  ((SELECT id FROM complex_template), 'Quality Control', 3, 7, 'Comprehensive quality testing'),
  ((SELECT id FROM complex_template), 'Packaging', 2, 8, 'Packaging with additional quality checks');

-- Insert template items for Quick Production
WITH quick_template AS (
  SELECT id FROM task_templates WHERE name = 'Quick Production' LIMIT 1
)
INSERT INTO task_template_items (template_id, name, duration_days, order_index, details_template)
VALUES
  ((SELECT id FROM quick_template), 'Quick Material Check', 1, 1, 'Basic material verification'),
  ((SELECT id FROM quick_template), 'Production', 2, 2, 'Streamlined production process'),
  ((SELECT id FROM quick_template), 'Quality Check', 1, 3, 'Essential quality verification'),
  ((SELECT id FROM quick_template), 'Packaging', 1, 4, 'Basic packaging process');