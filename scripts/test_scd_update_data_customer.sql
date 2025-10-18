UPDATE dbt_dev.bronze.bronze_dim_customer
SET 
    loyalty_tier = CASE
        WHEN customer_sk IN (5, 20, 24, 33, 36, 39) THEN 'Silver'
        WHEN customer_sk IN (10, 12, 17, 19) THEN 'Gold'
        WHEN customer_sk IN (25, 31, 37) THEN 'Platinum'
        ELSE loyalty_tier
    END,
    updated_at = CURRENT_TIMESTAMP()

WHERE 
    customer_sk IN (
    5, 10, 12, 17, 19, 20, 24, 25, 31, 33, 36, 37, 39
);
