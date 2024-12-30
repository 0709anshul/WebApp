/*
  # Create tasks table and related schemas

  1. New Tables
    - tasks
      - id (uuid, primary key)
      - production_order_id (uuid, foreign key)
      - start_date (date)
      - duration_days (integer)
      - due_date (date, computed)
      - owner_id (uuid, foreign key)
      - details (text)
      - proof_of_work (jsonb array for attachments)
      - status (enum)
      - created_at (timestamp)
      - updated_at (timestamp)
    
    - task_history
      - id (uuid, primary key)
      - task_id (uuid, foreign key)
      - user_id (uuid, foreign key)
      - action (text)
      - details (text)
      - created_at (timestamp)

  2. Security
    - Enable RLS on both tables
    - Add policies for organization and role-based access
*/

-- Create task status enum
CREATE TYPE task_status AS ENUM ('pending', 'in_progress', 'completed', 'blocked');

-- Create tasks table
CREATE TABLE IF NOT EXISTS tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  production_order_id uuid REFERENCES production_orders(id) NOT NULL,
  start_date date NOT NULL,
  duration_days integer NOT NULL CHECK (duration_days > 0),
  due_date date GENERATED ALWAYS AS (start_date + duration_days * INTERVAL '1 day') STORED,
  owner_id uuid REFERENCES users(id) NOT NULL,
  details text,
  proof_of_work jsonb[] DEFAULT ARRAY[]::jsonb[],
  status task_status NOT NULL DEFAULT 'pending',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create task history table
CREATE TABLE IF NOT EXISTS task_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id uuid REFERENCES tasks(id) NOT NULL,
  user_id uuid REFERENCES users(id) NOT NULL,
  action text NOT NULL,
  details text,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_history ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger for tasks
CREATE TRIGGER update_tasks_updated_at
  BEFORE UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create policies
DO $$ 
BEGIN
  -- Tasks policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'tasks' AND policyname = 'Users can view relevant tasks'
  ) THEN
    CREATE POLICY "Users can view relevant tasks"
      ON tasks FOR SELECT
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM users u
          JOIN production_orders po ON tasks.production_order_id = po.id
          WHERE u.id = auth.uid()
          AND (
            -- Users can see tasks from their organization's orders
            u.organization_id = po.organization_id
            OR
            -- Leumas staff can see all tasks
            u.organization_id = (SELECT id FROM organizations WHERE name = 'Leumas')
          )
        )
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'tasks' AND policyname = 'Leumas staff can manage tasks'
  ) THEN
    CREATE POLICY "Leumas staff can manage tasks"
      ON tasks FOR ALL
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM users u
          JOIN roles r ON u.role_id = r.id
          WHERE u.id = auth.uid()
          AND u.organization_id = (SELECT id FROM organizations WHERE name = 'Leumas')
          AND r.name IN ('admin', 'manager', 'staff')
        )
      );
  END IF;

  -- Task history policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'task_history' AND policyname = 'Users can view relevant task history'
  ) THEN
    CREATE POLICY "Users can view relevant task history"
      ON task_history FOR SELECT
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM users u
          JOIN tasks t ON task_history.task_id = t.id
          JOIN production_orders po ON t.production_order_id = po.id
          WHERE u.id = auth.uid()
          AND (
            u.organization_id = po.organization_id
            OR
            u.organization_id = (SELECT id FROM organizations WHERE name = 'Leumas')
          )
        )
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'task_history' AND policyname = 'Leumas staff can add task history'
  ) THEN
    CREATE POLICY "Leumas staff can add task history"
      ON task_history FOR INSERT
      TO authenticated
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM users u
          JOIN roles r ON u.role_id = r.id
          WHERE u.id = auth.uid()
          AND u.organization_id = (SELECT id FROM organizations WHERE name = 'Leumas')
          AND r.name IN ('admin', 'manager', 'staff')
        )
      );
  END IF;
END $$;

-- Insert sample tasks for each production order
WITH task_templates AS (
  SELECT unnest(ARRAY[
    '{"name": "Raw Material Inspection", "duration": 2}',
    '{"name": "Production Setup", "duration": 1}',
    '{"name": "Manufacturing", "duration": 3}',
    '{"name": "Quality Control", "duration": 2}',
    '{"name": "Packaging", "duration": 2}'
  ]::jsonb[]) as template
)
INSERT INTO tasks (
  production_order_id,
  start_date,
  duration_days,
  owner_id,
  details,
  status
)
SELECT 
  po.id,
  po.created_at::date + (row_number() OVER (PARTITION BY po.id ORDER BY t.template->>'name'))::integer * INTERVAL '1 day',
  (t.template->>'duration')::integer,
  get_random_leumas_staff_id(),
  'Task: ' || (t.template->>'name') || ' for ' || p.name,
  CASE 
    WHEN random() < 0.3 THEN 'pending'::task_status
    WHEN random() < 0.6 THEN 'in_progress'::task_status
    ELSE 'completed'::task_status
  END
FROM production_orders po
CROSS JOIN task_templates t
JOIN products p ON po.product_id = p.id;

-- Add sample proof of work for some completed tasks
UPDATE tasks
SET proof_of_work = ARRAY[
  jsonb_build_object(
    'filename', 'quality_report.pdf',
    'size', 1024567,
    'type', 'application/pdf',
    'url', 'https://example.com/files/quality_report.pdf'
  ),
  jsonb_build_object(
    'filename', 'process_photo.jpg',
    'size', 2048567,
    'type', 'image/jpeg',
    'url', 'https://example.com/files/process_photo.jpg'
  )
]
WHERE status = 'completed'
AND random() < 0.5;

-- Add sample task history
INSERT INTO task_history (task_id, user_id, action, details)
SELECT 
  t.id,
  t.owner_id,
  'status_update',
  'Task status updated to: ' || t.status
FROM tasks t;