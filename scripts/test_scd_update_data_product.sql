UPDATE dbt_dev.bronze.bronze_dim_product
SET 
    category = CASE
        WHEN product_sk = 7 THEN 'Toys'
        WHEN product_sk = 5 THEN 'Television'
        ELSE category
    END,
    updated_at = CURRENT_TIMESTAMP()

WHERE product_sk IN (5, 7);
