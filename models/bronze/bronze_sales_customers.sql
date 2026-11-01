{{
  config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='customerID',
    merge_exclude_columns=['ingestion_time'],
    post_hook=[
      "update {{ this }} set is_active = false
       where is_active = true
         and customerID not in (select customerID from {{ source('bakehouse', 'sales_customers') }})"
    ]
  )
}}

-- Bronze copy of the bakehouse customers reference table.
-- Same pattern as bronze_sales_transactions: full comparison every run
-- (deliberately NO is_incremental() filter -- cheap at ~300 rows), merge on
-- customerID, post_hook soft-deletes rows that disappeared upstream.
--
-- Behavior:
--   new source row       -> inserted with is_active = true
--   existing row changed -> updated in place (merge)
--   row removed upstream -> post_hook flips is_active to false (soft delete)
--   row re-appears       -> merge flips is_active back to true

select
    customerID,
    first_name,
    last_name,
    email_address,
    phone_number,
    address,
    city,
    state,
    country,
    continent,
    postal_zip_code,
    gender,
    current_timestamp() as ingestion_time,
    'samples.bakehouse' as source_system,
    true as is_active
from {{ source('bakehouse', 'sales_customers') }}
