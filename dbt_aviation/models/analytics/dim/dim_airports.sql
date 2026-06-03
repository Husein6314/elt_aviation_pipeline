with dim_airports as (
    select
        *,
        row_number() over(order by airport_id) as airport_sk 
from {{ ref('sr_airports') }}
)

select
        airport_sk,
        id,
        airport_id,
        iata_code,
        icao_code,
        country_iso2,
        latitude,
        longitude,
        airport_name,
        country_name,
        timezone
    from dim_airports

