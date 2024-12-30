/*
  # Add attachments support for production orders
  
  1. Changes
    - Add attachments column to store file metadata
    - Add validation function for attachment objects
    - Add trigger to validate attachments on insert/update
  
  2. Notes
    - Attachments are stored as JSONB array
    - Each attachment must have required fields: path, name, type, size
    - Only specific file types are allowed
*/

-- Create function to validate attachment object structure
CREATE OR REPLACE FUNCTION is_valid_attachment(attachment jsonb)
RETURNS boolean AS $$
BEGIN
  -- Check required fields exist and are of correct type
  RETURN (
    attachment ? 'path' AND 
    attachment ? 'name' AND 
    attachment ? 'type' AND 
    attachment ? 'size' AND
    jsonb_typeof(attachment->'path') = 'string' AND
    jsonb_typeof(attachment->'name') = 'string' AND
    jsonb_typeof(attachment->'type') = 'string' AND
    jsonb_typeof(attachment->'size') = 'number' AND
    (attachment->>'type' IN (
      'image/jpeg',
      'image/png',
      'image/gif',
      'application/pdf',
      'video/mp4',
      'video/quicktime'
    ))
  );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create function to validate attachments array
CREATE OR REPLACE FUNCTION validate_attachments_array()
RETURNS trigger AS $$
BEGIN
  -- Allow NULL or empty array
  IF NEW.attachments IS NULL OR jsonb_array_length(NEW.attachments) = 0 THEN
    RETURN NEW;
  END IF;

  -- Validate each attachment in the array
  IF NOT (
    SELECT bool_and(is_valid_attachment(attachment))
    FROM jsonb_array_elements(NEW.attachments) AS attachment
  ) THEN
    RAISE EXCEPTION 'Invalid attachment format';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add attachments column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'production_orders' AND column_name = 'attachments'
  ) THEN
    ALTER TABLE production_orders
    ADD COLUMN attachments jsonb[] DEFAULT ARRAY[]::jsonb[];
  END IF;
END $$;

-- Create trigger for validating attachments
DROP TRIGGER IF EXISTS validate_attachments_trigger ON production_orders;
CREATE TRIGGER validate_attachments_trigger
  BEFORE INSERT OR UPDATE OF attachments ON production_orders
  FOR EACH ROW
  EXECUTE FUNCTION validate_attachments_array();

-- Create storage bucket for attachments if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('order-attachments', 'order-attachments', true)
ON CONFLICT (id) DO NOTHING;

-- Set up storage policies
DROP POLICY IF EXISTS "Allow authenticated users to read attachments" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to upload attachments" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to delete their attachments" ON storage.objects;

CREATE POLICY "Allow authenticated users to read attachments"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'order-attachments');

CREATE POLICY "Allow authenticated users to upload attachments"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'order-attachments');

CREATE POLICY "Allow authenticated users to delete their attachments"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'order-attachments');