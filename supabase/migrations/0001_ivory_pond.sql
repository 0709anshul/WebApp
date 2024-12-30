/*
  # Create organizations table

  1. New Table
    - `organizations`
      - `id` (uuid, primary key): Unique identifier for each organization
      - `name` (text): Name of the organization
      - `type` (text): Type of organization (Manufacturing Company or Customer Brand)
      - `created_at` (timestamptz): Timestamp of creation
      - `updated_at` (timestamptz): Timestamp of last update

  2. Security
    - Enable RLS on `organizations` table
    - Add policies for authenticated users to read organizations
    - Add policies for admin users to manage organizations
*/

-- Create enum for organization types
CREATE TYPE organization_type AS ENUM ('Manufacturing Company', 'Customer Brand');

-- Create organizations table
CREATE TABLE IF NOT EXISTS organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  type organization_type NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow authenticated users to read organizations"
  ON organizations
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow admin users to manage organizations"
  ON organizations
  FOR ALL
  TO authenticated
  USING (auth.jwt() ? 'is_admin' = 'true');

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_organizations_updated_at
  BEFORE UPDATE ON organizations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Insert initial organizations
INSERT INTO organizations (name, type) VALUES
  ('Leumas', 'Manufacturing Company'),
  ('Mountainor Wellbeing', 'Customer Brand'),
  ('iThrive Wellness', 'Customer Brand'),
  ('HyugaLife', 'Customer Brand'),
  ('Trustco', 'Customer Brand'),
  ('Spellbound', 'Customer Brand')
ON CONFLICT (name) DO NOTHING;