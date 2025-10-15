SELECT
    *
FROM
    {{ ref('bronze_sales') }}
WHERE
    1=1
    AND gross_amount < 0
    AND net_amount < 0