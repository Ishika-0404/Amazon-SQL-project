# **Amazon USA Sales Analysis Project**

### **Difficulty Level: Advanced**

---

## **Project Overview**

I have worked on analyzing a dataset of over 20,000 sales records from an Amazon-like e-commerce platform. This project involves extensive querying of customer behavior, product performance, and sales trends using PostgreSQL. Through this project, I have tackled various SQL problems, including revenue analysis, customer segmentation, and inventory management.

The project also focuses on data cleaning, handling null values, and solving real-world business problems using structured queries.

An ERD diagram is included to visually represent the database schema and relationships between tables.

---

## **Database Setup & Design**

### **Schema Structure**
```
CREATE TABLE category
(
  category_id	INT PRIMARY KEY,
  category_name VARCHAR(20)
);

-- customers TABLE
CREATE TABLE customers
(
  customer_id INT PRIMARY KEY,	
  first_name	VARCHAR(20),
  last_name	VARCHAR(20),
  state VARCHAR(20),
  address VARCHAR(5) DEFAULT ('xxxx')
);

-- sellers TABLE
CREATE TABLE sellers
(
  seller_id INT PRIMARY KEY,
  seller_name	VARCHAR(25),
  origin VARCHAR(15)
);

-- products table
CREATE TABLE products
  (
  product_id INT PRIMARY KEY,	
  product_name VARCHAR(50),	
  price	FLOAT,
  cogs	FLOAT,
  category_id INT, -- FK 
  CONSTRAINT product_fk_category FOREIGN KEY(category_id) REFERENCES category(category_id)
);

-- orders
CREATE TABLE orders
(
  order_id INT PRIMARY KEY, 	
  order_date	DATE,
  customer_id	INT, -- FK
  seller_id INT, -- FK 
  order_status VARCHAR(15),
  CONSTRAINT orders_fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  CONSTRAINT orders_fk_sellers FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);

select * from orders;
-- order_item

CREATE TABLE order_item(
	order_item_id int PRIMARY KEY,
	order_id int,
	product_id int,
	quantity int,
	price_per_unit float,
	CONSTRAINT order_item_fk_order FOREIGN KEY (order_id) REFERENCES orders(order_id),
  	CONSTRAINT order_item_fk_product FOREIGN KEY (product_id) REFERENCES products(product_id)
)
--payment

CREATE TABLE payments(
	payment_id int primary key,
	order_id int,
	payment_date date,
	payment_status varchar(20),
	CONSTRAINT payments_fk_order FOREIGN KEY (order_id) REFERENCES orders(order_id)
)

--shipping 

create table shipping(
	shipping_id int primary key,
	order_id int,
	shipping_date date,
	return_date	date,
	shipping_providers varchar(10),
	delivery_status varchar(10),
	CONSTRAINT shipping_fk_order FOREIGN KEY (order_id) REFERENCES orders(order_id)
)

create table inventory(
	inventory_id int primary key,
	product_id int,
	stock int,
	warehouse_id int,
	last_stock_date date,
	CONSTRAINT inventory_fk_order FOREIGN KEY (product_id) REFERENCES products(product_id)

)

```
---

## **Task: Data Cleaning**

I cleaned the dataset by:
- **Removing duplicates**: Duplicates in the customer and order tables were identified and removed.
- **Handling missing values**: Null values in critical fields (e.g., customer address, payment status) were either filled with default values or handled using appropriate methods.

---

## **Handling Null Values**

Null values were handled based on their context:
- **Customer addresses**: Missing addresses were assigned default placeholder values.
- **Payment statuses**: Orders with null payment statuses were categorized as “Pending.”
- **Shipping information**: Null return dates were left as is, as not all shipments are returned.

---

## **Objective**

The primary objective of this project is to showcase SQL proficiency through complex queries that address real-world e-commerce business challenges. The analysis covers various aspects of e-commerce operations, including:
- Customer behavior
- Sales trends
- Inventory management
- Payment and shipping analysis
- Forecasting and product performance
  

## **Identifying Business Problems**

Key business problems identified:
1. Low product availability due to inconsistent restocking.
2. High return rates for specific product categories.
3. Significant delays in shipments and inconsistencies in delivery times.
4. High customer acquisition costs with a low customer retention rate.

---

## **Solving Business Problems**

### Solutions Implemented:

```
select * from category;
select * from customers;
select * from inventory;
select * from order_item;
select * from orders;
select * from payments;
select * from products;
select * from shipping;
select * from sellers;
```

1. Top Selling Products
Query the top 10 products by total sales value.
Challenge: Include product name, total quantity sold, and total sales value.
```
ALTER table order_item
add column total_sales float;

UPDATE order_item
set total_sales= quantity* price_per_unit;


SELECT 
	oi.product_id,
	p.product_name,
	SUM(oi.total_sales) as total_sale,
	COUNT(o.order_id)  as total_orders
FROM orders as o
JOIN
order_item as oi
ON oi.order_id = o.order_id
JOIN 
products as p
ON p.product_id = oi.product_id
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 10
```


2. Revenue by Category
Calculate total revenue generated by each product category.
Challenge: Include the percentage contribution of each category to total revenue.
```
select p.category_id,
	c.category_name ,
	sum(oi.total_sales) as total_revenue,
	sum(oi.total_sales)/(select sum(total_sales) from order_item )*100 as total_contribution
from category c
left join products p 
	on c.category_id=p.category_id
join order_item oi
	on p.product_id = oi.product_id
group by p.category_id,
	c.category_name
	order by 3 desc


```
3. Average Order Value (AOV)
Compute the average order value for each customer.
Challenge: Include only customers with more than 5 orders.
```

-- join customer-order_item-orders
-- avg(price) >customers with more than 5 orders.

select c.customer_id,
	concat(c.first_name,' ',c.last_name) as full_name,
	SUM(total_sales)/COUNT(o.order_id) as AOV,
	COUNT(o.order_id) as total_orders
from customers c
join orders o
	on c.customer_id =o.customer_id
join order_item oi
	on o.order_id=oi.order_id
group by c.customer_id
having count(o.order_id) >5


```
4. Monthly Sales Trend
Query monthly total sales over the past year.
Challenge: Display the sales trend, grouping by month, return current_month sale, last month sale!
```

-- last year sales
-- month - current month sale and previous month sale
-- join orders - order_item

select * from order_item;
select * from orders;

select year,
	month,
	total_sale as current_month_sale,
	lag(total_sale,1) over(order by year,month) as preious_month_sale
from
(
select 
	extract(month from o.order_date) as month,
	extract (year from o.order_date) as year,
	round(
		sum(oi.total_sales:: numeric),2) as total_sale
from orders o
join order_item oi
	on o.order_id= oi.order_id
where o.order_date >= current_date - interval '1 year'
group by 1,2
order by year , month
)


```
5. Customers with No Purchases
Find customers who have registered but never placed an order.
Challenge: List customer details and the time since their registration.
```

--approach 1

select c.customer_id,
	c.first_name,
	c.last_name,
	c.state,
	c.address
from customers c left join orders o 
on c.customer_id = o.customer_id
group by c.customer_id
having count(o.order_id)=0
order by c.customer_id asc

--approach 2

SELECT *	
FROM customers
WHERE customer_id NOT IN (SELECT 
					DISTINCT customer_id
				FROM orders
				)
order by customer_id;

--approach 3

SELECT *
FROM customers as c
LEFT JOIN
orders as o
ON o.customer_id = c.customer_id
WHERE o.customer_id IS NULL

```
6. Least-Selling Categories by State
Identify the least-selling product category for each state.
Challenge: Include the total sales for that category within each state.


```
-- join category, products, order_item, customers
--group by state , min(sum(total_sale))
--approch 1

select min(total_sale),
	state	
from(
select 
	cu.state as state,
	c.category_id as category_id ,
	c.category_name as name,
	sum(oi.total_sales) as total_sale
from customers cu 
join orders o
 	on cu.customer_id = o.customer_id
join order_item oi
	on o.order_id= oi.order_id
join products p
	on oi.product_id = p.product_id
join category c
	on p.category_id= c.category_id
group by cu.state,2
order by 1,4 desc

) as t1
group by state

--approch 2

with cte as(
select 
	cu.state as state,
	c.category_id as category_id ,
	c.category_name as name,
	sum(oi.total_sales) as total_sale,
	rank() over(partition by cu.state order by sum(oi.total_sales) asc) as rank
from customers cu 
join orders o
 	on cu.customer_id = o.customer_id
join order_item oi
	on o.order_id= oi.order_id
join products p
	on oi.product_id = p.product_id
join category c
	on p.category_id= c.category_id
group by cu.state,2
order by 1,4 asc

) 

select * from cte where rank=1
```

7. Customer Lifetime Value (CLTV)
Calculate the total value of orders placed by each customer over their lifetime.
Challenge: Rank customers based on their CLTV.

```
select c.customer_id,
	concat(c.first_name,' ',c.last_name) as full_name,
	SUM(total_sales) as CLTV,
	dense_rank() over(partition by SUM(total_sales) order by SUM(total_sales) asc) as rank
from customers c
join orders o
	on c.customer_id =o.customer_id
join order_item oi
	on o.order_id=oi.order_id
group by c.customer_id,2
```


8. Inventory Stock Alerts
Query products with stock levels below a certain threshold (e.g., less than 10 units).
Challenge: Include last restock date and warehouse information.

```
select i.inventory_id,
	p.product_id,
	i.stock,
	i.last_stock_date,
	i.warehouse_id
from inventory i
join products p
	on i.product_id= p.product_id
where stock <10

```


9. Shipping Delays
Identify orders where the shipping date is later than 3 days after the order date.
Challenge: Include customer, order details, and delivery provider.
```

select c.*,
	o.*,
	s.shipping_providers,
	s.shipping_date - o.order_date as days_took_to_ship
from shipping s
join orders o 
	on o.order_id = s.order_id
join customers c
	on c.customer_id=o.customer_id
where s.shipping_date - o.order_date >3
```


10. Payment Success Rate 
Calculate the percentage of successful payments across all orders.
Challenge: Include breakdowns by payment status (e.g., failed, pending).


```
select p.payment_status,
	count(*),
	count(*)/(select count(*) from payments)::numeric  *100 
	from orders o 
join payments p
on o.order_id= p.order_id
group by payment_status
```



11. Top Performing Sellers
Find the top 5 sellers based on total sales value.
Challenge: Include both successful and failed orders, and display their percentage of successful orders.


```
with top_sellers as
(
select 
	s.seller_id,
	s.seller_name,
	sum(oi.total_sales) as total_sale
from orders o
join sellers s 
	on o.seller_id = s.seller_id
join order_item oi 
	on oi.order_id = o.order_id
group by s.seller_id,
	s.seller_name
order by 3 desc 
limit 5
),
sellers_reports as
(
select o.seller_id,
	ts.seller_name,
	o.order_status,
	count(*) as total_orders
from orders o 
join top_sellers ts
on ts.seller_id=o.seller_id
WHERE 
	o.order_status NOT IN ('Inprogress', 'Returned')
	
GROUP BY 1, 2, 3
)
SELECT 
	seller_id,
	seller_name,
	SUM(CASE WHEN order_status = 'Completed' THEN total_orders ELSE 0 END) as Completed_orders,
	SUM(CASE WHEN order_status = 'Cancelled' THEN total_orders ELSE 0 END) as Cancelled_orders,
	SUM(total_orders) as total_orders,
	SUM(CASE WHEN order_status = 'Completed' THEN total_orders ELSE 0 END)::numeric/
	SUM(total_orders)::numeric * 100 as successful_orders_percentage
	
FROM sellers_reports
GROUP BY 1, 2
```
12. Product Profit Margin
Calculate the profit margin for each product (difference between price and cost of goods sold).
Challenge: Rank products by their profit margin, showing highest to lowest.
```

select product_id,
	product_name,
	dense_rank() over(
					order by profit_margin desc) as ranking
from(
select p.product_id,
	p.product_name,
	sum(oi.total_sales-(p.cogs * oi.quantity)) as profit,
	sum(oi.total_sales-(p.cogs * oi.quantity))/sum(oi.total_sales) as profit_margin
	--dense_rank() over(partition by sum(oi.total_sales-(p.cogs * oi.quantity))/sum(oi.total_sales)
	--			order by sum(oi.total_sales-(p.cogs * oi.quantity))/sum(oi.total_sales)) as rank
from orders o 
join order_item oi
on o.order_id= oi.order_id
join products p
on p.product_id= oi.product_id
group by p.product_id,
	p.product_name
)

```
13. Most Returned Products
Query the top 10 products by the number of returns.
Challenge: Display the return rate as a percentage of total units sold for each product.
```
--approach 1
select p.product_id,
	count(s.return_date) as return_products,
	count(oi.quantity) as total_quantity,
	(count(s.return_date)::numeric/count(oi.quantity)::numeric) * 100 as return_rate
from shipping s 
join orders o 
on o.order_id = s.order_id
join order_item oi
on o.order_id=oi.order_id
join products p
on oi.product_id = p.product_id
group by 
	p.product_id
order by 4 desc
limit 10

--approch 2
SELECT 
	p.product_id,
	p.product_name,
	COUNT(*) as total_unit_sold,
	SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END) as total_returned,
	SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END)::numeric/COUNT(*)::numeric * 100 as return_percentage
FROM order_item as oi
JOIN 
products as p
ON oi.product_id = p.product_id
JOIN orders as o
ON o.order_id = oi.order_id
GROUP BY 1, 2
ORDER BY 5 desc
limit 10

```
14. Orders Pending delivered
Find orders that have been paid but are still pending delivery.
Challenge: Include order details, payment date, and customer information.
```

select delivery_status from shipping group by delivery_status
select payment_status  from payments group by payment_status
select order_status  from orders group by order_status

select c.customer_id,
	o.order_id,
	p.payment_date,
	p.payment_status,
	s.delivery_status,
	case 
		when 
			p.payment_status = 'Payment Successed' 
			and 
			s.delivery_status = 'Shipped' 
		then 1 
		else 0 
		end 
		as order_pending_delivered
from shipping s
join orders o 
on s.order_id = o.order_id
join payments p
on o.order_id = p.order_id
join customers c
on o.customer_id = c.customer_id
WHERE 
    p.payment_status = 'Payment Successed' 
    AND s.delivery_status = 'Shipped'
order by order_pending_delivered desc


```
15. Inactive Sellers
Identify sellers who haven’t made any sales in the last 6 months.
Challenge: Show the last sale date and total sales from those sellers.
```
WITH cte1 -- as these sellers has not done any sale in last 6 month
AS
(SELECT * FROM sellers
WHERE seller_id NOT IN (SELECT seller_id FROM orders WHERE order_date >= CURRENT_DATE - INTERVAL '6 month')
)

SELECT 
o.seller_id,
MAX(o.order_date) as last_sale_date,
MAX(oi.total_sales) as last_sale_amount
FROM orders as o
JOIN 
cte1
ON cte1.seller_id = o.seller_id
JOIN order_item as oi
ON o.order_id = oi.order_id
GROUP BY 1



```
16. IDENTITY customers into returning or new
if the customer has done more than 5 return categorize them as returning otherwise new
Challenge: List customers id, name, total orders, total returns
```
select * from customers;
select * from order_item;
select * from orders;


with cte as(
select c.customer_id,
	concat(c.first_name,' ',c.last_name) as fullname,
	count(o.order_id) as total_orders,
	sum(case when o.order_status='Returned' then 1 else 0 end) as total_returns
	
	
from customers c
join orders o
on c.customer_id = o.customer_id
join order_item oi
on oi.order_id= o.order_id
group by c.customer_id,o.order_status

)

select (case when total_returns >5 then 'Returning' else 'New' end) as Category,
 	--(case when total_returns <5 then 1 else 0 end) as new,
	customer_id,
	fullname,
	total_orders,
	total_returns
from cte


```



18. Top 5 Customers by Orders in Each State
Identify the top 5 customers with the highest number of orders for each state.
Challenge: Include the number of orders and total sales for each customer.
```
SELECT * FROM 
(
select c.customer_id,
	c.state,
	concat(c.first_name,' ',c.last_name) as fullname,
	count(o.order_id) as total_orders,
	SUM(total_sales) as total_sale,
	DENSE_RANK() OVER(PARTITION BY c.state ORDER BY COUNT(o.order_id) DESC) as rank

from customers c
join orders o
on c.customer_id = o.customer_id
join order_item oi
on oi.order_id = o.order_id
group by c.state,c.customer_id
) as t1
WHERE rank <=5


```
19. Revenue by Shipping Provider
Calculate the total revenue handled by each shipping provider.
Challenge: Include the total number of orders handled and the average delivery time for each provider.
```

select s.shipping_providers,
	COUNT(o.order_id) as order_handled,
	SUM(oi.total_sales) as total_sale,
	COALESCE(AVG(s.return_date - s.shipping_date), 0) as average_days 
from shipping s
join orders o
on s.order_id = o.order_id
join order_item oi
on oi.order_id = o.order_id
group by 1


```
20. Top 10 product with highest decreasing revenue ratio compare to last year(2022) and 
current_year(2023)
Challenge: Return product_id, product_name, category_name, 2022 revenue and 2023 revenue 
decrease ratio at end Round the result

Note: Decrease ratio = cr-ls/ls* 100 (cs = current_year ls=last_year)
```


WITH last_year_sale
as
(
SELECT 
	p.product_id,
	p.product_name,
	SUM(oi.total_sales) as revenue
FROM orders as o
JOIN 
order_item as oi
ON oi.order_id = o.order_id
JOIN 
products as p
ON 
p.product_id = oi.product_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2022
GROUP BY 1, 2
),

current_year_sale
AS
(
SELECT 
	p.product_id,
	p.product_name,
	SUM(oi.total_sales) as revenue
FROM orders as o
JOIN 
order_item as oi
ON oi.order_id = o.order_id
JOIN 
products as p
ON 
p.product_id = oi.product_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2023
GROUP BY 1, 2
)

SELECT
	cs.product_id,
	ls.revenue as last_year_revenue,
	cs.revenue as current_year_revenue,
	ls.revenue - cs.revenue as rev_diff,
	ROUND((cs.revenue - ls.revenue)::numeric/ls.revenue::numeric * 100, 2) as reveneue_dec_ratio
FROM last_year_sale as ls
JOIN
current_year_sale as cs
ON ls.product_id = cs.product_id
WHERE 
	ls.revenue > cs.revenue
ORDER BY 5 DESC
LIMIT 10


```
Final Task
-- Store Procedure
create a function as soon as the product is sold the the same quantity should reduced from inventory table
after adding any sales records it should update the stock in the inventory table based on the product and qty purchased
-- 
```

CREATE OR REPLACE PROCEDURE add_sales
(
p_order_id INT,
p_customer_id INT,
p_seller_id INT,
p_order_item_id INT,
p_product_id INT,
p_quantity INT
)
LANGUAGE plpgsql
AS $$

DECLARE 
-- all variable
v_count INT;
v_price FLOAT;
v_product VARCHAR(50);

BEGIN
-- Fetching product name and price based p id entered
	SELECT 
		price, product_name
		INTO
		v_price, v_product
	FROM products
	WHERE product_id = p_product_id;
	
-- checking stock and product availability in inventory	
	SELECT 
		COUNT(*) 
		INTO
		v_count
	FROM inventory
	WHERE 
		product_id = p_product_id
		AND 
		stock >= p_quantity;
		
	IF v_count > 0 THEN
	-- add into orders and order_items table
	-- update inventory
		INSERT INTO orders(order_id, order_date, customer_id, seller_id)
		VALUES
		(p_order_id, CURRENT_DATE, p_customer_id, p_seller_id);

		-- adding into order list
		INSERT INTO order_item(order_item_id, order_id, product_id, quantity, price_per_unit, total_sales)
		VALUES
		(p_order_item_id, p_order_id, p_product_id, p_quantity, v_price, v_price*p_quantity);

		--updating inventory
		UPDATE inventory
		SET stock = stock - p_quantity
		WHERE product_id = p_product_id;
		
		RAISE NOTICE 'Thank you product: % sale has been added also inventory stock updates',v_product; 
	ELSE
		RAISE NOTICE 'Thank you for for your info the product: % is not available', v_product;
	END IF;
END;
$$




--**Testing Store Procedure**
call add_sales
(
25005, 2, 5, 25004, 1, 14
);

---

```
