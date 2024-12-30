/*
  # Fix Task Status Updates

  1. Changes
    - Ensure task_status enum exists with correct values
    - Update RLS policies for task status updates
    - Add proper constraints and defaults

  2. Security
    - Only admins and managers can update task status
    - All authenticated users can view tasks
*/

-- Drop existing policies
DROP POLICY IF EXISTS "allow_admin_manager_update_task_status" ON tasks;
DROP POLICY IF EXISTS "allow_read_tasks" ON tasks;

-- Re-enable RLS
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Create read policy
CREATE POLICY "allow_read_tasks"
  ON tasks FOR SELECT
  TO authenticated
  USING (true);

-- Create update policy for admins and managers
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

-- Ensure task_status enum exists with correct values
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

-- Update tasks table to use enum
ALTER TABLE tasks 
  ALTER COLUMN status SET DATA TYPE task_status 
  USING status::task_status,
  ALTER COLUMN status SET DEFAULT 'pending'::task_status;