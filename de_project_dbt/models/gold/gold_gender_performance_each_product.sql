SELECT 
    product_sk,
    CASE
      WHEN gender = 'F' THEN 'Female'
      WHEN gender = 'M' THEN 'Male'
      ELSE 'Unspecified'
    END AS gender,
    ROUND(SUM(total_sales), 2)      AS total_spent, 
    ROUND(SUM(discount_amount), 2)  AS total_discount
 

FROM 
    {{ ref('silver_sales_info') }}

GROUP BY 
    product_sk,
    gender

ORDER BY 
    total_discount DESC;