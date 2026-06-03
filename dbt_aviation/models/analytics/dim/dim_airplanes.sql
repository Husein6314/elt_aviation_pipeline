with dim_airplanes as (
    select
        *,
        row_number() over(order by airplane_id) as airplane_sk
from {{ ref('sr_airplanes') }}
)

select
        airplane_sk,
        id,
        airplane_id,
        iata_type,
        engines_count,
        engines_type,
        first_flight_date,
        line_number,
        plane_age,
        model_code,
        model_name,
        plane_owner,
        plane_status,
        production_line
    from dim_airplanes