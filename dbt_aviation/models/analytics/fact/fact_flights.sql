with flights as (
    select * from {{ ref('sr_flights') }}
),

dim_airlines as (
    select airline_sk, iata_code from {{ ref('dim_airlines') }}
),

dim_airports as (
    select da.airport_sk, da.iata_code, sa.city_iata_code, da.country_iso2
    from {{ ref('dim_airports') }} da
    join {{ ref('sr_airports') }} sa on da.iata_code = sa.iata_code
),

dim_cities as (
    select city_sk, iata_code from {{ ref('dim_cities') }}
),

dim_countries as (
    select country_sk, country_iso2 from {{ ref('dim_countries') }}
),

dim_dates as (
    select date_sk, full_date from {{ ref('dim_dates') }}
),

dim_taxes as (
    select tax_sk, iata_code from {{ ref('dim_taxes') }}
),

fct_base as (
    select
        f.flight_date::date                                                             as flight_date,
        f.flight_status,
        f.dep_airport_iata,
        f.arr_airport_iata,
        f.flight_iata,

        -- surrogate keys
        da.airline_sk,
        null::bigint as airplane_sk,
        dap.airport_sk,
        dco.country_sk,
        dc.city_sk,
        dt.tax_sk,
        dd.date_sk,

        -- delay measures
        coalesce(f.dep_delay_minutes, 0)                                                as departure_delay_minutes,
        coalesce(f.arr_delay_minutes, 0)                                                as arrival_delay_minutes,

        -- flight time measures
        round(extract(epoch from (f.arr_actual_ts - f.dep_actual_ts)) / 60)::int       as total_flight_time_minutes,
        round(extract(epoch from (f.arr_scheduled_ts - f.dep_scheduled_ts)) / 60)::int as scheduled_flight_time_minutes,

        -- delay flags
        case
            when coalesce(f.dep_delay_minutes, 0) > 0
              or coalesce(f.arr_delay_minutes, 0) > 0 then 1 else 0
        end                                                                             as number_of_delay,

        case
            when f.flight_status = 'cancelled'         then 'Cancelled'
            when coalesce(f.dep_delay_minutes, 0) > 15 then 'Delayed'
            else 'On Time'
        end                                                                             as delay_status_flag,

        greatest(0, 100 - coalesce(f.dep_delay_minutes, 0))                            as on_time_performance_score,

        case when f.flight_status = 'cancelled' then true else false end                as is_cancelled

    from flights f
    left join dim_airlines  da     on f.airline_iata      = da.iata_code
    left join dim_airports  dap    on f.dep_airport_iata  = dap.iata_code
    left join dim_cities    dc     on dap.city_iata_code  = dc.iata_code
    left join dim_countries dco    on dap.country_iso2    = dco.country_iso2
    left join dim_dates     dd     on f.flight_date::date = dd.full_date
    left join dim_taxes     dt     on f.dep_airport_iata  = dt.iata_code
)

select
    row_number() over (order by flight_date, flight_iata)   as flight_sk,
    airline_sk,
    airplane_sk,
    airport_sk,
    country_sk,
    city_sk,
    tax_sk,
    date_sk,
    flight_date,
    flight_status,
    departure_delay_minutes,
    arrival_delay_minutes,
    total_flight_time_minutes,
    scheduled_flight_time_minutes,
    number_of_delay,
    round(
        case
            when coalesce(scheduled_flight_time_minutes, 0) = 0 then 0
            else departure_delay_minutes::decimal / scheduled_flight_time_minutes * 100
        end, 2
    )                                                       as delay_percentage,
    on_time_performance_score,
    delay_status_flag,
    is_cancelled
from fct_base
