{{ config(materialized='table') }}

-- Customer dimension: business keys from silver; attributes (city/state/
-- country/continent/gender) joined from silver_sales_customers_clean.
select distinct
    s.customerID,
    c.first_name,
    c.last_name,
    c.city,
    c.state,
    c.country,
    c.continent,
    c.gender
from {{ ref('silver_sales_transactions_clean') }} s
left join {{ ref('silver_sales_customers_clean') }} c
    on s.customerID = c.customerID
   and c.is_active = true
where s.is_active = true
