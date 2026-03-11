-- -------------------SQL FINAL PROJECT-------------------

-- Create Database:

SHOW DATABASES;
CREATE DATABASE IF NOT EXISTS final_project;
USE final_project;
SHOW tables;

-- Fetch tables:

SELECT * FROM customers;
SELECT * FROM order_items;
SELECT * FROM orders;
SELECT * FROM payments;
SELECT * FROM products;

-- 1. Find customers who have placed more than 3 orders:

SELECT c.customer_id, c.customer_name, COUNT(o.order_id) AS total_orders
FROM customers c, orders o
WHERE c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING total_orders>3;

-- 2. Display the top 5 customers based on total purchase value:

SELECT c.customer_id, c.customer_name, sum(i.quantity*p.price) total_purchase_value
FROM customers c, orders o, order_items i, products p, payments p1
WHERE c.customer_id = o.customer_id
AND o.order_id = i.order_id
AND i.product_id = p.product_id
AND i.order_id = p1.order_id
AND p1.payment_status = 'Success'
GROUP BY c.customer_id, c.customer_name,i.quantity ,p.price
ORDER BY total_purchase_value DESC LIMIT 5;

-- 3. List products that have never been ordered:

SELECT p.product_id,p.product_name
FROM products p
LEFT JOIN order_items o 
ON p.product_id = o.product_id
WHERE o.product_id IS NULL;

-- 4. Find the most sold product (by quantity):

SELECT p.product_id, p.product_name, SUM(o.quantity) total_quantity
FROM products p, order_items o, payments y
WHERE p.product_id = o.product_id
AND o.order_id = y.order_id
AND y.payment_status = 'Success'
GROUP BY p.product_id, p.product_name
ORDER BY total_quantity DESC;

-- 5. Show each customer’s latest order using a single query:

SELECT c.customer_id, c.customer_name, o.order_date
FROM customers c, orders o
WHERE c.customer_id = o.customer_id
AND o.order_date = (SELECT MAX(d.order_date) FROM orders d
					WHERE d.customer_id=c.customer_id);

-- 6. Identify orders where payment failed but order status is marked as Delivered:

SELECT o.order_id, p.payment_date, p.payment_status, o.order_status
FROM orders o, payments p
WHERE o.order_id = p.order_id
AND p.payment_status = 'Failed'
AND o.order_status = 'Delivered';

-- 7. Calculate total revenue generated per product category:

SELECT p.category, SUM(o.quantity*p.price) total_revenue
FROM products p, order_items o, payments y
WHERE p.product_id = o.product_id
AND o.order_id = y.order_id
GROUP BY p.category;

-- 8. Find customers who placed orders but never made a successful payment:

SELECT c.customer_id, c.customer_name, o.order_id, o.order_date,o.order_status, p.payment_status
FROM customers c, orders o, payments p
WHERE c.customer_id = o.customer_id
AND o.order_id = p.order_id
AND payment_status = 'Failed'
AND o.order_status = 'Placed';

-- 9. Display each order along with the total bill amount after discount:

SELECT o.order_id, SUM(o.quantity*p.price*(o.discount/100)) bill_amount
FROM order_items o,products p
WHERE o.product_id = p.product_id
GROUP BY o.order_id;

-- 10. Rank customers within each city based on total spending:

SELECT
RANK() OVER (PARTITION BY c.city ORDER BY SUM(i.quantity * p.price) DESC) AS rank_position,
c.customer_id, c.city,
SUM(i.quantity * p.price) AS Total_Spending
FROM customers c, orders o, order_items i, products p
WHERE c.customer_id = o.customer_id
AND o.order_id = i.order_id
AND i.product_id = p.product_id
GROUP BY c.city, c.customer_id, c.customer_name;

-- 11. Find the second highest priced product in each category:

SELECT s.category_rank, s.category, s.product_name, s.price
FROM(SELECT RANK() OVER(PARTITION BY p.category ORDER BY p.price DESC) AS category_rank, p.category,p.product_name,p.price
FROM products p) s
WHERE s.category_rank = 2;

-- 12. Show month-wise total number of orders and revenue:

SELECT MONTH(o.order_date) AS order_month, COUNT(DISTINCT o.order_id) AS total_orders, SUM(d.quantity * p.price) AS total_revenue
FROM orders o JOIN order_items d ON o.order_id = d.order_id
JOIN products p ON d.product_id = p.product_id
GROUP BY order_month
ORDER BY order_month;

-- 13. Identify customers whose total spending is above the average customer spending:

SELECT c1.customer_id, c1.customer_name, SUM(d1.quantity*p1.price) total_customer_spend
FROM customers c1
INNER JOIN orders o1 ON c1.customer_id = o1.customer_id
INNER JOIN order_items d1 ON o1.order_id = d1.order_id
INNER JOIN products p1 ON d1.product_id = p1.product_id
GROUP BY c1.customer_id, c1.customer_name
HAVING total_customer_spend >
(SELECT AVG(total_spent) FROM
(SELECT o.customer_id, SUM(d.quantity * p.price) AS total_spent
FROM orders o
JOIN order_items d ON o.order_id = d.order_id
JOIN products p ON d.product_id = p.product_id
GROUP BY o.customer_id) s);

-- 14. Display orders where order total is greater than any order placed by customers from Delhi:

SELECT o.order_id, SUM(d.quantity*p.price) total_order_amount
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN order_items d ON d.order_id = o.order_id
INNER JOIN products p ON p.product_id = d.product_id
GROUP BY order_id
HAVING total_order_amount >
ANY (SELECT (d.quantity*p.price) amount
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN order_items d ON d.order_id = o.order_id
INNER JOIN products p ON p.product_id = d.product_id
WHERE c.city = 'Delhi')
ORDER BY total_order_amount DESC;

-- 15. Write a query to show cumulative revenue ordered by order date:

SELECT o.order_date, SUM(d.quantity*p.price) cumulative_revenue
FROM orders o
INNER JOIN order_items d ON o.order_id = d.order_id
INNER JOIN products p ON d.product_id = p.product_id
GROUP BY o.order_date;

-- 16. Find products whose stock is less than the average stock of their category:

SELECT p.*
FROM products p
WHERE p.stock_qty<
(SELECT AVG(p1.stock_qty)
FROM products p1
WHERE p1.category = p.category);

-- 17. reate a stored procedure to fetch all orders of a given customer:

DELIMITER //
CREATE PROCEDURE get_customer_orders(IN customerid INT)
BEGIN
SELECT c.customer_id, c.customer_name,o.order_id, o.order_date, o.order_status
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE c.customer_id = customerid
ORDER BY o.order_date DESC;
END//
DELIMITER ;

call get_customer_orders(18);

-- 18. Identify customers who placed an order on the same day they signed up:

SELECT c.customer_id, c.customer_name,o.order_id, o.order_date, o.order_status
FROM customers c, orders o
WHERE c.customer_id = o.customer_id
AND c.signup_date = o.order_date;

-- ----------------------------------------------------------------------------------------------------------
