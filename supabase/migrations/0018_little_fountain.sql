/*
  # Simplify RLS policies for users table
  
  1. Changes
    - Simplify policies to basic CRUD operations
    - Remove complex policy conditions
    - Ensure first user creation works
  
  2. Security
    - Read access for all authenticated users
    - Write access for first user creation
    - Admin-only access for subsequent operations
*/

-- Drop existing policies
DROP POLICY IF EXISTS "enable_read_access_for_all_authenticated_users" ON users;
DROP POLICY IF EXISTS "enable_insert_for_first_user_or_admin" ON users;
DROP POLICY IF EXISTS "enable_update_for_admin" ON users;
DROP POLICY IF EXISTS "enable_update_for_self" ON users;
DROP POLICY IF EXISTS "enable_delete_for_admin" ON users;

-- Simple read policy
CREATE POLICY "allow_read"
  ON users FOR SELECT
  TO authenticated
  USING (true);

-- Simple insert policy
CREATE POLICY "allow_insert"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Allow first user or admin
    NOT EXISTS (SELECT 1 FROM users)
    OR
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );

-- Simple update policy
CREATE POLICY "allow_update"
  ON users FOR UPDATE
  TO authenticated
  USING (
    -- Only admins can update
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );

-- Simple delete policy
CREATE POLICY "allow_delete"
  ON users FOR DELETE
  TO authenticated
  USING (
    -- Only admins can delete
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );