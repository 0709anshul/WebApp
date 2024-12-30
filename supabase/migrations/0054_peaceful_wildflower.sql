-- Add missing columns to production_orders
ALTER TABLE production_orders
ADD COLUMN IF NOT EXISTS owner_id uuid REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS details text,
ADD COLUMN IF NOT EXISTS attachments jsonb DEFAULT '[]'::jsonb;

-- Create storage bucket for order attachments if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('order-attachments', 'order-attachments', true)
ON CONFLICT (id) DO NOTHING;

-- Set up storage policies
CREATE POLICY "Allow authenticated read order attachments"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'order-attachments');

CREATE POLICY "Allow staff upload order attachments"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'order-attachments' AND
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role IN ('admin', 'manager', 'staff')
  )
);

CREATE POLICY "Allow staff delete order attachments"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'order-attachments' AND
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role IN ('admin', 'manager', 'staff')
  )
);