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










