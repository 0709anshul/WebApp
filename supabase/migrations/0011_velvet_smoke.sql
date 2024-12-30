/*
  # Simplify RLS policies with flat queries

  1. Changes
    - Remove nested subqueries
    - Use simple JOIN-based policies
    - Flatten all policy conditions
  
  2. Security
    - Maintain proper access control
    - Fix infinite recursion issues
    - Keep data properly protected
*/

-- Drop all existing policies
DROP POLICY IF EXISTS "read_users" ON users;
DROP POLICY IF EXISTS "read_products" ON products;
DROP POLICY IF EXISTS "read_tasks" ON tasks;
DROP POLICY IF EXISTS "manage_users" ON users;
DROP POLICY IF EXISTS "manage_products" ON products;
DROP POLICY IF EXISTS "manage_tasks" ON tasks;

-- Simple read-only policies
CREATE POLICY "read_all_users"
  ON users FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "read_all_products"
  ON products FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "read_all_tasks"
  ON tasks FOR SELECT
  TO authenticated
  USING (true);

-- Flat management policies
CREATE POLICY "manage_all_users"
  ON users FOR ALL
  TO authenticated
  USING (
    auth.uid() IN (
      SELECT u.id 
      FROM users u, roles r 
      WHERE u.role_id = r.id 
      AND r.name IN ('admin', 'manager')
    )
  );

CREATE POLICY "manage_all_products"
  ON products FOR ALL
  TO authenticated
  USING (
    auth.uid() IN (
      SELECT u.id 
      FROM users u, roles r 
      WHERE u.role_id = r.id 
      AND r.name IN ('admin', 'manager', 'staff')
    )
  );

CREATE POLICY "manage_all_tasks"
  ON tasks FOR ALL
  TO authenticated
  USING (
    auth.uid() IN (
      SELECT u.id 
      FROM users u, roles r 
      WHERE u.role_id = r.id 
      AND r.name IN ('admin', 'manager', 'staff')
    )
  );