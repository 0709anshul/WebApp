-- Drop existing triggers and functions
DROP TRIGGER IF EXISTS validate_task_attachments_trigger ON tasks;
DROP FUNCTION IF EXISTS validate_task_attachments();
DROP FUNCTION IF EXISTS validate_task_attachment();

-- Create function to validate attachment object structure
CREATE OR REPLACE FUNCTION validate_attachment_object(attachment jsonb)
RETURNS boolean AS $$
BEGIN
  RETURN (
    attachment ? 'path' AND 
    attachment ? 'name' AND 
    attachment ? 'type' AND 
    attachment ? 'size' AND
    jsonb_typeof(attachment->'path') = 'string' AND
    jsonb_typeof(attachment->'name') = 'string' AND
    jsonb_typeof(attachment->'type') = 'string' AND
    jsonb_typeof(attachment->'size') = 'number'
  );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create function to validate attachments array
CREATE OR REPLACE FUNCTION validate_attachments_array()
RETURNS trigger AS $$
BEGIN
  -- Allow NULL or empty array
  IF NEW.attachments IS NULL OR jsonb_array_length(NEW.attachments) = 0 THEN
    NEW.attachments := '[]'::jsonb;
    RETURN NEW;
  END IF;

  -- Validate each attachment
  IF NOT (
    SELECT bool_and(validate_attachment_object(attachment))
    FROM jsonb_array_elements(NEW.attachments) AS attachment
  ) THEN
    RAISE EXCEPTION 'Invalid attachment format';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update attachments column with proper default
ALTER TABLE tasks 
  ALTER COLUMN attachments SET DEFAULT '[]'::jsonb;

-- Create trigger for attachments validation
CREATE TRIGGER validate_attachments_trigger
  BEFORE INSERT OR UPDATE OF attachments ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION validate_attachments_array();