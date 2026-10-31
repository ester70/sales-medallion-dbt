{{ config(materialized='table') }}

select distinct
    sale_date,
    year(sale_date)      as year,
    month(sale_date)     as month,
    day(sale_date)       as day,
    dayofweek(sale_date) as day_of_week,
    quarter(sale_date)  as quarter
from {{ ref('silver_sales_transactions_clean') }}
where is_active = true
