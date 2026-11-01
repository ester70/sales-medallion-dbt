{{ config(materialized='table') }}

-- Franchise dimension: business keys from silver; attributes (name/city/
-- district/country/size) joined from bronze_sales_franchises.
select distinct
    s.franchiseID,
    f.name  as franchise_name,
    f.city,
    f.district,
    f.country,
    f.size  as franchise_size
from {{ ref('silver_sales_transactions_clean') }} s
left join {{ ref('bronze_sales_franchises') }} f
    on s.franchiseID = f.franchiseID
   and f.is_active = true
where s.is_active = true
