with sr_airplanes as (
    select * from {{ source('raw','airplanes') }}
)

select
        id::int,
        iata_type::varchar(30),
        airplane_id::int,
        coalesce(airline_iata_code, 'N/A')::varchar(3)  as airline_iata_code,
        iata_code_long::varchar(4),
        iata_code_short::varchar(3),
        coalesce(airline_icao_code::text, 'N/A')::varchar(4) as airline_icao_code,
        construction_number::varchar(20),

        case when delivery_date ='0000-00-00'then null
        else delivery_date::timestamp
        end as delivery_date,

        engines_count::int,
        engines_type::varchar(30),

        case when first_flight_date = '0000-00-00' then null
        else first_flight_date::timestamp
        end as first_flight_date,

        icao_code_hex::varchar(20),
        line_number::varchar(10),
        model_code::varchar(50),
        registration_number::varchar(10),
        test_registration_number::varchar(10),
        plane_age::int,
        model_name::varchar(50),
        plane_owner::varchar(100),
        plane_series::varchar(10),
        plane_status::varchar(50),
        production_line::varchar(50),

        case when registration_date ='0000-00-00'then null
        else registration_date::timestamp
        end as registration_date,

        
        case when rollout_date ='0000-00-00'then null
        else rollout_date::timestamp
        end as rollout_date
    from sr_airplanes