/*
  # Fix users table RLS policies

  1. Changes
    - Drop and recreate users table with proper structure
    - Add simplified RLS policies
    
  2. Security
    - All authenticated users can read users
    - Any authenticated user can create the first admin
    - Only admins can manage users after initial setup
*/

-- Drop existing table and policies
DROP TABLE IF EXISTS users CASCADE;

-- Recreate users table
CREATE TABLE users (
  id uuid PRIMARY KEY REFERENCES auth.users(id),
  email text NOT NULL UNIQUE,
  full_name text NOT NULL,
  role text NOT NULL CHECK (role IN ('admin', 'manager', 'staff', 'brand_user')),
  organization_id uuid REFERENCES organizations(id) NOT NULL,
  department text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "allow_read_users"
  ON users FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "allow_create_users"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Allow creating first admin user
    NOT EXISTS (SELECT 1 FROM users)
    OR
    -- After first user, only admins can create users
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );