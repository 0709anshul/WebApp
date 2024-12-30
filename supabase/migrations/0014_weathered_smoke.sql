/*
  # Update users table RLS policies

  1. Changes
    - Drop existing policies
    - Add simplified RLS policies for users table
    - Remove circular dependency with is_admin function
    
  2. Security
    - All authenticated users can read users
    - Only admin users can manage users
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view all users" ON users;
DROP POLICY IF EXISTS "Only admin can insert users" ON users;
DROP POLICY IF EXISTS "Only admin can update users" ON users;
DROP POLICY IF EXISTS "Only admin can delete users" ON users;

-- Drop the function as it creates circular dependency
DROP FUNCTION IF EXISTS is_admin;

-- Create simplified policies
-- Allow viewing users for all authenticated users
CREATE POLICY "allow_read_users"
  ON users FOR SELECT
  TO authenticated
  USING (true);

-- Allow admin to create users
CREATE POLICY "allow_admin_create_users"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
    OR NOT EXISTS (SELECT 1 FROM users)
  );

-- Allow admin to update users
CREATE POLICY "allow_admin_update_users"
  ON users FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Allow admin to delete users
CREATE POLICY "allow_admin_delete_users"
  ON users FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );