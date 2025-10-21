

-- Staging model for raw users from bronze layer
-- This model cleans and standardizes the raw user data

SELECT
    user_id,
    user_name,
    email as user_email,
    created_at,
    current_timestamp() as dbt_loaded_at
FROM bronze.raw_users
WHERE user_id IS NOT NULL