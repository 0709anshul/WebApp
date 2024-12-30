-- Create order type enum
CREATE TYPE order_type AS ENUM ('Project Plan', 'Production Order', 'NPD Order');

-- Add order_type column to production_orders table
ALTER TABLE production_orders
ADD COLUMN order_type order_type NOT NULL DEFAULT 'Production Order';

-- Update existing orders to have a random type for demonstration
UPDATE production_orders
SET order_type = (
  ARRAY['Project Plan', 'Production Order', 'NPD Order']::order_type[]
)[floor(random() * 3 + 1)];

-- Remove the default after updating existing records
ALTER TABLE production_orders 
ALTER COLUMN order_type DROP DEFAULT;