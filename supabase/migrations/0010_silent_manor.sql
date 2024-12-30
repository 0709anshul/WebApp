/*
  # Simplify RLS policies with direct role checks

  1. Changes
    - Remove function-based approach
    - Use direct role checks with joins
    - Simplify policy conditions
  
  2. Security
    - Maintain proper access control
    - Fix infinite recursion issues
    - Keep data properly protected
*/

-- Drop all existing policies
DROP POLICY IF EXISTS "authenticated_read_users" ON users;
DROP POLICY IF EXISTS "authenticated_read_products" ON products;
DROP POLICY IF EXISTS "authenticated_read_tasks" ON tasks;
DROP POLICY IF EXISTS "staff_manage_users" ON users;
DROP POLICY IF EXISTS "staff_manage_products" ON products;
DROP POLICY IF EXISTS "staff_manage_tasks" ON tasks;

-- Drop the function as we're not using it anymore
DROP FUNCTION IF EXISTS auth.user_has_role;

-- Simple read policies
CREATE POLICY "read_users"
  ON users FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "read_products"
  ON products FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "read_tasks"
  ON tasks FOR SELECT
  TO authenticated
  USING (true);

-- Management policies with direct role checks
CREATE POLICY "manage_users"
  ON users 
  USING (
    EXISTS (
      SELECT 1 FROM roles
      WHERE roles.id = (SELECT role_id FROM users WHERE users.id = auth.uid())
      AND roles.name IN ('admin', 'manager')
    )
  );

CREATE POLICY "manage_products"
  ON products 
  USING (
    EXISTS (
      SELECT 1 FROM roles
      WHERE roles.id = (SELECT role_id FROM users WHERE users.id = auth.uid())
      AND roles.name IN ('admin', 'manager', 'staff')
    )
  );

CREATE POLICY "manage_tasks"
  ON tasks 
  USING (
    EXISTS (
      SELECT 1 FROM roles
      WHERE roles.id = (SELECT role_id FROM users WHERE users.id = auth.uid())
      AND roles.name IN ('admin', 'manager', 'staff')
    )
  );