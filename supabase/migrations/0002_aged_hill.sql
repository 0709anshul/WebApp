/*
  # Create users and roles system

  This migration establishes the user management system with roles and permissions.

  1. Tables
    - roles: User permission levels
    - users: Core user data with role assignments
  
  2. Security
    - RLS enabled on both tables
    - Policies for role-based access control
*/

-- Create roles table first
CREATE TABLE IF NOT EXISTS roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  description text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Basic roles data
INSERT INTO roles (name, description) VALUES
  ('admin', 'Main administrator with all permissions'),
  ('manager', 'Can manage users, products, orders, and tasks'),
  ('staff', 'Can manage tasks and proof of work'),
  ('brand_user', 'Can view orders and manage proof of work')
ON CONFLICT (name) DO NOTHING;

-- Helper functions
CREATE OR REPLACE FUNCTION get_role_id(role_name text)
RETURNS uuid AS $$
  SELECT id FROM roles WHERE name = role_name;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_org_id(org_name text)
RETURNS uuid AS $$
  SELECT id FROM organizations WHERE name = org_name;
$$ LANGUAGE SQL;

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY,
  full_name text NOT NULL,
  organization_id uuid REFERENCES organizations(id) NOT NULL,
  role_id uuid REFERENCES roles(id) NOT NULL,
  department text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Basic policies
DO $$ 
BEGIN
  -- Roles policy
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'roles' AND policyname = 'Allow authenticated users to read roles'
  ) THEN
    CREATE POLICY "Allow authenticated users to read roles"
      ON roles FOR SELECT
      TO authenticated
      USING (true);
  END IF;

  -- Users policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'users' AND policyname = 'Users can read all users'
  ) THEN
    CREATE POLICY "Users can read all users"
      ON users FOR SELECT
      TO authenticated
      USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'users' AND policyname = 'Admins and managers can manage users'
  ) THEN
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
  END IF;
END $$;

-- Insert Leumas admin and managers first
INSERT INTO users (id, full_name, organization_id, role_id)
SELECT 
  gen_random_uuid(),
  name,
  get_org_id('Leumas'),
  role_id
FROM (
  VALUES 
    ('Nitesh Kumar', get_role_id('admin')),
    ('Sandeep Boora', get_role_id('manager')),
    ('Subhajit Biswas', get_role_id('manager'))
) AS t(name, role_id);

-- Insert Leumas staff
INSERT INTO users (id, full_name, organization_id, role_id, department)
SELECT 
  gen_random_uuid(),
  name,
  get_org_id('Leumas'),
  get_role_id('staff'),
  dept
FROM (
  VALUES 
    ('Gautam Sahoo', 'Formulation'),
    ('Stalin Joseph', 'Production'),
    ('Vishal Kumar', 'Sourcing')
) AS t(name, dept);

-- Insert brand users
INSERT INTO users (id, full_name, organization_id, role_id)
SELECT 
  gen_random_uuid(),
  name,
  get_org_id(org),
  get_role_id('brand_user')
FROM (
  VALUES 
    ('Sheikh', 'Mountainor Wellbeing'),
    ('Aditya', 'iThrive Wellness'),
    ('Sukruth', 'HyugaLife'),
    ('Yatharth', 'Trustco'),
    ('Ishita', 'Spellbound')
) AS t(name, org);