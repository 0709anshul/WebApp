-- Drop existing triggers first
DROP TRIGGER IF EXISTS validate_attachments_trigger ON production_orders;
DROP FUNCTION IF EXISTS validate_attachments_array CASCADE;
DROP FUNCTION IF EXISTS is_valid_attachment CASCADE;

-- Drop existing attachments column if it exists
ALTER TABLE production_orders 
DROP COLUMN IF EXISTS attachments CASCADE;

-- Add details and attachments columns with proper types
ALTER TABLE production_orders 
ADD COLUMN IF NOT EXISTS details text,
ADD COLUMN attachments jsonb DEFAULT '[]'::jsonb;

-- Create storage bucket for attachments
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