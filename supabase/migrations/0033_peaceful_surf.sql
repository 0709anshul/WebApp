/*
  # Update Task Status Enum

  1. Changes
    - Update task_status enum to include new status 'pending_from_client'
    - Migrate existing data safely
    - Add RLS policies for task status updates

  2. Security
    - Only admins and managers can update task status
*/

-- Temporarily disable the enum constraint
ALTER TABLE tasks ALTER COLUMN status DROP DEFAULT;
ALTER TABLE tasks ALTER COLUMN status TYPE text;

-- Drop the old enum type
DROP TYPE IF EXISTS task_status;

-- Create new enum type with additional status
CREATE TYPE task_status AS ENUM (
  'pending',
  'pending_from_client',
  'in_progress',
  'completed'
);

-- Convert column back to enum and set default
ALTER TABLE tasks 
  ALTER COLUMN status TYPE task_status USING status::task_status,
  ALTER COLUMN status SET DEFAULT 'pending';

-- Add policy for task status updates
DROP POLICY IF EXISTS "allow_admin_manager_update_task_status" ON tasks;

CREATE POLICY "allow_admin_manager_update_task_status"
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