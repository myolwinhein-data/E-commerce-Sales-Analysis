CREATE DATABASE E_commerce_Transactional_DB;

USE E_commerce_Transactional_DB;

CREATE TABLE customers (
	customer_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(50),
    join_date DATE,
    region VARCHAR(50)
);

CREATE TABLE products (
	product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(50),
    category VARCHAR(50),
    price DECIMAL(10,2)
);

CREATE TABLE orders (
	order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    product_id INT,
    order_date DATE,
    quantity INT,
    FOREIGN KEY(customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY(product_id) REFERENCES products(product_id)
);

INSERT INTO customers (customer_name,join_date,region) VALUES
('Aung Aung','2026-01-10','Yangon'),
('Su Su', '2026-02-01','Mandalay'),
('Kyaw Kyaw','2026-01-15','Yangon'),
('Aye Aye','2026-01-10','Naypyitaw');

INSERT INTO products (product_name,category,price) VALUES
('Laptop','Electronics',1200),
('Mouse','Electronics',25),
('Keyboard','Electronics',45),
('Coffee Marker','Appliances',150),
('Air Fryer','Appliances',200);

INSERT INTO orders (customer_id,product_id,order_date,quantity) VALUES
(1,1,'2026-02-15',1),
(1,2,'2026-02-16',2),
(2,4,'2026-02-20',1),
(3,1,'2026-03-05',1),
(3,5,'2026-03-10',1),
(4,2,'2026-03-15',5),
(2,1,'2026-04-15',5);


SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM orders;


-- High Value Customers ( Total spend > 500 )
WITH customer_spending AS (
SELECT 
    c.customer_name,
    SUM(p.price * o.quantity) AS total_spend
FROM orders o
JOIN products p
	ON o.product_id = p.product_id
JOIN customers c 
	ON o.customer_id = c.customer_id
GROUP BY c.customer_name
)
SELECT * FROM customer_spending
WHERE total_spend > 500
ORDER BY total_spend DESC;


-- running total ( Cumulative Sales )
SELECT
    p.product_name,
    p.category,
    o.quantity,
    o.order_date,
    p.price,
    SUM(p.price * o.quantity ) OVER(PARTITION BY p.category ORDER BY o.order_date) AS cumulative_sale
FROM products p
JOIN orders o 
	ON p.product_id = o.order_id;
	

-- Customer Retention Analysis ( Repeat Purchase )
SELECT *
FROM customers
WHERE customer_id IN (
					SELECT 
						customer_id
					FROM orders
                    WHERE quantity > 1
                    );
   
   
-- Best Selling Categories by Region
WITH regional_sales AS(
SELECT
	c.region,
    p.category,
    SUM(o.quantity) AS total_quantity,
    ROW_NUMBER() OVER(PARTITION BY c.region ORDER BY SUM(o.quantity) DESC) AS ranking
FROM customers c
	JOIN orders o 
		ON c.customer_id = o.customer_id
	JOIN products P
		ON o.product_id = p.product_id
	GROUP BY c.region, p.category
    )
SELECT 
	region,
	category,
    total_quantity
FROM regional_sales
WHERE ranking = 1;

    
-- High Values product vs Low Values product
SELECT
	o.order_id,
    p.product_name,
	CASE 
		WHEN p.price > 500 THEN 'High Value Product'
        ELSE 'Low Value Product'
	END AS product_type,
    SUM(p.price * o.quantity) AS total_revenue
FROM orders o
	JOIN products p 
		ON o.product_id = p.product_id
GROUP BY order_id
ORDER BY total_revenue;


-- Monthly Growth Rate (MoM Growth)
WITH monthly_sales AS (
SELECT 
	o.order_date,
	MONTH(o.order_date) AS month_name,
    SUM(p.price * o.quantity) AS revenue
FROM orders o 
JOIN products p 
	ON o.product_id = p.product_id
GROUP BY order_id
)
SELECT 
	order_date,
	month_name,
    revenue,
    LAG(revenue) OVER(ORDER BY month_name) AS previous_month_revenue,
    ((revenue - LAG(revenue) OVER(ORDER BY month_name)) / LAG(revenue)OVER(ORDER BY month_name)) * 100 AS growth_percent
FROM monthly_sales;


-- Customer Lifetime values
SELECT 
	DISTINCT c.customer_id,
    c.customer_name,
    SUM(p.price * o.quantity) OVER(PARTITION BY c.customer_id) AS life_time_value
FROM customers c
	JOIN orders o 
		ON o.customer_id = c.customer_id
    JOIN products p 
		ON o.product_id = p.product_id;


-- Inventory Turnover
SELECT
	p.category,
    SUM(o.quantity) AS total_sold 
FROM orders o 
	JOIN products p 
		ON p.product_id = p.product_id
GROUP BY p.category
ORDER BY total_sold DESC;
