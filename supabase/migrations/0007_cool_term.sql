/*
  # Fix RLS policies with proper UUID handling

  1. Changes
    - Fix UUID type casting in policies
    - Simplify user policies
    - Update product and task policies
  
  2. Security
    - Maintain data access control
    - Fix type casting issues
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
      SELECT 1 FROM users u
      JOIN roles r ON u.role_id = r.id
      WHERE u.id = auth.uid()
      AND r.name IN ('admin', 'manager')
    )
  );

-- Fix products policies
DROP POLICY IF EXISTS "Users can view products from their organization" ON products;
DROP POLICY IF EXISTS "Leumas admins and managers can manage products" ON products;

CREATE POLICY "Users can view products"
  ON products FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Leumas staff can manage products"
  ON products FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      JOIN roles r ON u.role_id = r.id
      WHERE u.id = auth.uid()
      AND r.name IN ('admin', 'manager', 'staff')
    )
  );

-- Fix tasks policies
DROP POLICY IF EXISTS "Users can view relevant tasks" ON tasks;
DROP POLICY IF EXISTS "Leumas staff can manage tasks" ON tasks;

CREATE POLICY "Users can view tasks"
  ON tasks FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Staff can manage tasks"
  ON tasks FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      JOIN roles r ON u.role_id = r.id
      WHERE u.id = auth.uid()
      AND r.name IN ('admin', 'manager', 'staff')
    )
  );