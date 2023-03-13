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

--job_industry_category customer expenditure based on job category
SELECT DISTINCT job_industry_category,
CASE WHEN job_industry_category = 'Agriculture' THEN 
(SELECT SUM(list_price) FROM transactions AS t LEFT JOIN customerdemographic AS cd ON t.customer_id =cd.customer_id WHERE job_industry_category = 'Agriculture')
WHEN job_industry_category = 'Retail' THEN (SELECT SUM(list_price) FROM transactions AS t LEFT JOIN customerdemographic AS cd ON t.customer_id =cd.customer_id WHERE job_industry_category = 'Retail')
WHEN job_industry_category = 'Manufacturing' THEN (SELECT SUM(list_price) FROM transactions AS t LEFT JOIN customerdemographic AS cd ON t.customer_id =cd.customer_id WHERE job_industry_category = 'Manufacturing')
WHEN job_industry_category = 'n/a' THEN (SELECT SUM(list_price) FROM transactions AS t LEFT JOIN customerdemographic AS cd ON t.customer_id =cd.customer_id WHERE job_industry_category = 'n/a')
WHEN job_industry_category = 'Property' THEN (SELECT SUM(list_price) FROM transactions AS t LEFT JOIN customerdemographic AS cd ON t.customer_id =cd.customer_id WHERE job_industry_category = 'Property')
WHEN job_industry_category = 'Entertainment' THEN (SELECT SUM(list_price) FROM transactions AS t LEFT JOIN customerdemographic AS cd ON t.customer_id =cd.customer_id WHERE job_industry_category = 'Entertainment')
WHEN job_industry_category = 'IT' THEN (SELECT SUM(list_price) FROM transactions AS t LEFT JOIN customerdemographic AS cd ON t.customer_id =cd.customer_id WHERE job_industry_category = 'IT')
WHEN job_industry_category = 'Financial Services' THEN (SELECT SUM(list_price) FROM transactions AS t LEFT JOIN customerdemographic AS cd ON t.customer_id =cd.customer_id WHERE job_industry_category = 'Financial Services')
WHEN job_industry_category = 'Telecommunications' THEN (SELECT SUM(list_price) FROM transactions AS t LEFT JOIN customerdemographic AS cd ON t.customer_id =cd.customer_id WHERE job_industry_category = 'Telecommunications')
WHEN job_industry_category = 'Health' THEN (SELECT SUM(list_price) FROM transactions AS t LEFT JOIN customerdemographic AS cd ON t.customer_id =cd.customer_id WHERE job_industry_category = 'Health') END AS job_industry_sum
FROM customerdemographic;

--Profit on brands seperated by distinct product_id for each brand
SELECT DISTINCT brand, product_id, SUM(list_price - standard_cost) OVER(PARTITION BY brand,product_id) AS profit
FROM transactions
GROUP BY brand, product_id, list_price, standard_cost
ORDER BY brand

--Count and Percentage of Online Orders
SELECT online_order, COUNT(*), ROUND((COUNT(*) *100.0 / (SUM(COUNT(*)) OVER())),2)
FROM transactions
GROUP BY 1

--Customer Categories of job industry and wealth segment with sales in millions
WITH A AS
(SELECT job_industry_category AS customer_category, ROUND(((COUNT(*)*100.0/SUM(COUNT(*)) OVER())),2) AS percent_of_business, SUM(list_price) AS sales
FROM customerdemographic AS cd
LEFT JOIN transactions AS t
ON cd.customer_id = t.customer_id
GROUP BY 1),

B AS
(SELECT wealth_segment, ROUND((((COUNT(*) *100.0/SUM(COUNT(*)) OVER()))),2) AS wealth_seg_perc, SUM(list_price) AS wealth_seg_sales
FROM customerdemographic AS cd
LEFT JOIN transactions AS t
ON cd.customer_id = t.customer_id
GROUP BY 1)

SELECT customer_category, percent_of_business, ROUND((sales/1000000),2) AS sales_millions
FROM A
UNION ALL
SELECT wealth_segment, wealth_seg_perc, ROUND((wealth_seg_sales/1000000),2) AS sales_millions
FROM B;

--Customer's full name, gender, age at purchase, and total money spent with Sprocket Central
SELECT DISTINCT CONCAT(first_name, ' ', last_name) AS full_name, gender, EXTRACT(year FROM AGE(transaction_date, date_of_birth)) AS age_at_purchase, SUM(list_price) OVER(PARTITION BY CONCAT(first_name, ' ', last_name)) AS money_spent
FROM customerdemographic AS cd
LEFT JOIN transactions AS t
ON cd.customer_id = t.customer_id
GROUP BY 1, transaction_date, date_of_birth, list_price, gender
HAVING EXTRACT(year FROM AGE(transaction_date, date_of_birth)) IS NOT NULL
ORDER BY money_spent DESC, full_name;

--Top earning products where the order was not cancelled
SELECT DISTINCT brand, product_line, product_class, product_size, 
ROUND((SUM(list_price) OVER(PARTITION BY brand, product_line, product_class, product_size)/1000000),2) AS sales_million,
ROUND((SUM(list_price-standard_cost) OVER(PARTITION BY brand, product_line, product_class,product_size)/1000000),2) AS profit_million, 
COUNT(brand) OVER(PARTITION BY brand, product_line, product_class, product_size) AS number_sold
FROM transactions
WHERE brand IS NOT NULL AND order_status != 'cancelled'
ORDER BY profit_million desc, brand, product_line, product_class, product_size
LIMIT 10;

--Percentage of sales per wealth segment, per Austrailian state, with sales per wealth segment in millions
SELECT DISTINCT wealth_segment, state, ROUND((((COUNT(*) *100.0 / SUM(COUNT(*)) OVER(PARTITION BY state)))),2), ROUND((SUM(list_price)::numeric/1000000),2) AS sales_millions
FROM customerdemographic AS cd
LEFT JOIN customeraddress AS ca
ON cd.customer_id = ca.customer_id
LEFT JOIN transactions AS t
ON ca.customer_id = t.customer_id
GROUP BY 1,2
ORDER BY state;

--Total sales by month and average sale price per month, month names added
SELECT DISTINCT CASE WHEN EXTRACT(month FROM transaction_date) = '1' THEN 'January'
WHEN EXTRACT(month FROM transaction_date) = '2' THEN 'February'
WHEN EXTRACT(month FROM transaction_date) = '3' THEN 'March'
WHEN EXTRACT(month FROM transaction_date) = '4' THEN 'April'
WHEN EXTRACT(month FROM transaction_date) = '5' THEN 'May'
WHEN EXTRACT(month FROM transaction_date) = '6' THEN 'June'
WHEN EXTRACT(month FROM transaction_date) = '7' THEN 'July'
WHEN EXTRACT(month FROM transaction_date) = '8' THEN 'August'
WHEN EXTRACT(month FROM transaction_date) = '9' THEN 'September'
WHEN EXTRACT(month FROM transaction_date) = '10' THEN 'October'
WHEN EXTRACT(month FROM transaction_date) = '11' THEN 'November'
WHEN EXTRACT(month FROM transaction_date) = '12' THEN 'December' END AS months, ROUND((SUM(list_price)*1.0/1000000),2) AS total_sales_millions,
ROUND(AVG(list_price),2) AS avg_sale_price
FROM transactions
GROUP BY 1
ORDER BY total_sales_millions DESC;

--Customer's full name, count of transactions, total money spent, and average purchase expenditure
WITH A AS
(SELECT customer_id, COUNT(*) AS transaction_count
 FROM transactions
 GROUP BY 1)
 SELECT CONCAT(first_name, ' ', last_name) AS full_name, transaction_count, SUM(list_price) AS money_spent, ROUND(AVG(list_price),2) AS avg_purchase
 FROM A
 LEFT JOIN transactions AS t
 ON A.customer_id = t.customer_id
 LEFT JOIN customerdemographic AS cd
 ON t.customer_id = cd.customer_id
 GROUP BY first_name, last_name, transaction_count
 ORDER BY money_spent DESC
 
 --Number of transactions divided between gender and age group
 SELECT gender, 
SUM(CASE WHEN EXTRACT(year from AGE(transaction_date, date_of_birth)) >=10 AND EXTRACT(year from AGE(transaction_date, date_of_birth)) <20 THEN 1 END) AS teens,
SUM(CASE WHEN EXTRACT(year from AGE(transaction_date, date_of_birth)) >=20 AND EXTRACT(year FROM AGE(transaction_date, date_of_birth)) <30 THEN 1 END) AS twenties,
SUM(CASE WHEN EXTRACT(year from AGE(transaction_date, date_of_birth)) >=30 AND EXTRACT(year FROM AGE(transaction_date, date_of_birth)) <40 THEN 1 END) AS thirties,
SUM(CASE WHEN EXTRACT(year from AGE(transaction_date, date_of_birth)) >=40 AND EXTRACT(year FROM AGE(transaction_date, date_of_birth)) <50 THEN 1 END) AS forties,
SUM(CASE WHEN EXTRACT(year from AGE(transaction_date, date_of_birth)) >=50 AND EXTRACT(year FROM AGE(transaction_date, date_of_birth)) <60 THEN 1 END) AS fifties,
SUM(CASE WHEN EXTRACT(year from AGE(transaction_date, date_of_birth)) >=60 AND EXTRACT(year FROM AGE(transaction_date, date_of_birth)) <70 THEN 1 END) AS sixties,
SUM(CASE WHEN EXTRACT(year from AGE(transaction_date, date_of_birth)) >=70 AND EXTRACT(year FROM AGE(transaction_date, date_of_birth)) <80 THEN 1 END) AS seventies,
SUM(CASE WHEN EXTRACT(year from AGE(transaction_date, date_of_birth)) >=80 AND EXTRACT(year FROM AGE(transaction_date, date_of_birth)) <90 THEN 1 END) AS eighties
FROM transactions AS t
LEFT JOIN customerdemographic AS cd
ON t.customer_id=cd.customer_id
WHERE gender IS NOT NULL AND gender != 'U'
GROUP BY 1

--Customer sum of money spent per gender, wealth segment, and age group
SELECT DISTINCT gender, wealth_segment, 
CASE WHEN EXTRACT(year FROM AGE(transaction_date, date_of_birth)) >=10 AND EXTRACT(YEAR FROM AGE(transaction_date,date_of_birth)) <20 THEN '10s'
WHEN EXTRACT(YEAR FROM AGE(transaction_date, date_of_birth)) >=20 AND EXTRACT(YEAR FROM AGE(transaction_date, date_of_birth)) <30 THEN '20s'
WHEN EXTRACT(YEAR FROM AGE(transaction_date, date_of_birth)) >=30 AND EXTRACT(YEAR FROM AGE(transaction_date, date_of_birth)) <40 THEN '30s'
WHEN EXTRACT(YEAR FROM AGE(transaction_date, date_of_birth)) >=40 AND EXTRACT(YEAR FROM AGE(transaction_date, date_of_birth)) <50 THEN '40s'
WHEN EXTRACT(YEAR FROM AGE(transaction_date, date_of_birth)) >=50 AND EXTRACT(YEAR FROM AGE(transaction_date, date_of_birth)) <60 THEN '50s'
WHEN EXTRACT(YEAR FROM AGE(transaction_date, date_of_birth)) >=60 AND EXTRACT(YEAR FROM AGE(transaction_date, date_of_birth)) <70 THEN '60s'
WHEN EXTRACT(YEAR FROM AGE(transaction_date, date_of_birth)) >=70 AND EXTRACT(YEAR FROM AGE(transaction_date, date_of_birth)) <80 THEN '70s'
WHEN EXTRACT(YEAR FROM AGE(transaction_date, date_of_birth)) >=80 AND EXTRACT(YEAR FROM AGE(transaction_date, date_of_birth)) <90 THEN '80s'
WHEN EXTRACT(YEAR FROM AGE(transaction_date, date_of_birth)) >=90 AND EXTRACT(YEAR FROM AGE(transaction_date, date_of_birth)) <100 THEN '90s'
END AS age_segment,
SUM(list_price) AS age_group_money_spent
FROM customerdemographic AS cd
LEFT JOIN transactions AS t
ON cd.customer_id = t.customer_id
GROUP BY 1,2,3
ORDER BY gender, age_segment;

--Customers past purchases categoried between low and high on the values 1-100
SELECT CONCAT(first_name, ' ', last_name) AS full_name,
CASE WHEN past_3_years_bike_related_purchases >=1 AND past_3_years_bike_related_purchases <25 THEN 'low'
WHEN past_3_years_bike_related_purchases >=25 AND past_3_years_bike_related_purchases <50 THEN 'mid-low'
WHEN past_3_years_bike_related_purchases >=50 AND past_3_years_bike_related_purchases <75 THEN 'mid-high'
ELSE 'high' END AS past_purchasing_category, SUM(list_price)
FROM customerdemographic AS cd
LEFT JOIN transactions AS t
ON cd.customer_id=t.customer_id
GROUP BY first_name, last_name, past_3_years_bike_related_purchases
HAVING SUM(list_price) IS NOT NULL
ORDER BY sum DESC

--Profit Percentage on unique products
SELECT DISTINCT product_id, brand, product_line, product_class, product_size, list_price, standard_cost, ROUND(((profit/standard_cost)*100.0),2) AS profit_perc
FROM (SELECT DISTINCT product_id, brand, product_line, product_class, product_size, list_price, standard_cost, (list_price-standard_cost) AS profit
	 FROM transactions) AS A
WHERE brand IS NOT NULL AND product_line IS NOT NULL AND product_class IS NOT NULL AND product_size IS NOT NULL
ORDER BY brand, product_line;
