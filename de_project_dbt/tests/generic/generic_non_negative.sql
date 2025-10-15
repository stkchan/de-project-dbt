{% test generic_non_negative(model, column_name) %}

SELECT
    *
FROM
    {{ model }}
WHERE
        1=1
    AND {{ column_name }} < 0

{% endtest %}