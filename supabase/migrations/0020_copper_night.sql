-- Disable RLS on all tables
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE organizations DISABLE ROW LEVEL SECURITY;
ALTER TABLE products DISABLE ROW LEVEL SECURITY;
ALTER TABLE production_orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE tasks DISABLE ROW LEVEL SECURITY;
ALTER TABLE task_history DISABLE ROW LEVEL SECURITY;
ALTER TABLE task_templates DISABLE ROW LEVEL SECURITY;
ALTER TABLE task_template_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE roles DISABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DROP POLICY IF EXISTS "allow_read" ON users;
DROP POLICY IF EXISTS "allow_insert" ON users;
DROP POLICY IF EXISTS "allow_update" ON users;
DROP POLICY IF EXISTS "allow_delete" ON users;

DROP POLICY IF EXISTS "Allow authenticated users to read organizations" ON organizations;
DROP POLICY IF EXISTS "Allow admin users to manage organizations" ON organizations;

DROP POLICY IF EXISTS "Anyone can view products" ON products;
DROP POLICY IF EXISTS "Staff can manage products" ON products;

DROP POLICY IF EXISTS "Users can view relevant production orders" ON production_orders;
DROP POLICY IF EXISTS "Leumas staff can manage production orders" ON production_orders;

DROP POLICY IF EXISTS "Users can view relevant tasks" ON tasks;
DROP POLICY IF EXISTS "Staff can manage tasks" ON tasks;

DROP POLICY IF EXISTS "Users can view relevant task history" ON task_history;
DROP POLICY IF EXISTS "Leumas staff can add task history" ON task_history;

DROP POLICY IF EXISTS "Anyone can view active templates" ON task_templates;
DROP POLICY IF EXISTS "Leumas staff can manage templates" ON task_templates;

DROP POLICY IF EXISTS "Anyone can view template items" ON task_template_items;
DROP POLICY IF EXISTS "Leumas staff can manage template items" ON task_template_items;