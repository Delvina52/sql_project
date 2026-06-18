---Bikes is dominating. Accessories and Clothing are clearly underperforming. Now let's find out why.

---Reason 1 — Are fewer products being sold? (Volume problem)
   SELECT
    p.category,
    COUNT(DISTINCT f.order_number) AS total_orders,
    SUM(f.quantity) AS total_quantity_sold
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_quantity_sold DESC

--Reason 2 — Is the price too low? (Pricing problem)
 SELECT
    p.category,
    AVG(p.cost) AS avg_cost,
    AVG(f.sales_amount) AS avg_sales_per_order
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY avg_sales_per_order DESC

---Reason 3 — How many products exist per category? (Product variety problem)

SELECT
    category,
    COUNT(DISTINCT product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC

---Accessories subcategories!

SELECT
    p.subcategory,
    SUM(f.sales_amount) AS total_sales,
    COUNT(DISTINCT f.order_number) AS total_orders,
    SUM(f.quantity) AS total_quantity_sold,
    AVG(f.sales_amount) AS avg_sales_per_order
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
WHERE p.category = 'Accessories'
GROUP BY p.subcategory
ORDER BY total_sales DESC

---compare this against Clothing subcategories too
SELECT
    p.subcategory,
    SUM(f.sales_amount) AS total_sales,
    COUNT(DISTINCT f.order_number) AS total_orders,
    SUM(f.quantity) AS total_quantity_sold,
    AVG(f.sales_amount) AS avg_sales_per_order
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
WHERE p.category = 'Clothing'
GROUP BY p.subcategory
ORDER BY total_sales DESC

---To get exact revenue per order
SELECT
    p.subcategory,
    SUM(f.sales_amount) AS total_sales,
    COUNT(DISTINCT f.order_number) AS total_orders,
    SUM(f.sales_amount) / COUNT(DISTINCT f.order_number) AS revenue_per_order
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
WHERE p.subcategory = 'Tires and Tubes'
GROUP BY p.subcategory


SELECT
    p.subcategory,
    AVG(p.cost) AS avg_cost_per_product,
    MIN(p.cost) AS min_cost,
    MAX(p.cost) AS max_cost
FROM gold.dim_products p
WHERE p.subcategory = 'Tires and Tubes'
GROUP BY p.subcategory

SELECT
    p.subcategory,
    SUM(p.cost * f.quantity) AS total_cost,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.sales_amount) - SUM(p.cost * f.quantity) AS total_profit
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
WHERE p.subcategory = 'Tires and Tubes'
GROUP BY p.subcategory