-- Drop existing attachments validation
DROP TRIGGER IF EXISTS validate_attachments_trigger ON tasks;
DROP FUNCTION IF EXISTS validate_attachments_array();
DROP FUNCTION IF EXISTS validate_attachment_object();

-- Update tasks table
ALTER TABLE tasks
  ALTER COLUMN attachments SET DEFAULT '[]'::jsonb,
  ADD CONSTRAINT valid_attachments CHECK (
    attachments IS NULL 
    OR jsonb_typeof(attachments) = 'array'
  );

-- Create function to handle empty arrays
CREATE OR REPLACE FUNCTION handle_empty_attachments()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.attachments IS NULL OR jsonb_array_length(NEW.attachments) = 0 THEN
    NEW.attachments := '[]'::jsonb;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for empty array handling
CREATE TRIGGER handle_empty_attachments_trigger
  BEFORE INSERT OR UPDATE OF attachments ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION handle_empty_attachments();