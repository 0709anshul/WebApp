-- Drop existing triggers and functions
DROP TRIGGER IF EXISTS ensure_valid_attachments_trigger ON tasks;
DROP FUNCTION IF EXISTS ensure_valid_attachments();

-- Update tasks table
ALTER TABLE tasks
  ALTER COLUMN attachments SET DEFAULT '[]'::jsonb,
  DROP CONSTRAINT IF EXISTS valid_attachments;

-- Add basic type check constraint
ALTER TABLE tasks ADD CONSTRAINT valid_attachments_type 
  CHECK (jsonb_typeof(attachments) = 'array');

-- Create function to validate attachments on insert/update
CREATE OR REPLACE FUNCTION ensure_valid_attachments()
RETURNS TRIGGER AS $$
BEGIN
  -- Set default empty array if null
  IF NEW.attachments IS NULL THEN
    NEW.attachments := '[]'::jsonb;
  END IF;

  -- Validate each attachment in the array
  FOR i IN 0..jsonb_array_length(NEW.attachments) - 1 LOOP
    IF NOT (
      (NEW.attachments->i) ? 'path' AND
      (NEW.attachments->i) ? 'name' AND
      (NEW.attachments->i) ? 'type' AND
      (NEW.attachments->i) ? 'size' AND
      jsonb_typeof(NEW.attachments->i->'path') = 'string' AND
      jsonb_typeof(NEW.attachments->i->'name') = 'string' AND
      jsonb_typeof(NEW.attachments->i->'type') = 'string' AND
      jsonb_typeof(NEW.attachments->i->'size') = 'string'
    ) THEN
      RAISE EXCEPTION 'Invalid attachment format at index %', i;
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for validation
CREATE TRIGGER ensure_valid_attachments_trigger
  BEFORE INSERT OR UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION ensure_valid_attachments();