with sr_airports as (
    select * from {{ source('raw', 'airports') }}
)

select
    id::int,
    gmt::interval AS utc_offset,
    airport_id::int,
    iata_code::varchar(3),
    city_iata_code::varchar(3),
    icao_code::varchar(4),
    country_iso2::varchar(2),
    geoname_id::int,
    latitude::numeric(8,6) as latitude,
    longitude::numeric(9,6) as longitude,
    airport_name::varchar(50),
    country_name::varchar(50),
    phone_number::varchar(20),
    timezone::varchar(50)
    from sr_airports