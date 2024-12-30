-- Add internal notes and proof of work columns to tasks
ALTER TABLE tasks
ADD COLUMN IF NOT EXISTS internal_notes text,
ADD COLUMN IF NOT EXISTS proof_of_work text,
ADD COLUMN IF NOT EXISTS attachments jsonb DEFAULT '[]'::jsonb;

-- Create storage bucket for task attachments if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('task-attachments', 'task-attachments', true)
ON CONFLICT (id) DO NOTHING;

-- Set up storage policies
DROP POLICY IF EXISTS "Allow authenticated users to read task attachments" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to upload task attachments" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to delete task attachments" ON storage.objects;

CREATE POLICY "Allow authenticated users to read task attachments"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'task-attachments');

CREATE POLICY "Allow authenticated users to upload task attachments"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'task-attachments');

CREATE POLICY "Allow authenticated users to delete task attachments"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'task-attachments');