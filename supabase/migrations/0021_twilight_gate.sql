/*
  # Update product policies

  1. Changes
    - Drop existing policies
    - Create new policies for products table
    - Allow read access for all authenticated users
    - Allow write access for admin and manager roles
  
  2. Security
    - Enable RLS on products table
    - Add policy for read access
    - Add policy for write access (admin/manager only)
*/

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "allow_read_products" ON products;
DROP POLICY IF EXISTS "allow_manage_products" ON products;
DROP POLICY IF EXISTS "Anyone can view products" ON products;
DROP POLICY IF EXISTS "Staff can manage products" ON products;

-- Re-enable RLS for products
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Create new policies
CREATE POLICY "products_read_policy"
  ON products FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "products_write_policy"
  ON products FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('admin', 'manager')
    )
  );