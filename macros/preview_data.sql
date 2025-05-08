{% macro preview_data(model_name, limit=10) %}
    select * from {{ ref(model_name) }} limit {{ limit }}
{% endmacro %} 