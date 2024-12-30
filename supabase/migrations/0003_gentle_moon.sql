/*
  # Create products table and add initial data

  1. New Tables
    - products
      - id (uuid, primary key)
      - name (text)
      - organization_id (uuid, foreign key)
      - batch_size (integer)
      - price_inr (decimal)
      - created_at (timestamp)
      - updated_at (timestamp)

  2. Security
    - Enable RLS on products table
    - Add policies for organization-based access
*/

-- Create products table
CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  organization_id uuid REFERENCES organizations(id) NOT NULL,
  batch_size integer NOT NULL,
  price_inr decimal(10,2) NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger
CREATE TRIGGER update_products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create policies
DO $$ 
BEGIN
  -- Read policy
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'products' AND policyname = 'Users can view products from their organization'
  ) THEN
    CREATE POLICY "Users can view products from their organization"
      ON products FOR SELECT
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM users
          WHERE users.id = auth.uid()
          AND (
            -- Users can see products from their organization
            users.organization_id = products.organization_id
            OR
            -- Leumas staff can see all products
            users.organization_id = (SELECT id FROM organizations WHERE name = 'Leumas')
          )
        )
      );
  END IF;

  -- Write policy
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'products' AND policyname = 'Leumas admins and managers can manage products'
  ) THEN
    CREATE POLICY "Leumas admins and managers can manage products"
      ON products FOR ALL
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM users u
          JOIN roles r ON u.role_id = r.id
          WHERE u.id = auth.uid()
          AND u.organization_id = (SELECT id FROM organizations WHERE name = 'Leumas')
          AND r.name IN ('admin', 'manager')
        )
      );
  END IF;
END $$;

-- Insert initial products
INSERT INTO products (name, organization_id, batch_size, price_inr)
VALUES
  -- Mountainor Wellbeing products
  (
    'L Glutathione 60 Caps',
    get_org_id('Mountainor Wellbeing'),
    1000,
    101.00
  ),
  (
    'L Glutathione 30 Caps',
    get_org_id('Mountainor Wellbeing'),
    1000,
    71.00
  ),
  (
    'Facial Wax',
    get_org_id('Mountainor Wellbeing'),
    1000,
    56.00
  ),
  
  -- iThrive Wellness products
  (
    'B-Complex 60 Caps',
    get_org_id('iThrive Wellness'),
    500,
    350.00
  ),
  (
    'Krill Oil 60 Caps',
    get_org_id('iThrive Wellness'),
    500,
    1100.00
  ),
  (
    'Magnesium Bisglycinate',
    get_org_id('iThrive Wellness'),
    1000,
    950.00
  ),
  
  -- HyugaLife products
  (
    'Caffeine 120 mg',
    get_org_id('HyugaLife'),
    2000,
    27.00
  ),
  (
    'MSM + Glucasamanie',
    get_org_id('HyugaLife'),
    1000,
    123.00
  ),
  
  -- Trustco products
  (
    'Bloom Hair Serum',
    get_org_id('Trustco'),
    500,
    120.00
  ),
  (
    'Bloom Tablets',
    get_org_id('Trustco'),
    500, -- Assuming 500 as it wasn't specified
    190.00
  ),
  
  -- Spellbound products
  (
    'SpellQ10 Capsule',
    get_org_id('Spellbound'),
    200,
    100.00
  ),
  (
    'Spell Forte',
    get_org_id('Spellbound'),
    2000,
    120.00
  );