-- Drop task history table and related objects
DROP TRIGGER IF EXISTS task_history_trigger ON tasks;
DROP FUNCTION IF EXISTS add_task_history();
DROP TABLE IF EXISTS task_history;