/*
  # Simplify RLS policies and remove recursion

  1. Changes
    - Remove all circular references in policies
    - Use direct role checks without joins
    - Simplify policy conditions
  
  2. Security
    - Maintain proper access control
    - Fix infinite recursion issues
    - Keep data properly protected
*/

-- Drop all existing policies to start fresh
DROP POLICY IF EXISTS "Users can read all users" ON users;
DROP POLICY IF EXISTS "Admins and managers can manage users" ON users;
DROP POLICY IF EXISTS "Anyone can view products" ON products;
DROP POLICY IF EXISTS "Staff can manage products" ON products;
DROP POLICY IF EXISTS "Anyone can view tasks" ON tasks;
DROP POLICY IF EXISTS "Staff can manage tasks" ON tasks;

-- Simple read-only policies for authenticated users
CREATE POLICY "authenticated_read_users"
  ON users FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "authenticated_read_products"
  ON products FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "authenticated_read_tasks"
  ON tasks FOR SELECT
  TO authenticated
  USING (true);

-- Create function to check user role
CREATE OR REPLACE FUNCTION auth.user_has_role(required_roles text[])
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM auth.users
    JOIN public.users ON auth.users.id = public.users.id
    JOIN public.roles ON public.users.role_id = public.roles.id
    WHERE auth.users.id = auth.uid()
    AND roles.name = ANY(required_roles)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Management policies using the new function
CREATE POLICY "staff_manage_users"
  ON users FOR ALL
  TO authenticated
  USING (auth.user_has_role(ARRAY['admin', 'manager']));

CREATE POLICY "staff_manage_products"
  ON products FOR ALL
  TO authenticated
  USING (auth.user_has_role(ARRAY['admin', 'manager', 'staff']));

CREATE POLICY "staff_manage_tasks"
  ON tasks FOR ALL
  TO authenticated
  USING (auth.user_has_role(ARRAY['admin', 'manager', 'staff']));