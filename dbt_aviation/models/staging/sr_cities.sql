with sr_cities as (
    select * from {{ source('raw', 'cities') }}
)

select
    id::int,
    gmt::interval AS utc_offset,
    city_id::int,
    iata_code::varchar(3),
    country_iso2::varchar(2),
    geoname_id::int,
    latitude::numeric(8,6) as latitude,
    longitude::numeric(9,6) as longitude,
    city_name::varchar(50),
    timezone::varchar(30)
from sr_cities
