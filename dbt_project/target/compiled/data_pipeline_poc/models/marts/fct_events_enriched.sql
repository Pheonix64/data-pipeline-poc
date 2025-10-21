

-- Mart model: Events enriched with user information
-- This model joins event data with user data for analytics

WITH events AS (
    SELECT * FROM default_default_silver.stg_events
),

users AS (
    SELECT * FROM default_default_silver.stg_users
),

enriched AS (
    SELECT
        e.event_id,
        e.event_type,
        e.event_timestamp,
        e.event_data,
        e.user_id,
        u.user_name,
        u.user_email,
        u.created_at as user_created_at,
        e.dbt_loaded_at
    FROM events e
    LEFT JOIN users u ON e.user_id = u.user_id
)

SELECT * FROM enriched