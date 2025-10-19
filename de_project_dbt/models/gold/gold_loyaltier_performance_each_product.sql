SELECT 
    product_sk, 
    CASE
        WHEN loyalty_tier = 'None' THEN 'Standard'
        ELSE loyalty_tier
    END AS loyalty_tier, 
    ROUND(SUM(total_sales),2) AS total_spent, 
    ROUND(AVG(total_sales),2) AS avg_transaction_value, 
    COUNT(*) AS purchase_count 

FROM 
    {{ ref('silver_sales_info') }}

GROUP BY 
    product_sk, 
    loyalty_tier

ORDER BY 
    total_spent DESC;