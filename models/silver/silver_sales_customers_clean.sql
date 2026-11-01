{{
  config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='customerID'
  )
}}

-- Silver: cleaned + validated customers.
-- Quality rule: customerID IS NOT NULL. Rows with an empty/NULL unique key
-- are rejected here: they cannot be soft-deleted by a merge because a NULL
-- key never matches the merge ON clause and such a row would be re-inserted
-- on every run, accumulating duplicates. They remain fully preserved in
-- bronze_sales_customers (never physically deleted).
-- Soft deletes propagate automatically: a bronze row flagged is_active = false
-- flows here through the merge and overwrites the active version, so silver
-- keeps exactly one row per customerID with the current is_active value.
-- Cleaning: trim text fields, normalize email to lowercase.

select
    customerID,
    trim(first_name)            as first_name,
    trim(last_name)             as last_name,
    lower(trim(email_address))  as email_address,
    trim(phone_number)          as phone_number,
    trim(address)               as address,
    trim(city)                  as city,
    trim(state)                 as state,
    trim(country)               as country,
    trim(continent)             as continent,
    postal_zip_code,
    trim(gender)                as gender,
    ingestion_time,
    source_system,
    is_active
from {{ ref('bronze_sales_customers') }}
where customerID is not null
