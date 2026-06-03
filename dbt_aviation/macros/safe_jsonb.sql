{% macro safe_jsonb(col) %}
    replace({{ col }}::text, '''', '\u0027')::jsonb
{% endmacro %}
