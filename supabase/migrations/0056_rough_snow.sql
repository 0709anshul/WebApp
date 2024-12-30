-- Update task history policies
DROP POLICY IF EXISTS "allow_read_task_history" ON task_history;

CREATE POLICY "allow_admin_manager_read_history"
  ON task_history FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('admin', 'manager')
    )
  );