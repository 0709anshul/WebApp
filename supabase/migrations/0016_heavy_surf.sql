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

-- Create updated_at trigger
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create policies
CREATE POLICY "enable_read_access_for_authenticated_users"
  ON users FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "enable_insert_for_first_user_or_admin"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Allow first user creation (becomes admin)
    NOT EXISTS (SELECT 1 FROM users)
    OR
    -- Allow admins to create users
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

CREATE POLICY "enable_update_for_admin"
  ON users FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  )
  WITH CHECK (true);

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