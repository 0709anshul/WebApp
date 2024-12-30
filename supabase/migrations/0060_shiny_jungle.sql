-- Create triggers for due date calculation
DROP TRIGGER IF EXISTS update_order_due_date ON tasks;
CREATE TRIGGER update_order_due_date
  AFTER INSERT OR UPDATE OF due_date ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION calculate_order_due_date();

DROP TRIGGER IF EXISTS update_order_due_date_on_delete ON tasks;
CREATE TRIGGER update_order_due_date_on_delete
  AFTER DELETE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION calculate_order_due_date();