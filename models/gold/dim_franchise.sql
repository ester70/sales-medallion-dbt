{{ config(materialized='table') }}

select distinct franchiseID
from {{ ref('silver_sales_transactions_clean') }}
where is_active = true
