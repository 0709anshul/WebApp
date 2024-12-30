-- Drop existing attachments column
ALTER TABLE tasks DROP COLUMN IF EXISTS attachments;

-- Add attachments column with proper validation
ALTER TABLE tasks ADD COLUMN attachments jsonb DEFAULT '[]'::jsonb;

-- Create validation function
CREATE OR REPLACE FUNCTION validate_task_attachment(attachment jsonb)
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

-- Create trigger function for attachments validation
CREATE OR REPLACE FUNCTION validate_task_attachments()
RETURNS trigger AS $$
BEGIN
  -- Allow NULL or empty array
  IF NEW.attachments IS NULL OR jsonb_array_length(NEW.attachments) = 0 THEN
    NEW.attachments := '[]'::jsonb;
    RETURN NEW;
  END IF;

  -- Validate each attachment
  IF NOT (
    SELECT bool_and(validate_task_attachment(attachment))
    FROM jsonb_array_elements(NEW.attachments) AS attachment
  ) THEN
    RAISE EXCEPTION 'Invalid attachment format';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS validate_task_attachments_trigger ON tasks;
CREATE TRIGGER validate_task_attachments_trigger
  BEFORE INSERT OR UPDATE OF attachments ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION validate_task_attachments();