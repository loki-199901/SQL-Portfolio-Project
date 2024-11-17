use project_1; -- the database

SELECT * FROM customers;
SELECT * FROM inventory_movements;
SELECT * FROM sales;
SELECT * FROM products;
SET SQL_SAFE_UPDATES = 0;

/*1. Total Sales per Month:
○ Calculate the total sales amount per month, including the number of units sold
and the total revenue generated.
*/

ALTER TABLE sales
ADD COLUMN months INT;
UPDATE sales SET months = MONTH(sale_date);
-- -- --
Select count(sale_id) as number_of_orders, months, 
round(sum(total_amount),1) as revenue_per_month, 
sum(quantity_sold) as quantity_sold_per_month 
from sales
group by months 
ORDER by months ASC;

/*2. Average Discount per Month:
○ Calculate the average discount applied to sales in each month and assess how
discounting strategies impact total sales.
*/
SELECT months, 
ROUND(SUM(total_amount),1) AS revenue,
avg(discount_applied) as avg_discount 
FROM sales
group by months
order by revenue DESC;
/*
3. Identify high-value customers:
○ Which customers have spent the most on their purchases? Show their details
*/

SELECT c.customer_id ,round(sum(s.total_amount),1) as customer_spent
FROM customers as c
JOIN sales as s
on c.customer_id = s.customer_id
group by c.customer_id
order by 2 DESC;

/*
4. Identify the oldest Customer:
○ Find the details of customers born in the 1990s, including their total spending and
specific order details.
*/

SELECT s.sale_id,
c.customer_id, p.product_name, s.total_amount, quantity_sold as quantity_bought
FROM 
customers as c
JOIN 
sales as s ON c.customer_id = s.customer_id
JOIN
products as p ON s.product_id = p.product_id
WHERE c.date_of_birth BETWEEN '1990-01-01' AND '1999-12-31'
GROUP BY s.sale_id, c.customer_id, p.product_name, s.total_amount, quantity_bought
ORDER BY c.customer_id;

/*
5. Customer Segmentation:
○ Use SQL to create customer segments based on their total spending (e.g., Low
Spenders, High Spenders).
*/

SELECT c.customer_id,
round(SUM(s.total_amount),1) as lifetime_value,
	CASE  
     WHEN SUM(s.total_amount) < 500 THEN 'Low Spender'
     WHEN SUM(s.total_amount) BETWEEN 500 AND 3000 THEN 'Medium Spender'
     WHEN SUM(s.total_amount) > 3000 THEN 'High Spender'
		END AS spending_category
FROM
customers AS c
JOIN
sales AS s 
ON c.customer_id = s.customer_id
GROUP BY c.customer_id
order by lifetime_value DESC;

/*
6. Stock Management:
○ Write a query to find products that are running low in stock (below a threshold like
10 units) and recommend restocking amounts based on past sales performance.
*/

WITH recent_sales AS (
SELECT product_id,
AVG(quantity_sold) AS avg_daily_sales
FROM sales
WHERE sale_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY product_id
)
SELECT 
p.product_id,
p.stock_quantity,
avg_daily_sales * 30 AS restock_quantity
FROM products p
JOIN recent_sales r ON p.product_id = r.product_id
WHERE p.stock_quantity < 10;


/*7. Inventory Movements Overview:
○ Create a report showing the daily inventory movements (restock vs. sales) for
each product over a given period.
*/
SELECT 
p.product_id,
i.movement_date,
SUM(CASE WHEN i.movement_type = 'IN' THEN i.quantity_moved ELSE 0 END) AS total_restock,
SUM(CASE WHEN i.movement_type = 'OUT' THEN i.quantity_moved ELSE 0 END) AS total_sales
FROM 
Products p
JOIN 
Inventory_Movements i 
ON p.product_id = i.product_id
WHERE i.movement_date BETWEEN '2024-01-01' AND '2024-09-31' 
GROUP BY p.product_id, i.movement_date
ORDER BY  p.product_id,i.movement_date ASC; 


/*8. Rank Products::
○ Rank products in each category by their prices.
*/
SELECT * FROM products;
SELECT 
category,product_id,
product_name,price,
ROW_NUMBER() OVER(PARTITION BY category ORDER BY price DESC) AS price_rank
FROM products
ORDER BY category, price_rank;


/*
9. Average order size:
○ What is the average order size in terms of quantity sold for each product?
*/

SELECT
product_id,
round(avg(quantity_sold),1) as average_order_size
FROM sales
GROUP BY product_id
ORDER BY product_id ASC;

/*
10. Recent Restock Product:
○ Which products have seen the most recent restocks
*/
SELECT 
product_id, MAX(movement_date) AS last_restock_date
FROM inventory_movements
GROUP BY product_id
ORDER BY last_restock_date DESC;




/*
Customer Purchase Patterns: Analyze purchase patterns using time-series data and
window functions to find high-frequency buying behavior.
*/
SELECT 
customer_id, sale_id, sale_date,
LAG(sale_date) OVER (PARTITION BY customer_id ORDER BY sale_date) AS previous_order_date,
TIMESTAMPDIFF(DAY, LAG(sale_date) OVER (PARTITION BY customer_id ORDER BY sale_date), sale_date) AS days_since_last_order,
count(sale_id) OVER (PARTITION BY customer_id) AS total_orders
FROM 
Sales
ORDER BY  customer_id, sale_date, total_orders DESC;

/*
● Predictive Analytics: Use past data to predict which customers are most likely to churn
and recommend strategies to retain them.
*/

SELECT customer_id,
MAX(sale_date) AS last_order_date,
TIMESTAMPDIFF(MONTH, MAX(sale_date), CURDATE()) AS months_since_last_order
FROM sales
GROUP BY customer_id
HAVING months_since_last_order >= 6
order by customer_id;

/*
Dynamic Pricing Simulation: Challenge students to analyze how price changes for
products impact sales volume, revenue, and customer behavior.
*/

SELECT p.product_id, p.product_name, round(AVG(s.price_per_product),1) AS avg_price_last_12_months,
round(SUM(s.quantity_sold),1) AS total_quantity_sold
FROM products p
JOIN sales s ON p.product_id = s.product_id
WHERE s.sale_date BETWEEN CURDATE() - INTERVAL 12 MONTH AND CURDATE()
GROUP BY p.product_id, p.product_name;

SELECT p.product_name, round(SUM(s.price_per_product),1) AS total_revenue_last_12_months
FROM products p
JOIN sales s ON p.product_id = s.product_id
WHERE s.sale_date BETWEEN CURDATE() - INTERVAL 12 MONTH AND CURDATE()
GROUP BY p.product_name;

SELECT * FROM customers;

SELECT c.customer_id, p.product_name, round(SUM(s.quantity_sold),1) AS quantity_purchased
FROM customers c
JOIN sales s ON c.customer_id = s.customer_id
JOIN products p ON s.product_id = p.product_id
WHERE s.sale_date BETWEEN CURDATE() - INTERVAL 12 MONTH AND CURDATE()
GROUP BY c.customer_id, p.product_name;

SELECT * FROM sales;
SELECT c.customer_id, COUNT(DISTINCT p.product_id) AS products_purchased, 
round(AVG(s.total_amount),1) AS avg_revenue_per_customer
FROM customers c
JOIN sales s ON c.customer_id = s.customer_id
JOIN products p ON s.product_id = p.product_id
WHERE s.sale_date BETWEEN CURDATE() - INTERVAL 12 MONTH AND CURDATE()
GROUP BY c.customer_id;

