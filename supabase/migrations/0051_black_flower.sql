/*
  # Add Todo Attachments Support

  1. New Columns
    - Add `attachments` column to task_todos table
    - JSONB array to store attachment metadata

  2. Security
    - Update RLS policies to handle attachments
    - Create storage bucket policies
*/

-- Add attachments column to task_todos
ALTER TABLE task_todos
ADD COLUMN attachments jsonb DEFAULT '[]'::jsonb;

-- Create storage bucket for todo attachments
INSERT INTO storage.buckets (id, name, public)
VALUES ('todo-attachments', 'todo-attachments', true)
ON CONFLICT (id) DO NOTHING;

-- Set up storage policies
CREATE POLICY "Allow authenticated read todo attachments"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'todo-attachments');

CREATE POLICY "Allow staff upload todo attachments"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'todo-attachments' AND
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role IN ('admin', 'manager', 'staff')
  )
);

CREATE POLICY "Allow staff delete todo attachments"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'todo-attachments' AND
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role IN ('admin', 'manager', 'staff')
  )
);