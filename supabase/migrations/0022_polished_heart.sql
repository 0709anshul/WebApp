/*
  # Update users table structure

  1. Changes
    - Remove department column from users table
    - Update existing policies
  
  2. Security
    - Maintain existing RLS policies
*/

-- Remove department column
ALTER TABLE users DROP COLUMN IF EXISTS department;