{{
  config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='transactionID',
    merge_exclude_columns=['ingestion_time'],
    post_hook=[
      "update {{ this }} set is_active = false
       where is_active = true
         and transactionID not in (select transactionID from {{ source('bakehouse', 'sales_transactions') }})"
    ]
  )
}}

-- Bronze: full comparison every run (deliberately NO is_incremental() filter).
-- The price for detecting updated/deleted source rows without Change Data Feed
-- is one full scan per run -- cheap at this scale (~3.3K rows).
--
-- Behavior:
--   new source row       -> inserted with is_active = true
--   existing row changed -> updated in place (merge)
--   row removed upstream -> post_hook flips is_active to false (soft delete)
--   row re-appears       -> merge flips is_active back to true

select
    transactionID,
    customerID,
    franchiseID,
    dateTime,
    product,
    quantity,
    unitPrice,
    totalPrice,
    paymentMethod,
    cardNumber,
    current_timestamp() as ingestion_time,
    'samples.bakehouse' as source_system,
    true as is_active
from {{ source('bakehouse', 'sales_transactions') }}
qualify row_number() over (partition by transactionID order by dateTime desc) = 1
