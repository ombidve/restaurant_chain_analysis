SQL Project:

-- Find Top 1 outlets by cuisine type without using limit and top
WITH cte AS (
SELECT `Cuisine`, `Restaurant_id`, count(*) AS no_of_orders
FROM orders
GROUP BY `Cuisine`, `Restaurant_id`) 
SELECT * FROM	(
SELECT *, row_number() OVER (PARTITION BY cuisine ORDER BY no_of_orders DESC) AS RN
FROM cte) a
WHERE RN = 1


-- Find daily new customers count from launch date
WITH cte AS(
SELECT `Customer_code`, cast(MIN(`Placed_at`)AS DATE) AS first_order_date
FROM orders
GROUP BY `Customer_code`
)
SELECT first_order_date, count(*) AS no_of_new_order 
FROM cte
GROUP BY first_order_date
ORDER BY first_order_date


-- Count all users aquired in Jan 2025 AND placed less than 3 orders in Jan, and then did not place order at all
WITH cte AS(
SELECT `Customer_code`, count(*)AS no_of_orders
FROM orders
WHERE MONTH(`Placed_at`)=1 AND YEAR(`Placed_at`)=2025 
AND `Customer_code` NOT IN (SELECT DISTINCT(`Customer_code`)
FROM orders
WHERE NOT MONTH(`Placed_at`)=1 AND YEAR(`Placed_at`)=2025)
GROUP BY `Customer_code`)
SELECT `Customer_code`, no_of_orders
FROM cte
WHERE no_of_orders< 4


-- List all customers with NO order in last 7 days but were aquired one month ago with their 1st order on promo code

WITH cte AS (
SELECT `Customer_code`, min(`Placed_at`) AS first_order_date, max(`Placed_at`) AS last_order_date
FROM orders
GROUP BY `Customer_code`
)
SELECT cte.*, orders.`Promo_code_Name`
FROM cte
INNER JOIN orders ON cte.`Customer_code` = orders.`Customer_code` AND cte.first_order_date = orders.`Placed_at`
WHERE last_order_date < DATEADD(DAY, -7, GETDATE())
  AND first_order_date < DATEADD(MONTH, -1, GETDATE())
AND orders.`Promo_code_Name` IS NOT NULL


-- Create a trigger for every 3rd order
WITH CTE AS (
SELECT *,row_number() over(PARTITION BY `Customer_code` ORDER BY `Placed_at`) AS order_no
FROM orders
)
SELECT * 
FROM CTE
WHERE order_no %3=0 AND cast(`Placed_at` AS DATE)=cast(GETDATE() AS DATE)


-- List customers who placed more than one order and all their orders had promo code
WITH cte AS (
SELECT `Customer_code`, count(*) AS no_of_orders, count(`Promo_code_Name`) AS promo_orders
FROM orders
WHERE `Promo_code_Name` IS NOT NULL 
GROUP BY `Customer_code`)
SELECT *
FROM cte
HAVING no_of_orders > 1


-- List customers who were aquired in Jan 2025 organically (custoomers aquired without any promo code)
WITH q1 AS(
WITH cte AS (
SELECT `Customer_code`, MIN(`Placed_at`) AS first_order
FROM orders
WHERE MONTH(`Placed_at`)=1 AND `Promo_code_Name`IS NULL
GROUP BY `Customer_code`
)
SELECT count(`Customer_code`) AS ans1
FROM cte
),
WITH q2 AS(
SELECT count(`Customer_code`) AS ans2 
FROM orders
WHERE MONTH(`Placed_at`)=1
)
SELECT (q1.ans1/q2.ans2)*100 AS ratio
FROM q1,q2;
