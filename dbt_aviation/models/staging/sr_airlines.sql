with sr_airline as (
    select * from {{ source('raw', 'airlines') }}
)
select
    id::int,
    fleet_average_age::decimal(4,1) as fleet_average_age,
    airline_id::int,
    callsign::varchar(30),
    hub_code::varchar(3),
    iata_code::varchar(2),
    icao_code::varchar(3),
    coalesce(country_iso2, 'XX')::varchar(2)   as country_iso2,
    date_founded::int as date_founded,
    iata_prefix_accounting::int,
    airline_name::varchar(100),
    country_name::varchar(30),
    fleet_size::int,
    status::varchar(30),
    type::varchar(30)
    from sr_airline