-- Create task history table with proper relationships
CREATE TABLE IF NOT EXISTS task_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id uuid REFERENCES tasks(id) ON DELETE CASCADE NOT NULL,
  user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  action text NOT NULL,
  details text,
  created_at timestamptz DEFAULT now() NOT NULL
);

-- Enable RLS
ALTER TABLE task_history ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "allow_read_task_history"
  ON task_history FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "allow_insert_task_history"
  ON task_history FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Create function to automatically add history entries
CREATE OR REPLACE FUNCTION add_task_history()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'UPDATE') THEN
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

    -- Proof of work change
    IF OLD.proof_of_work IS DISTINCT FROM NEW.proof_of_work 
    OR OLD.attachments IS DISTINCT FROM NEW.attachments THEN
      INSERT INTO task_history (task_id, user_id, action, details)
      VALUES (
        NEW.id,
        auth.uid(),
        'proof_update',
        'Proof of work updated'
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for task history
DROP TRIGGER IF EXISTS task_history_trigger ON tasks;
CREATE TRIGGER task_history_trigger
  AFTER UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION add_task_history();