with dim_cities as (
    select
        *,
        row_number() over(order by city_id) as city_sk        
    from {{ ref('sr_cities') }}
)

select  
        city_sk,
        id,
        city_id,
        city_name,
        utc_offset,
        iata_code,
        country_iso2,
        latitude,
        longitude,
        timezone
from dim_cities