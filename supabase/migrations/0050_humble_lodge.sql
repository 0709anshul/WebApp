/*
  # Add Task Todos Feature

  1. New Tables
    - `task_todos`
      - `id` (uuid, primary key)
      - `task_id` (uuid, references tasks)
      - `description` (text)
      - `completed` (boolean)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on `task_todos` table
    - Add policies for authenticated users to:
      - Read todos
      - Create/update/delete todos (admin/manager/staff only)
*/

-- Create task_todos table
CREATE TABLE task_todos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id uuid REFERENCES tasks(id) ON DELETE CASCADE NOT NULL,
  description text NOT NULL,
  completed boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- Enable RLS
ALTER TABLE task_todos ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger
CREATE TRIGGER update_task_todos_updated_at
  BEFORE UPDATE ON task_todos
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create policies
CREATE POLICY "allow_read_todos"
  ON task_todos FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "allow_staff_manage_todos"
  ON task_todos FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('admin', 'manager', 'staff')
    )
  );

-- Add task history entries for todo changes
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
  ELSIF (TG_OP = 'UPDATE' AND OLD.completed IS DISTINCT FROM NEW.completed) THEN
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

-- Create triggers for todo history
CREATE TRIGGER todo_history_insert_trigger
  AFTER INSERT ON task_todos
  FOR EACH ROW
  EXECUTE FUNCTION add_todo_history();

CREATE TRIGGER todo_history_update_trigger
  AFTER UPDATE ON task_todos
  FOR EACH ROW
  EXECUTE FUNCTION add_todo_history();

CREATE TRIGGER todo_history_delete_trigger
  AFTER DELETE ON task_todos
  FOR EACH ROW
  EXECUTE FUNCTION add_todo_history();