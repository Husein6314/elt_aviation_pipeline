
select
    flight_date,
    flight_status,

    /* ======================
       DEPARTURE (JSON text)
       ====================== */
    (replace(departure, '''', '\u0027')::jsonb ->> 'iata')                         as dep_airport_iata,
    (replace(departure, '''', '\u0027')::jsonb ->> 'scheduled')::timestamp         as dep_scheduled_ts,
    (replace(departure, '''', '\u0027')::jsonb ->> 'actual')::timestamp            as dep_actual_ts,
    (replace(departure, '''', '\u0027')::jsonb ->> 'delay')::int                   as dep_delay_minutes,

    /* ======================
       ARRIVAL (JSON text)
       ====================== */
    (replace(arrival, '''', '\u0027')::jsonb ->> 'iata')                           as arr_airport_iata,
    (replace(arrival, '''', '\u0027')::jsonb ->> 'scheduled')::timestamp           as arr_scheduled_ts,
    (replace(arrival, '''', '\u0027')::jsonb ->> 'actual')::timestamp              as arr_actual_ts,
    (replace(arrival, '''', '\u0027')::jsonb ->> 'delay')::int                     as arr_delay_minutes,

    /* ======================
       AIRLINE (JSON text)
       ====================== */
    (replace(airline, '''', '\u0027')::jsonb ->> 'iata')                           as airline_iata,
    (replace(airline, '''', '\u0027')::jsonb ->> 'icao')                           as airline_icao,
    (replace(airline, '''', '\u0027')::jsonb ->> 'name')                           as airline_name,

    /* ======================
       FLIGHT (JSON text)
       ====================== */
    (replace(flight, '''', '\u0027')::jsonb ->> 'iata')                            as flight_iata,
    (replace(flight, '''', '\u0027')::jsonb ->> 'icao')                            as flight_icao,
    (replace(flight, '''', '\u0027')::jsonb ->> 'number')                          as flight_number,

    /* ======================
       NON-JSON
       ====================== */
    aircraft::text as aircraft_code,
    live

from {{ source('raw', 'flights') }}