{{ config(materialized='table') }}

select distinct product
from {{ ref('silver_sales_transactions_clean') }}
where is_active = true
