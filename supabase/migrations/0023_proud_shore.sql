/*
  # Add brand details fields

  1. Changes
    - Add contact information fields to organizations table
    - Add notes field for additional information
  
  2. Security
    - Maintain existing RLS policies
*/

-- Add new columns to organizations table
ALTER TABLE organizations
ADD COLUMN IF NOT EXISTS contact_person text,
ADD COLUMN IF NOT EXISTS email text,
ADD COLUMN IF NOT EXISTS phone text,
ADD COLUMN IF NOT EXISTS address text,
ADD COLUMN IF NOT EXISTS notes text;