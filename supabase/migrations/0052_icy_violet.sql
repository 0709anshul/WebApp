-- Add notes column to task_todos
ALTER TABLE task_todos
ADD COLUMN notes text;

-- Update task history function to track notes changes
CREATE OR REPLACE FUNCTION add_todo_history()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    INSERT INTO task_history (task_id, user_id, action, details)
    VALUES (
      NEW.task_id,
      auth.uid(),
      'todo_added',
      format('Added todo: %s', NEW.description)
    );
  ELSIF (TG_OP = 'UPDATE') THEN
    -- Track completion status change
    IF OLD.completed IS DISTINCT FROM NEW.completed THEN
      INSERT INTO task_history (task_id, user_id, action, details)
      VALUES (
        NEW.task_id,
        auth.uid(),
        'todo_status_change',
        format('Todo "%s" marked as %s', 
          NEW.description, 
          CASE WHEN NEW.completed THEN 'completed' ELSE 'pending' END
        )
      );
    END IF;
    
    -- Track notes changes
    IF OLD.notes IS DISTINCT FROM NEW.notes THEN
      INSERT INTO task_history (task_id, user_id, action, details)
      VALUES (
        NEW.task_id,
        auth.uid(),
        'todo_notes_update',
        format('Updated notes for todo: %s', NEW.description)
      );
    END IF;
  ELSIF (TG_OP = 'DELETE') THEN
    INSERT INTO task_history (task_id, user_id, action, details)
    VALUES (
      OLD.task_id,
      auth.uid(),
      'todo_removed',
      format('Removed todo: %s', OLD.description)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;