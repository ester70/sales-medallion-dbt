{{
  config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='transactionID'
  )
}}

-- Gold fact table: one row per transaction, joined to the dimensions by
-- natural keys. is_active is carried so soft-deleted transactions remain
-- queryable but can be filtered with WHERE is_active = true.

select
    transactionID,
    customerID    as customer_id,
    franchiseID   as franchise_id,
    product       as product_name,
    sale_date,
    paymentMethod as payment_method,
    is_active,
    quantity,
    unitPrice     as unit_price,
    totalPrice    as total_price
from {{ ref('silver_sales_transactions_clean') }}
