/*
  # Update Task Status Schema

  1. Changes
    - Create new task_status enum type
    - Update tasks table to use new enum
    - Add RLS policies for task management

  2. Security
    - Enable RLS on tasks table
    - Add policies for reading and updating tasks
*/

-- First create the new enum type if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_status') THEN
    CREATE TYPE task_status AS ENUM (
      'pending',
      'pending_from_client',
      'in_progress',
      'completed'
    );
  END IF;
END $$;

-- Add temporary column with new enum type
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS new_status task_status DEFAULT 'pending';

-- Update the new column based on existing status values
UPDATE tasks 
SET new_status = CASE 
  WHEN status::text = 'pending' THEN 'pending'::task_status
  WHEN status::text = 'pending_from_client' THEN 'pending_from_client'::task_status
  WHEN status::text = 'in_progress' THEN 'in_progress'::task_status
  WHEN status::text = 'completed' THEN 'completed'::task_status
  ELSE 'pending'::task_status
END;

-- Drop old status column and rename new one
ALTER TABLE tasks DROP COLUMN IF EXISTS status;
ALTER TABLE tasks RENAME COLUMN new_status TO status;

-- Add not null constraint
ALTER TABLE tasks ALTER COLUMN status SET NOT NULL;

-- Ensure RLS is enabled
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Create policies
DROP POLICY IF EXISTS "allow_read_tasks" ON tasks;
DROP POLICY IF EXISTS "allow_admin_manager_update_tasks" ON tasks;

CREATE POLICY "allow_read_tasks"
  ON tasks FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "allow_admin_manager_update_tasks"
  ON tasks
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('admin', 'manager')
    )
  );