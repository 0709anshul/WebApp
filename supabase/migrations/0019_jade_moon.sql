/*
  # Final fix for RLS policies
  
  1. Changes
    - Simplify policies to absolute minimum
    - Fix first user creation
    - Fix admin access
  
  2. Security
    - Read access for all authenticated users
    - Write access controlled by simple conditions
*/

-- Drop existing policies
DROP POLICY IF EXISTS "allow_read" ON users;
DROP POLICY IF EXISTS "allow_insert" ON users;
DROP POLICY IF EXISTS "allow_update" ON users;
DROP POLICY IF EXISTS "allow_delete" ON users;

-- Read access for all authenticated users
CREATE POLICY "allow_read"
  ON users FOR SELECT
  TO authenticated
  USING (true);

-- Insert allowed for first user or admin
CREATE POLICY "allow_insert"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Either no users exist (first user case)
    NOT EXISTS (SELECT 1 FROM users)
    OR
    -- Or the authenticated user is an admin
    auth.uid() IN (
      SELECT id FROM users WHERE role = 'admin'
    )
  );

-- Update allowed for admin only
CREATE POLICY "allow_update"
  ON users FOR UPDATE
  TO authenticated
  USING (
    auth.uid() IN (
      SELECT id FROM users WHERE role = 'admin'
    )
  );

-- Delete allowed for admin only
CREATE POLICY "allow_delete"
  ON users FOR DELETE
  TO authenticated
  USING (
    auth.uid() IN (
      SELECT id FROM users WHERE role = 'admin'
    )
  );