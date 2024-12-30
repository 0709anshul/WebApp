/*
  # User Management Setup

  1. Changes
    - Drop existing users table
    - Create new users table linked to auth.users
    - Add policies for admin access
    - Add function to check if user is admin

  2. Security
    - Only admin can manage users
    - Users can read their own data
*/

-- Drop existing users table and related policies
DROP TABLE IF EXISTS users CASCADE;

-- Create new users table
CREATE TABLE users (
  id uuid PRIMARY KEY REFERENCES auth.users(id),
  full_name text NOT NULL,
  email text NOT NULL UNIQUE,
  role text NOT NULL CHECK (role IN ('admin', 'manager', 'staff', 'brand_user')),
  organization_id uuid REFERENCES organizations(id) NOT NULL,
  department text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create admin check function
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Policies
CREATE POLICY "Users can view all users"
  ON users FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only admin can insert users"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (is_admin());

CREATE POLICY "Only admin can update users"
  ON users FOR UPDATE
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

CREATE POLICY "Only admin can delete users"
  ON users FOR DELETE
  TO authenticated
  USING (is_admin());

-- Create trigger for updated_at
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Note: Admin user will need to be created through the auth API first,
-- then their user record can be inserted into the users table.
-- This should be done through the application, not in the migration.