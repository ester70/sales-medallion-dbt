{{
  config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='transactionID'
  )
}}

-- Silver: cleaned + validated transactions.
-- Quality rules mirror the SDP expect_or_drop rules:
--   transactionID IS NOT NULL and totalPrice <> 0.
-- Soft deletes propagate automatically: a bronze row flagged is_active = false
-- flows here through the merge and overwrites the active version, so silver
-- keeps exactly one row per transactionID with the current is_active value.

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
    ingestion_time,
    source_system,
    is_active,
    to_date(dateTime) as sale_date
from {{ ref('bronze_sales_transactions') }}
where transactionID is not null
  and totalPrice <> 0
