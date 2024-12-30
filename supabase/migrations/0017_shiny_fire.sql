/*
  # Update RLS policies for users table
  
  1. Changes
    - Simplify policies to avoid NEW/OLD references
    - Add separate policies for different operations
    - Maintain security while fixing syntax errors
  
  2. Security
    - Read access for all authenticated users
    - Write access controlled by admin role
    - Self-update allowed for non-role fields
*/

-- Drop existing policies
DROP POLICY IF EXISTS "enable_read_access_for_authenticated_users" ON users;
DROP POLICY IF EXISTS "enable_insert_for_first_user_or_admin" ON users;
DROP POLICY IF EXISTS "enable_update_for_admin" ON users;
DROP POLICY IF EXISTS "enable_delete_for_admin" ON users;

-- Create new policies with proper checks
CREATE POLICY "enable_read_access_for_all_authenticated_users"
  ON users FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "enable_insert_for_first_user_or_admin"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (
    NOT EXISTS (SELECT 1 FROM users)
    OR
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Split update policy into two: one for admins, one for self-updates
CREATE POLICY "enable_update_for_admin"
  ON users FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

CREATE POLICY "enable_update_for_self"
  ON users FOR UPDATE
  TO authenticated
  USING (
    auth.uid() = id
  )
  WITH CHECK (
    -- Users can only update non-role fields
    role = (SELECT role FROM users WHERE id = auth.uid())
  );

CREATE POLICY "enable_delete_for_admin"
  ON users FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );