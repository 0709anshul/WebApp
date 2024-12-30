/*
  # Add welcome message to organizations

  1. Changes
    - Add welcome_message column to organizations table for rich text content
  
  2. Security
    - Maintain existing RLS policies
*/

-- Add welcome_message column
ALTER TABLE organizations
ADD COLUMN IF NOT EXISTS welcome_message text;