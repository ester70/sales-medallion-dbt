{{
  config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='franchiseID'
  )
}}

-- Silver: cleaned + validated franchises.
-- Quality rule: franchiseID IS NOT NULL. Rows with an empty/NULL unique key
-- are rejected here: they cannot be soft-deleted by a merge because a NULL
-- key never matches the merge ON clause and such a row would be re-inserted
-- on every run, accumulating duplicates. They remain fully preserved in
-- bronze_sales_franchises (never physically deleted).
-- Soft deletes propagate automatically: a bronze row flagged is_active = false
-- flows here through the merge and overwrites the active version, so silver
-- keeps exactly one row per franchiseID with the current is_active value.
-- Cleaning: trim text fields.

select
    franchiseID,
    trim(name)      as name,
    trim(city)      as city,
    trim(district)  as district,
    trim(zipcode)   as zipcode,
    trim(country)   as country,
    trim(size)      as size,
    longitude,
    latitude,
    supplierID,
    ingestion_time,
    source_system,
    is_active
from {{ ref('bronze_sales_franchises') }}
where franchiseID is not null
