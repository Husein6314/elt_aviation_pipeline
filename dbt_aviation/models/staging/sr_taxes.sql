with sr_taxes as (
    select * from {{ source('raw', 'taxes') }}
)

select
    id::int,
    tax_id::int,
    tax_name::text,
    coalesce(iata_code, 'N/A')::varchar(3)     as iata_code
from sr_taxes