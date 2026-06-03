with dim_airline as (
    select 
        *,
        row_number() over(order by airline_id) as airline_sk
    from {{ ref('sr_airlines') }}
)
select
        airline_sk,
        id,
        airline_id,
        fleet_average_age,
        iata_code,
        icao_code,
        country_iso2,
        date_founded,
        airline_name,
        country_name,
        fleet_size,
        status,
        type
    from dim_airline