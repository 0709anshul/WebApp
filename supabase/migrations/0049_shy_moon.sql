-- Create policy for owner assignment
CREATE POLICY "allow_admin_manager_assign_owner"
  ON tasks
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('admin', 'manager')
    )
  )
  WITH CHECK (
    -- Only allow updating owner_id if user is admin/manager
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('admin', 'manager')
    )
  );

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS task_history_trigger ON tasks;
DROP FUNCTION IF EXISTS add_task_history();

-- Recreate function to track task history including owner changes
CREATE OR REPLACE FUNCTION add_task_history()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'UPDATE') THEN
    -- Owner change
    IF OLD.owner_id IS DISTINCT FROM NEW.owner_id THEN
      INSERT INTO task_history (task_id, user_id, action, details)
      VALUES (
        NEW.id,
        auth.uid(),
        'owner_change',
        CASE 
          WHEN NEW.owner_id IS NULL THEN 'Owner removed'
          ELSE format('Owner changed to %s', (
            SELECT full_name FROM users WHERE id = NEW.owner_id
          ))
        END
      );
    END IF;

    -- Status change
    IF OLD.status IS DISTINCT FROM NEW.status THEN
      INSERT INTO task_history (task_id, user_id, action, details)
      VALUES (
        NEW.id,
        auth.uid(),
        'status_change',
        format('Status changed from %s to %s', OLD.status, NEW.status)
      );
    END IF;

    -- Duration change
    IF OLD.duration_days IS DISTINCT FROM NEW.duration_days THEN
      INSERT INTO task_history (task_id, user_id, action, details)
      VALUES (
        NEW.id,
        auth.uid(),
        'duration_change',
        format('Duration changed from %s to %s days', OLD.duration_days, NEW.duration_days)
      );
    END IF;

    -- Internal notes change
    IF OLD.internal_notes IS DISTINCT FROM NEW.internal_notes THEN
      INSERT INTO task_history (task_id, user_id, action, details)
      VALUES (
        NEW.id,
        auth.uid(),
        'notes_update',
        'Internal notes updated'
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
CREATE TRIGGER task_history_trigger
  AFTER UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION add_task_history();