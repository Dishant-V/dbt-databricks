select 
* 
from {{ source('source', 'bronze_sales') }}
where 
{{ column_name }} < 0
