with dim_taxes as (
    select 
    *,
    row_number() over(order by tax_id) as tax_sk
    from {{ ref('sr_taxes') }}
)

select
    tax_sk,
    id,
    tax_id,
    tax_name,
    iata_code
from dim_taxes