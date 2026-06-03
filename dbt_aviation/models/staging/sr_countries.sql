with sr_countries as (
    select * from {{ source('raw', 'countries') }}
)

select
    id::int,
    capital::varchar(30),
    currency_code::varchar(3),
    fips_code::varchar(2),
    coalesce(country_iso2, 'XX')::varchar(2)   as country_iso2,
    country_iso3::varchar(3),
    case continent
        when 'AF' then 'Africa'
        when 'AS' then 'Asia'
        when 'EU' then 'Europe'
        when 'NA' then 'North America'
        when 'SA' then 'South America'
        when 'OC' then 'Oceania'
        when 'AN' then 'Antarctica'
        else 'Unknown'
    end                          as continent,
    country_id::int,
    country_name::varchar(50),
    currency_name::varchar(30),
    country_iso_numeric::int,
    phone_prefix::varchar(20),
    coalesce(population, 0)::int               as population
from sr_countries