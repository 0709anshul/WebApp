-- Add is_private column to task_todos
ALTER TABLE task_todos
ADD COLUMN is_private boolean NOT NULL DEFAULT false;

-- Update policies to handle private todos
DROP POLICY IF EXISTS "allow_read_todos" ON task_todos;

CREATE POLICY "allow_read_todos"
  ON task_todos FOR SELECT
  TO authenticated
  USING (
    -- Allow Leumas staff to see all todos
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('admin', 'manager', 'staff')
    )
    OR
    -- Allow brand users to see only non-private todos
    (NOT is_private)
  );