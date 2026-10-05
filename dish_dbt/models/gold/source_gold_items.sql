with dedup_qry as (
    select *,
        row_number() over (partition by id order by updateDate desc) as duplication_id
    from   
        {{ source('source', 'items') }}
)
select id,
    name,
    category,
    updateDate
from dedup_qry
where duplication_id = 1