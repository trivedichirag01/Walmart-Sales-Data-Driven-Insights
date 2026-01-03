CREATE DATABASE walmart_db;
use walmart_db;

SELECT * FROM billing_info;

-- Making invoice_id a primary key
ALTER TABLE billing_info ADD CONSTRAINT pk_invoice PRIMARY KEY (invoice_id);


-- total number of branches
SELECT COUNT(DISTINCT branch) from billing_info;


-- Business problems
-- 1. Find the number of quantities sold as per the catogory
SELECT category, SUM(quantity) AS quantity_sold FROM billing_info GROUP BY category ORDER BY quantity_sold DESC;


-- 2. Find the number of transactions and total sales via different payment methods
SELECT payment_method, count(*) AS trans_vol, round(SUM(total), 2) as total_amount FROM billing_info GROUP BY payment_method ORDER BY total_amount DESC;


-- 3. Calculate total sales based on category
SELECT category, round(SUM(total),2) AS total_sales FROM billing_info GROUP BY category ORDER BY total_sales DESC; 


-- 4. Identify the Highest-Rated(avg) Category in Each Branch
SELECT * FROM
(SELECT branch,city, category, round(avg(rating),2) AS avg_rating,
RANK() OVER(PARTITION BY branch ORDER BY AVG(rating) DESC) AS ranks
FROM billing_info 
GROUP BY branch, city,category) t
WHERE ranks = 1;


-- 5. What is the busiest day of the week for each branch based on transaction volume?
-- modifying the date format according to mysql protocol
UPDATE billing_info
SET `date` = STR_TO_DATE(`date`, '%d/%m/%y');
ALTER TABLE billing_info MODIFY `date` DATE;


SELECT * FROM
(
SELECT branch, dayname(`date`) as `day`, COUNT(*) AS no_of_transactions,
DENSE_RANK() OVER(PARTITION BY branch ORDER BY count(*) DESC) AS `rank`
FROM billing_info
GROUP BY branch, `day`
) t 
WHERE `rank` = 1;


-- 6. How many items were sold through each payment method?
 SELECT payment_method, SUM(quantity) AS total_quantity_sold FROM billing_info GROUP BY payment_method;


-- 7. What are the average, minimum, and maximum ratings for each category in each city?
SELECT city, 
category, round(AVG(rating),2) AS avg_rating, 
MIN(rating) AS min_rating, 
MAX(rating) AS max_rating 
FROM billing_info
GROUP BY city, category;


-- 8. What is the total profit for each category, ranked from highest to lowest?
SELECT category, 
round(sum(total * profit_margin),2) AS profit, 
DENSE_RANK() OVER(ORDER BY sum(total * profit_margin) DESC) AS `rank`
FROM billing_info 
GROUP BY category;


-- 9. What is the most frequently used payment method in each branch?
SELECT * FROM (
	SELECT branch, 
	payment_method, 
	COUNT(*) AS frequency_of_use,
	DENSE_RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS `rank`
	FROM billing_info 
	GROUP BY branch, payment_method
) t WHERE `rank` = 1;


-- 10. How many transactions occur in each shift (Morning, Afternoon, Evening) across branches?
--  modifying the time format according to mysql protocol
DESCRIBE billing_info;
UPDATE billing_info
SET `time` = str_to_date(`time`, '%H:%i:%s');

ALTER TABLE billing_info MODIFY `time` TIME;

SELECT branch, 
CASE
	WHEN hour(`time`) < 12 THEN 'Morning'
    WHEN hour(`time`) BETWEEN 12 AND 17 THEN 'Afternoon'
    ELSE 'Evening'
    END AS shift,
COUNT(*) AS no_of_transactions
FROM billing_info
GROUP BY branch, shift
ORDER BY branch, no_of_transactions DESC;


-- 11. Top 5 branches which experienced the largest decrease in revenue 
--     compared to the previous year (current yr 2023, previous yr 2022)? 
WITH revenue_2022 
AS (
	SELECT branch, 
	SUM(total) AS revenue
	FROM billing_info
	WHERE year(`date`) = 2022
	GROUP BY branch
),
revenue_2023 
AS (
	SELECT branch, 
	SUM(total) AS revenue
	FROM billing_info
	WHERE year(`date`) = 2023
	GROUP BY branch
)
SELECT 
rv2022.branch,
rv2022.revenue AS last_year_rev,
rv2023.revenue AS current_year_rev,
round(((rv2023.revenue - rv2022.revenue)/rv2022.revenue)*100, 2) AS 'growth(%)'
FROM revenue_2022 AS rv2022 
JOIN revenue_2023 AS rv2023 
ON rv2022.branch = rv2023.branch
WHERE rv2022.revenue > rv2023.revenue
ORDER BY `growth(%)` ASC
LIMIT 5;




