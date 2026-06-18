/*Customer Report

Purpose:

This report consolidates key customer metrics and behaviors.

Highlights:

1 Gather essential customer information such as:
Customer name
Age
Transaction details

2 Segment customers into categories:VIP,Regular,New
Also classify customers into age groups.

3 Calculate the following customer-level metrics:
Total orders
Total sales
Total quantity purchased
Total products purchased
Lifespan (in months)

4 Calculate the following KPIs:
Recently (months since last order)
Average order value
Average monthly spend */

create view gold.report_customers1 as
WITH base_query AS (

/* 1 Base query retrieve core columns from table */

    SELECT
        f.order_number,
        f.product_key,
        f.sales_amount,
        f.quantity,
        f.order_date,
        c.customer_key,
        c.customer_number,
        c.birthdate,
        CONCAT(c.first_name,' ',c.last_name) AS customer_name,
        DATEDIFF(YEAR,c.birthdate,GETDATE()) AS age

FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key

WHERE order_date IS NOT NULL
),

customer_aggregation AS (

    /* 2 Calculate customer-level metrics */

    SELECT
        customer_key,
        customer_number,
        customer_name,
        age,

        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT product_key) AS total_products,

        MAX(order_date) AS last_order_date,

        DATEDIFF(
            MONTH,
            MIN(order_date),
            MAX(order_date)
        ) AS lifespan

    FROM base_query

    GROUP BY
        customer_key,
        customer_number,
        customer_name,
        age
)

SELECT

    customer_key,
    customer_number,
    customer_name,
    age,

    /* Age Group */
    CASE
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 and above'
    END AS age_group,

    /* Customer Segment */
    CASE
        WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
        WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
        ELSE 'New'
    END AS customer_segment,

    last_order_date,

    /* Recency */
    DATEDIFF(
        MONTH,
        last_order_date,
        GETDATE()
    ) AS recency,

    total_orders,
    total_sales,
    total_quantity,
    total_products,
    lifespan,

    /* Average Order Value (AOV) */
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END AS avg_order_value,

    /* Average Monthly Spend */
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
    END AS avg_monthly_spend

FROM customer_aggregation;



select *
from gold.report_customers1