SELECT
    *,
    CURRENT_TIMESTAMP() AS updated_at
FROM
{{ source('source', 'dim_product') }}