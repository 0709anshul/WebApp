-- Add details column to production_orders if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'production_orders' AND column_name = 'details'
  ) THEN
    ALTER TABLE production_orders
    ADD COLUMN details text;
  END IF;
END $$;

-- Add attachments column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'production_orders' AND column_name = 'attachments'
  ) THEN
    ALTER TABLE production_orders
    ADD COLUMN attachments jsonb DEFAULT '[]'::jsonb;
  END IF;
END $$;

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