WITH bronze_sales AS (
    SELECT
        sales_id,
        product_sk,
        customer_sk,
        ROUND(gross_amount, 2) AS gross_amount,
        ROUND({{ multiply('unit_price', 'quantity') }}, 2) AS total_sales,
        ROUND(discount_amount, 2) AS discount_amount,
        payment_method

    FROM
        {{ ref('bronze_sales') }} 
)

, bronze_products AS (
    SELECT
        product_sk,
        category

    FROM
        {{ ref('bronze_dim_product') }}
)

, bronze_customer AS (
    SELECT
        customer_sk,
        gender,
        loyalty_tier

    FROM
        {{ ref('bronze_dim_customer') }}
)

SELECT
    bz.sales_id,
    bz.product_sk,
    bz.customer_sk,
    bz.gross_amount,
    bz.total_sales,
    bz.discount_amount,
    bz.payment_method,
    bc.gender,
    bc.loyalty_tier

FROM
    bronze_sales        AS bz
INNER JOIN
    bronze_dim_product  AS bp 
ON  bz.product_sk = bp.product_sk
INNER JOIN
    bronze_customer     AS bc
ON  bz.customer_sk = bc.customer_sk
