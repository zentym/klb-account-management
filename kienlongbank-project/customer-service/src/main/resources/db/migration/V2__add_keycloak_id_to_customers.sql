-- Migration script to add keycloak_id column to customers table
-- Purpose: Link Customer entity with Keycloak user identity
-- Date: August 2025

-- Add keycloak_id column to customers table
ALTER TABLE customers 
ADD COLUMN keycloak_id VARCHAR(255);

-- Add unique constraint to ensure one customer per Keycloak user
ALTER TABLE customers 
ADD CONSTRAINT uk_customers_keycloak_id UNIQUE (keycloak_id);

-- Create index for faster lookup by keycloak_id
CREATE INDEX idx_customers_keycloak_id ON customers(keycloak_id);

-- Optional: Add comment to document the purpose
COMMENT ON COLUMN customers.keycloak_id IS 'Keycloak user ID for linking customer to identity provider';

-- Example usage after migration:
-- SELECT * FROM customers WHERE keycloak_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
