CREATE TABLE dbt_production.source.dim_customer
AS
SELECT * FROM dbt_dev.source.dim_customer;



CREATE TABLE dbt_production.source.dim_date
AS
SELECT * FROM dbt_dev.source.dim_date;



CREATE TABLE dbt_production.source.dim_product
AS
SELECT * FROM dbt_dev.source.dim_product;



CREATE TABLE dbt_production.source.dim_store
AS
SELECT * FROM dbt_dev.source.dim_store;



CREATE TABLE dbt_production.source.fact_returns
AS
SELECT * FROM dbt_dev.source.fact_returns;



CREATE TABLE dbt_production.source.fact_sales
AS
SELECT * FROM dbt_dev.source.fact_sales;