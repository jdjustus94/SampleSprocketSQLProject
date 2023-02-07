--The Top 10 Spenders
WITH A AS (
SELECT cd.customer_id, CONCAT(first_name, ' ' , last_name) AS full_name,  
EXTRACT(YEAR FROM AGE(CAST(NOW() AS DATE), date_of_birth)) AS age, wealth_segment
FROM customerdemographic AS cd)

SELECT full_name, age, wealth_segment, COUNT(transaction_id) AS transactions, SUM(list_price) AS money_spent, 
(SUM(list_price)-SUM(standard_cost)) AS business_profit
FROM A
LEFT JOIN transactions AS t
ON a.customer_id = t.customer_id
WHERE order_status = 'approved'
GROUP BY full_name, age, wealth_segment
HAVING (SUM(list_price)-SUM(standard_cost)) > 10000
ORDER BY business_profit DESC
LIMIT 10;

--Total Sales By Product
WITH A AS
(SELECT brand, product_line, product_class, order_status,
SUM(SUM(list_price)) OVER(PARTITION BY brand, product_line, product_class ORDER BY brand) AS product_sales
FROM transactions
GROUP BY 1,2,3,4)

SELECT brand, product_line, product_class, CONCAT('$', ROUND(((product_sales)/1000000),2), ' million') AS product_sales
FROM A
WHERE order_status = 'approved'
ORDER BY brand DESC;

--Sales Per Australian States and Car Ownership
WITH A AS (
SELECT cd.customer_id, CONCAT(first_name, ' ' , last_name) AS full_name,  
EXTRACT(YEAR FROM AGE(CAST(NOW() AS DATE), date_of_birth)) AS age, wealth_segment
FROM customerdemographic AS cd)
	
SELECT COUNT(DISTINCT full_name) AS customers_per_state, state, owns_car, CONCAT('$', ROUND(SUM(list_price)/1000000,2), ' million') AS sales
FROM A
LEFT JOIN customeraddress AS ca
	ON a.customer_id = ca.customer_id
LEFT JOIN customerdemographic AS cd
	ON ca.customer_id = cd.customer_id
LEFT JOIN transactions AS t
	ON cd.customer_id = t.customer_id
WHERE order_status = 'approved'
GROUP BY state, owns_car
ORDER BY sales DESC;

--Sales and Profit per Wealth_Segment
SELECT wealth_segment, CONCAT('$', ROUND((SUM(list_price)/1000000),2), ' million') AS sales, 
CONCAT('$', ROUND(((SUM(list_price -standard_cost))/1000000),2), ' million') AS profit
FROM customerdemographic AS cd
LEFT JOIN transactions AS t
ON cd.customer_id = t.customer_id
WHERE order_status = 'approved'
GROUP BY wealth_segment
ORDER BY profit DESC;

--Sales and Profit For Online Orders
SELECT online_order, CONCAT('$', ROUND((SUM(list_price)/1000000),2), ' million') AS sales, 
CONCAT('$', ROUND(((SUM(list_price -standard_cost))/1000000),2), ' million') AS profit
FROM transactions
GROUP BY online_order;

--Sales Percentage Per Job Industry
SELECT job_industry_category, sum(list_price) as Sales, 
(ROUND((sum(list_price) * 100.0 / (SELECT sum(list_price) from transactions)),2)) AS sales_percent
FROM customerdemographic AS cd
LEFT JOIN transactions as t
ON cd.customer_id = t.customer_id
GROUP BY 1;

--Sales Per Quarter with %
WITH A AS
(SELECT DISTINCT EXTRACT(quarter FROM transaction_date) AS quarter, SUM(list_price) AS sales
FROM transactions
GROUP BY quarter
ORDER BY quarter)

SELECT quarter, CONCAT('$',ROUND((sales/1000000),2),' million') AS quarter_sales, 
ROUND(sales * 100.0/(SELECT SUM(list_price) FROM transactions),2) AS quarter_sales_perc
FROM A;

--Brand Sales per Quarter w/Percentage
WITH A AS
(SELECT DISTINCT EXTRACT(quarter FROM transaction_date) AS quarter, brand,  SUM(list_price) AS sales
FROM transactions
GROUP BY quarter, brand
ORDER BY quarter)

SELECT brand, quarter, CONCAT('$',ROUND((sales/1000000),2),' million') AS quarter_sales, 
ROUND(sales * 100.0/(SELECT SUM(list_price) FROM transactions),2) AS quarter_sales_perc
FROM A
GROUP BY brand, quarter, sales
ORDER BY brand DESC;

--Gendered Sales
SELECT gender, CONCAT('$', ROUND((SUM(list_price)/1000000),2),' million') AS sales, 
ROUND(SUM(list_price)*100/(SELECT SUM(list_price) FROM transactions),2) AS sales_per_gender
FROM customerdemographic AS cd
LEFT JOIN transactions AS t
ON cd.customer_id = t.customer_id
GROUP BY gender;