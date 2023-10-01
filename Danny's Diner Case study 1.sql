CREATE DATABASE dannys_diner;

USE dannys_diner;

-- Creating the tables
CREATE TABLE sales(
customer_id VARCHAR (1),
order_date DATE,
product_id INT
);

CREATE TABLE members(
customer_id VARCHAR (1),
join_date DATE
);

CREATE TABLE menu(
product_id INT,
product_name VARCHAR(5),
price INT
);

-- Populating the tables
INSERT INTO sales VALUES
('A', '2021-01-01', 1),
('A', '2021-01-01', 2),
('A', '2021-01-07', 2),
('A', '2021-01-10', 3),
('A', '2021-01-11', 3),
('A', '2021-01-11', 3),
('B', '2021-01-01', 2),
('B', '2021-01-02', 2),
('B', '2021-01-04', 1),
('B', '2021-01-11', 1),
('B', '2021-01-16', 3),
('B', '2021-02-01', 3),
('C', '2021-01-01', 3),
('C', '2021-01-01', 3),
('C', '2021-01-07', 3);

SELECT * FROM sales;

-- Populating members table
INSERT INTO members VALUES
('A', '2021-01-07'),
('B', '2021-01-09');

SELECT * FROM members;

-- Populating menu table
INSERT INTO menu VALUES
(1, 'sushi', 10),
(2, 'curry', 15),
(3, 'ramen', 12);

SELECT * FROM menu;

-- CASE STUDY QUESTIONS
/* 1. What is the total amount each customer
spent at the restaurant */
SELECT 
    s.customer_id,
    SUM(m.price) as total_amt_spent
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id;

/* 2. How many days has each customeer visited the restaurant */
SELECT 
    customer_id, 
    COUNT(Distinct order_date) AS No_of_days
FROM sales
GROUP BY customer_id;

/*  3. What was the first item purchased by each customer from 
the menu */
WITH ranked_data AS(
    SELECT
        customer_id,
        product_name,
        order_date,
        RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS rnk
    FROM sales s
    JOIN menu m ON s.product_id = m.product_id
)
SELECT DISTINCT
    customer_id,
    product_name AS first_purchase
FROM ranked_data
WHERE rnk = 1;

/* 4. What is the most purchased item on the menu and how many
 times was it purchased by all customers*/
SELECT
    m.product_name AS most_purchased_item,
    COUNT(*) AS total_purchases
FROM menu m
JOIN sales s
ON s.product_id = m.product_id
GROUP BY  m.product_name
ORDER BY total_purchases DESC
LIMIT 1;

/* 5. Which item was the most popular for each customer */
WITH ranked_data AS(
    SELECT
        customer_id,
        product_name,
        COUNT(*) AS purchases,
        RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(*) DESC) AS rnk
    FROM sales s
    JOIN menu m ON s.product_id = m.product_id
    GROUP BY customer_id, product_name
)
SELECT
    customer_id,
    product_name,
    purchases
FROM ranked_data
WHERE rnk = 1;

/* 6. Which item was purchased first by the customer after they became 
a member */
WITH first_purchase AS(
    SELECT
        s.customer_id,
        s.order_date,
        m.product_name,
        join_date,
        RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rnk
    FROM sales s
    JOIN members mem ON s.customer_id = mem.customer_id
    JOIN menu m ON s.product_id = m.product_id
    WHERE s.order_date >= mem.join_date
)
SELECT
    customer_id,
    product_name AS first_item_purchased
FROM first_purchase
WHERE rnk = 1;

/* 7. Which item was purchased just before the customer 
became a member */
SELECT customer_id, product_name AS lst_purchase_as_non_member
FROM(
    SELECT 
        s.customer_id, 
        s.order_date, 
        s.product_id,
        RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rnk
    FROM sales s
    JOIN members mem
    ON s.customer_id = mem.customer_id
    WHERE s.order_date < mem.join_date
)x
JOIN menu m ON x.product_id = m.product_id
WHERE rnk = 1;

/* 8. What is the total items and amount spent for each 
member before they became a member */
SELECT
    s.customer_id,
    COUNT(product_name) AS total_items_purchased,
    SUM(price) AS amount_spent
FROM sales s
JOIN menu m ON s.product_id = m.product_id
JOIN members mem ON s.customer_id = mem.customer_id
WHERE s.order_date < mem.join_date
GROUP BY s.customer_id;

/* 9. If each $1 spent equates to 10 points and sushi has a 
2x points multiplier - how many points would each customer have? */
SELECT 
    s.customer_id,
    SUM(CASE WHEN m.product_name = 'sushi' THEN m.price * 10 * 2
    ELSE m.price * 10 
    END) AS total_points
FROM sales s 
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;

/* 10. In the first week after a customer joins the program 
(including their join date) they earn 2x points on all items,
 not just sushi - how many points do customer A and B have at 
 the end of January? */
SELECT 
    s.customer_id,
    SUM(CASE
            WHEN s.order_date BETWEEN mem.join_date AND DATE_ADD(mem.join_date, INTERVAL 6 DAY) THEN m.price * 10 *2
            WHEN m.product_name = 'sushi' THEN m.price * 10 * 2
            ELSE m.price * 10
        END) AS total_points
FROM sales s 
JOIN menu m ON s.product_id = m.product_id
JOIN members mem ON s.customer_id = mem.customer_id
WHERE s.order_date <= '2021-01-31'
GROUP BY s.customer_id;

-- Bonus Question
SELECT
    s.customer_id,
    s.order_date,
    m.product_name,
    m.price,
    CASE
        WHEN s.order_date < mem.join_date THEN 'N'
        WHEN join_date IS NULL THEN 'N'
        ELSE 'Y'
    END AS member
FROM sales s
JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mem ON s.customer_id = mem.customer_id
ORDER BY s.customer_id, order_date, price DESC;




