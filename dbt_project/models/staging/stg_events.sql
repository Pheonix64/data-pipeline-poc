{{
  config(
    materialized='table',
    file_format='iceberg',
    schema='default_silver'
  )
}}

-- Staging model for raw events from bronze layer
-- This model cleans and standardizes the raw event data

SELECT
    event_id,
    event_type,
    user_id,
    event_timestamp,
    event_data,
    current_timestamp() as dbt_loaded_at
FROM {{ source('bronze', 'raw_events') }}
WHERE event_id IS NOT NULL
