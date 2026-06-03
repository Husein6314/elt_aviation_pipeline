with dim_countries as (
    select
    *,
    row_number() over(order by country_id) as country_sk
    from {{ ref('sr_countries') }}
)

select
    country_sk,
    id,
    country_id,
    country_name,
    capital,
    continent,
    country_iso2,
    country_iso3,
    currency_code,
    currency_name,
    population
from dim_countries