{# Generic test: column must never be ZERO (negative transactions e.g. refunds are allowed) #}
{% test non_zero(model, column_name) %}

select *
from {{ model }}
where {{ column_name }} = 0

{% endtest %}
