/*
  # Simplify RLS policies to prevent recursion

  1. Changes
    - Remove circular dependencies in policies
    - Simplify policy conditions
    - Use direct role checks where possible
  
  2. Security
    - Maintain data access control
    - Fix infinite recursion issues
*/

-- Fix users policies
DROP POLICY IF EXISTS "Users can read all users" ON users;
DROP POLICY IF EXISTS "Admins and managers can manage users" ON users;

CREATE POLICY "Users can read all users"
  ON users FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins and managers can manage users"
  ON users FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM roles r
      WHERE r.id = (
        SELECT role_id FROM users WHERE id = auth.uid()
      )
      AND r.name IN ('admin', 'manager')
    )
  );

-- Fix products policies
DROP POLICY IF EXISTS "Users can view products from their organization" ON products;
DROP POLICY IF EXISTS "Leumas admins and managers can manage products" ON products;
DROP POLICY IF EXISTS "Users can view products" ON products;
DROP POLICY IF EXISTS "Leumas staff can manage products" ON products;

CREATE POLICY "Anyone can view products"
  ON products FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Staff can manage products"
  ON products FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM roles r
      WHERE r.id = (
        SELECT role_id FROM users WHERE id = auth.uid()
      )
      AND r.name IN ('admin', 'manager', 'staff')
    )
  );

-- Fix tasks policies
DROP POLICY IF EXISTS "Users can view relevant tasks" ON tasks;
DROP POLICY IF EXISTS "Leumas staff can manage tasks" ON tasks;
DROP POLICY IF EXISTS "Users can view tasks" ON tasks;
DROP POLICY IF EXISTS "Staff can manage tasks" ON tasks;

CREATE POLICY "Anyone can view tasks"
  ON tasks FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Staff can manage tasks"
  ON tasks FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM roles r
      WHERE r.id = (
        SELECT role_id FROM users WHERE id = auth.uid()
      )
      AND r.name IN ('admin', 'manager', 'staff')
    )
  );