/*
  # Create production orders table

  1. New Tables
    - production_orders
      - id (uuid, primary key)
      - po_number (text, unique)
      - organization_id (uuid, foreign key)
      - owner_id (uuid, foreign key)
      - product_id (uuid, foreign key)
      - quantity (integer)
      - details (text)
      - attachments (jsonb array for file metadata)
      - status (enum)
      - created_at (timestamp)
      - updated_at (timestamp)

  2. Security
    - Enable RLS
    - Add policies for organization and role-based access
*/

-- Create order status enum
CREATE TYPE order_status AS ENUM ('pending', 'in_progress', 'completed', 'cancelled');

-- Create production orders table
CREATE TABLE IF NOT EXISTS production_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  po_number text UNIQUE NOT NULL,
  organization_id uuid REFERENCES organizations(id) NOT NULL,
  owner_id uuid REFERENCES users(id) NOT NULL,
  product_id uuid REFERENCES products(id) NOT NULL,
  quantity integer NOT NULL CHECK (quantity > 0),
  details text,
  attachments jsonb[] DEFAULT ARRAY[]::jsonb[],
  status order_status NOT NULL DEFAULT 'pending',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE production_orders ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger
CREATE TRIGGER update_production_orders_updated_at
  BEFORE UPDATE ON production_orders
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create policies
DO $$ 
BEGIN
  -- Read policy
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'production_orders' AND policyname = 'Users can view relevant production orders'
  ) THEN
    CREATE POLICY "Users can view relevant production orders"
      ON production_orders FOR SELECT
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM users
          WHERE users.id = auth.uid()
          AND (
            -- Users can see orders from their organization
            users.organization_id = production_orders.organization_id
            OR
            -- Leumas staff can see all orders
            users.organization_id = (SELECT id FROM organizations WHERE name = 'Leumas')
          )
        )
      );
  END IF;

  -- Write policy
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'production_orders' AND policyname = 'Leumas staff can manage production orders'
  ) THEN
    CREATE POLICY "Leumas staff can manage production orders"
      ON production_orders FOR ALL
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM users u
          JOIN roles r ON u.role_id = r.id
          WHERE u.id = auth.uid()
          AND u.organization_id = (SELECT id FROM organizations WHERE name = 'Leumas')
          AND r.name IN ('admin', 'manager', 'staff')
        )
      );
  END IF;
END $$;

-- Helper function to get a random Leumas staff member ID
CREATE OR REPLACE FUNCTION get_random_leumas_staff_id()
RETURNS uuid AS $$
  SELECT u.id 
  FROM users u
  JOIN roles r ON u.role_id = r.id
  WHERE u.organization_id = (SELECT id FROM organizations WHERE name = 'Leumas')
  AND r.name IN ('manager', 'staff')
  ORDER BY random()
  LIMIT 1;
$$ LANGUAGE SQL;

-- Insert sample production orders
WITH numbered_products AS (
  SELECT 
    p.*,
    ROW_NUMBER() OVER () as rn
  FROM products p
)
INSERT INTO production_orders (
  po_number,
  organization_id,
  owner_id,
  product_id,
  quantity,
  details,
  status
)
SELECT
  'PO-' || TO_CHAR(NOW(), 'YYYY') || '-' || 
  CASE 
    WHEN rn < 10 THEN '00' || rn::text
    WHEN rn < 100 THEN '0' || rn::text
    ELSE rn::text
  END,
  organization_id,
  get_random_leumas_staff_id(),
  id,
  CASE 
    WHEN batch_size <= 500 THEN batch_size
    ELSE batch_size / 2
  END,
  'Sample production order for ' || name || '. Standard quality requirements apply.',
  (ARRAY['pending', 'in_progress', 'completed'])[floor(random() * 3 + 1)]::order_status
FROM numbered_products;

-- Add some orders with attachments for demonstration
UPDATE production_orders
SET attachments = ARRAY[
  '{"filename": "quality_specs.pdf", "size": 1024567, "type": "application/pdf", "url": "https://example.com/files/quality_specs.pdf"}'::jsonb,
  '{"filename": "packaging_requirements.jpg", "size": 2048567, "type": "image/jpeg", "url": "https://example.com/files/packaging_requirements.jpg"}'::jsonb
]
WHERE po_number LIKE '%001';