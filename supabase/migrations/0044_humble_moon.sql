-- Drop existing triggers and functions
DROP TRIGGER IF EXISTS handle_empty_attachments_trigger ON tasks;
DROP FUNCTION IF EXISTS handle_empty_attachments();

-- Update tasks table
ALTER TABLE tasks
  ALTER COLUMN attachments SET DEFAULT '[]'::jsonb,
  DROP CONSTRAINT IF EXISTS valid_attachments,
  ADD CONSTRAINT valid_attachments CHECK (
    attachments IS NOT NULL AND
    jsonb_typeof(attachments) = 'array'
  );

-- Create function to ensure valid attachments
CREATE OR REPLACE FUNCTION ensure_valid_attachments()
RETURNS TRIGGER AS $$
BEGIN
  -- Always ensure attachments is a valid array
  IF NEW.attachments IS NULL THEN
    NEW.attachments := '[]'::jsonb;
  END IF;

  -- Ensure it's an array type
  IF jsonb_typeof(NEW.attachments) != 'array' THEN
    NEW.attachments := '[]'::jsonb;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER ensure_valid_attachments_trigger
  BEFORE INSERT OR UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION ensure_valid_attachments();