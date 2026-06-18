
select  
datetrunc(month,order_date) as order_date,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quantity) as total_quantity
from gold.fact_sales
where order_date is not null
group by datetrunc(month,order_date)
order by datetrunc(month,order_date)





select  
format(order_date,'yyyy-MMM') as order_date,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quantity) as total_quantity
from gold.fact_sales
where order_date is not null
group by format(order_date,'yyyy-MMM')
order by format(order_date,'yyyy-MMM')


--calculate the total sales per month 
--and the runnning total of sales over time

select 
order_date,
total_sales,
sum(total_sales) over (order by order_date) as running_total_sales,
avg(avg_price ) over (order by order_date) as moving_average_price
from
(
select 
datetrunc(year,order_date) as order_date,
sum(sales_amount) as total_sales,
avg(price) as avg_price
from gold.fact_sales
where order_date is not null
group by datetrunc(year,order_date)
) t


/*Analyze the yearly performance of products by camparing their sales to both
the average sale performance of the product and the previous year's sales */

with yearly_product_sales as (
select 
year(f.order_date) as order_year,
p.product_name,
sum(f.sales_amount) as current_sales
from gold.fact_sales f
left join gold.dim_products p
on f.product_key=p.product_key
where f.order_date is not null
group by 
year (f.order_date),
p.product_name
)

select 
order_year,
product_name,
current_sales,
avg(current_sales) over (partition by product_name) as avg_sales,
current_sales- avg(current_sales) over (partition by product_name) as diff_avg,
case when current_sales- avg(current_sales) over (partition by product_name) >0 then 'above avg'
     when current_sales- avg(current_sales) over (partition by product_name)  <0 then 'below avg'
     else 'avg'
end avg_change,
lag(current_sales) over (partition by product_name order by order_year) py_sales,
current_sales- lag(current_sales) over (partition by product_name order by order_year) as diff_py,
case when current_sales- lag(current_sales) over (partition by product_name order by order_year) >0 then 'increase'
     when current_sales- lag(current_sales) over (partition by product_name order by order_year)  <0 then 'decraese'
     else 'no change'
    end py_change
from yearly_product_sales
order by product_name,order_year;

---which categories contribute the most to overall sales?


with category_sales as(
SELECT
    category,
    sum(sales_amount) as total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
    group by category)

select 
category,
total_sales,
sum(total_sales) over () overall_sales,
concat(round((cast(total_sales as float)/ sum(total_sales) over ()) *100,2),'%') as percentage_of_total
from category_sales
order by total_sales desc

SELECT
   category,
   sales_amount
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key


/*segment products into cost ranges and count
how many products fall into each segment*/
with product_segment as (
select 
product_key,
product_name,
cost,
case when cost <100 then 'below 100'
     when cost between 100 and 500 then '100-500'
     when cost between 500 and 1000 then '500-1000'
else 'above 1000'
end cost_range
from [gold].[dim_products])

select 
cost_range,
count(product_key) as total_products
from product_segment
group by cost_range
order by total_products


/*Group customers into three segments based on their spending behavior:

VIP: Customers with at least 12 months of history and spending more than €5,000.
Regular: Customers with at least 12 months of history but spending €5,000 or less.
New: Customers with a lifespan less than 12 months.

Find the total number of customers in each group*/


with customer_spending as(
select 
c.customer_key,
sum(f.sales_amount) as total_spending,
min(order_date) as first_order,
max(order_date) as last_order,
Datediff(month,min(order_date),max(order_date))as lifespan

from gold.fact_sales f
left join gold.dim_customers c
on f.customer_key= c.customer_key
group by c.customer_key
)

select 
customer_segment,
count(customer_key) as total_customers
from(
    select
    customer_key,
case when lifespan > 12 and total_spending > 5000 then 'VIP'
      when lifespan > 12 and total_spending <= 5000 then 'Regular'
      else 'New'
end customer_segment
from customer_spending) t
group by customer_segment
order by total_customers desc

