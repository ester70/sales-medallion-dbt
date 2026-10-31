{{ config(materialized='table') }}

select distinct paymentMethod
from {{ ref('silver_sales_transactions_clean') }}
where is_active = true
