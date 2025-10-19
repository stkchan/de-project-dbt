SELECT 
    payment_method,
    ROUND(SUM(total_sales),2) AS total_spent, 
    COUNT(*) AS purchase_count 

FROM 
    {{ ref('silver_sales_info') }}

GROUP BY 
    payment_method

ORDER BY 
    purchase_count DESC;