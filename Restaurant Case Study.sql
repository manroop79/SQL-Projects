CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-07-03', '2'),
  ('A', '2021-05-01', '2'),
  ('A', '2021-11-02', '3'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-08-05', '1'),
  ('B', '2021-08-06', '3'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '2'),
  ('C', '2021-01-07', '3'),
  ('C', '2021-01-07', '3'),
  ('C', '2021-01-07', '1'),
  ('C', '2021-01-07', '1'),
  ('C', '2021-01-07', '2');

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  
CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09'),
  ('C', '2021-01-08');


SELECT *
FROM menu

SELECT *
FROM members

SELECT *
FROM sales

--Amount spent by customers at the restaurant.

select sales.customer_id, SUM(price) AS amount_spent
from menu
JOIN sales
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id


--Days each customer visited the restaurant.

SELECT customer_id, COUNT(DISTINCT(order_date)) AS days_visited
FROM sales
GROUP BY customer_id


--First item purchased in the menu by each customer.
 
SELECT sales.customer_id, sales.order_date, menu.product_name
FROM sales
JOIN menu ON sales.product_id = menu.product_id
JOIN (
    SELECT customer_id, MIN(order_date) AS first_order_date
    FROM sales
    GROUP BY customer_id
) first_orders
ON sales.customer_id = first_orders.customer_id 
AND sales.order_date = first_orders.first_order_date
ORDER BY sales.order_date ASC
LIMIT 3;


--Most purchased item on the menu and the number of times it was purchased by all customers.

SELECT COUNT(customer_id) AS total_purchased, menu.product_name 
FROM sales
JOIN menu 
ON sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY total_purchased DESC
LIMIT 1;


--Item that was the most popular for each customer.

WITH purchase_counts AS (
    SELECT sales.customer_id, menu.product_name, 
        COUNT(*) AS purchase_count,
        ROW_NUMBER() OVER(PARTITION BY sales.customer_id ORDER BY COUNT(*) DESC) AS rank
    FROM sales 
    JOIN 
        menu ON sales.product_id = menu.product_id
    GROUP BY sales.customer_id, menu.product_name
)
SELECT customer_id, product_name, purchase_count, rank
FROM purchase_counts;


--Items purchased by the customer after they became a member.

SELECT members.customer_id, sales.order_date,
members.join_date, menu.product_name
FROM members
INNER JOIN sales
ON sales.customer_id = members.customer_id
INNER JOIN menu
ON sales.product_id = menu.product_id
WHERE sales.order_date >= members.join_date


--Item purchased by customer just before they became a member.

WITH last_purchase_before_membership AS(
	SELECT s.customer_id, MAX(s.order_date) AS last_purchase_date
	FROM sales s
	JOIN members mb
	ON s.customer_id = mb.customer_id
	WHERE s.order_date < mb.join_date
	GROUP BY s.customer_id)
	
SELECT lpbm.customer_id, m.product_name
FROM last_purchase_before_membership lpbm
JOIN sales s ON lpbm.customer_id = s.customer_id
AND lpbm.last_purchase_date = s.order_date
JOIN menu m ON m.product_id = s.product_id
GROUP BY lpbm.customer_id, m.product_name;


--Total amount spent for each customer before they became a member.

WITH last_purchase_before_membership AS (
    SELECT s.customer_id, MAX(s.order_date) AS last_purchase_date
    FROM sales s
    JOIN members mb ON s.customer_id = mb.customer_id
    WHERE s.order_date < mb.join_date
    GROUP BY s.customer_id
)

SELECT lpbm.customer_id, 
       SUM(m.price) AS total_amount_spent_before_membership
FROM last_purchase_before_membership lpbm
JOIN sales s ON lpbm.customer_id = s.customer_id
            AND lpbm.last_purchase_date = s.order_date
JOIN menu m ON m.product_id = s.product_id
GROUP BY lpbm.customer_id;


--1 dollar spent = 10 points, sushi has 2 points multiplier then the points each customer would have:-

SELECT
    s.customer_id,
    SUM(m.price * 10 * CASE 
		WHEN m.product_name = 'sushi' THEN 2
		ELSE 1 END) AS total_points
FROM
    sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id;


--In the first week after a customer joins the program they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT 
    mb.customer_id,
    mb.join_date,
    SUM(m.price * CASE 
            WHEN mb.customer_id = 'A' AND s.order_date BETWEEN '2021-01-07' AND '2021-01-14' THEN 2
            WHEN mb.customer_id = 'B' AND s.order_date BETWEEN '2021-01-09' AND '2021-01-16' THEN 2
            WHEN mb.customer_id = 'C' AND s.order_date BETWEEN '2021-01-08' AND '2021-01-15' THEN 2
            ELSE 1
        END) AS total_points
FROM 
    members mb
JOIN 
    sales s ON s.customer_id = mb.customer_id
JOIN 
    menu m ON s.product_id = m.product_id
GROUP BY 
    mb.customer_id, mb.join_date;