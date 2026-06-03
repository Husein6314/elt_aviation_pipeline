with dim_dates as (
    select distinct flight_date::date as full_date
    from {{ ref('sr_flights') }}
)
    select
        row_number() over(order by full_date) as date_sk,
        full_date,
        extract(year from full_date)::int as year,
        'Q' || extract(quarter from full_date)::varchar(2) as quarter,
        extract(quarter from full_date)::smallint as quarter_number,
        to_char(full_date, 'Month') as month,
        extract(month from full_date)::smallint as month_number,
        to_char(full_date, 'Mon') as month_short_name,
        to_char(full_date, 'YYYY-MM') as year_month,
        extract(week from full_date)::smallint as week_number,
        to_char(full_date, 'Day') as week_day_name,
        extract(dow from full_date)::smallint as week_day_number,
        extract(day from full_date)::smallint as day_of_month,
        extract(doy from full_date)::smallint as day_of_year,
        case when extract(dow from full_date) in (0,6) then true else false end as is_week_end,
        false as is_holiday
    from dim_dates
