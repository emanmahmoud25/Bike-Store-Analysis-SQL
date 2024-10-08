﻿---Explore Data---
select * from production.products;
select * from production.stocks;
select * from production.brands;
select * from production.categories;
select * from sales.customers;
select * from sales.orders;
select * from sales.staffs;
select * from sales.stores;
select * from sales.order_items;
------------------------------
----------------1. Product and Category Performance-----------------------------------
--1-What are the top-selling categories and brands?
select top 10 category_name ,brand_name,sum(oi.quantity) as'total sold'
from sales.order_items oi 
join production.products p on oi .product_id=p.product_id
join production.categories c on c.category_id=p.category_id
join production.brands b on b.brand_id=p.brand_id
group by category_name,brand_name
order by 'total sold' desc;
--------------------------------------------------------

--2- Which products have the highest sales volumes across all stores?
select top 10 p.product_name ,sum(oi.quantity) as 'total sold'
from sales.order_items oi 
join production.products p on oi.product_id=p.product_id
group by p.product_name
order by 'total sold' desc;

--3-What is the average price of products sold in each category?
select c.category_name ,avg(p.list_price) as 'average_price'
from production.categories c 
join production.products p on c.category_id=p.category_id
group by category_name
order by avg(p.list_price) desc;

--4--which category rejected more orders?
select top 1  c.category_name ,count(distinct oi.order_id) as rejected_order_count
from production.categories c
join production.products p on c.category_id=p.category_id 
join sales.order_items oi on oi.product_id =p.product_id
join sales.orders o on o.order_id =oi.order_id 
where o.order_status = 3
group by c.category_name
order by rejected_order_count desc;
---------------------------2. Customer Insights----------------------------------
--1-Which customers have made the most purchases (top 10)?
select top 10  concat(c.first_name,'',c.last_name)as 'Customer Name',
count( o.order_id) as 'Total Orders' from sales.customers c
join sales.orders o on c.customer_id =o.customer_id
group by c.first_name,c.last_name
order by 'Total Orders' desc;

--2-How many unique cities and states are represented by customers?
select count(distinct city) number_of_cities ,
count(distinct state) as number_of_state 
from sales.customers 

--3-What is the geographical distribution of customers?
select  top 15 city,state,count(customer_id) as 'total customers'
from sales.customers
group by city,state
order by 'total customers' desc;


--4-which state is doing better in terms of sales?
select top 1 s.state ,sum(oi.list_price * oi.quantity *(1-oi.discount)) as total_sales
from sales.stores s
join sales.orders o on  s.store_id=o.store_id
join sales.order_items oi on oi.order_id=o.order_id
group by s.state 
order by total_sales desc;


--5-What are the most common customer order statuses?
select order_status,count(order_id) as'Total Orders'
from sales.orders
group by order_status 
order by order_status ;

-------------------------------3.Sales Analysis and Revenue Trends------------------------------
--1-What is the total sales volume over time (monthly)?
select datepart(year,order_date) as order_year,
datepart(month,order_date)as order_month,sum(oi.quantity) as total_sales
from sales.orders o join sales.order_items oi 
on o.order_id=oi.order_id
GROUP BY datepart(year,order_date),
         datepart(month,order_date)
ORDER BY order_year, order_month;

--2-What is the total revenue generated by each store?
-- revenue =list_price*quantity*(1-discount)
select s.store_name,sum(oi.list_price*oi.quantity*(1-oi.discount)) as total_revenue
from sales.orders o 
join sales.order_items oi on o.order_id=oi.order_id
join sales.stores s on o.store_id=s.store_id
group by s.store_name
order by total_revenue desc;

--3-What is the total discount given across all orders?
select sum(discount) as total_discount_given
from sales.order_items

--4-What is the average revenue per order for completed orders?
select avg (items_count) as 'average revenue per order'
from(
select o.order_id ,sum(oi.quantity* oi.list_price *(1-oi.discount))  as items_count
from sales.orders o join sales.order_items oi on o.order_id=oi.order_id
where o.order_status=4
group by o.order_id 
) as order_revenues;

--5-What is the total revenue generated from completed orders?
select sum(oi.quantity * oi.list_price *(1-oi.discount)) as 'Total Revenue'
from sales.orders o join sales.order_items oi 
on o.order_id=oi.order_id
where o.order_status = 4; -- 4 is completed


--6-  stores are available in the database
select distinct store_name from sales.stores;

--7-Which store has the highest average order value?
select s.store_name,avg(oi.list_price*oi.quantity*(1-oi.discount)) as average_order_value
from sales.orders o 
join sales.order_items oi on o.order_id=oi.order_id
join sales.stores s on o.store_id=s.store_id
group by s.store_name
order by average_order_value desc;

--8-which 



-------------4- Staff Performance and Store Management-----------------

--1-Which staff member has processed the most orders?
select s.first_name + '' + s.last_name as full_name, 
       count(o.order_id) as total_orders
from sales.staffs s 
join sales.orders o on s.staff_id = o.staff_id
group by s.first_name, s.last_name
order by total_orders DESC;


--2-What is the performance comparison between stores?
select store_name ,count(o.order_id) as total_orders
from sales.stores s join sales.orders o on s.store_id=o.store_id
group by store_name
order by total_orders desc;

--3-Which store has the largest inventory stock for each product?
select  top 3 s.store_name,p.product_name,sk.quantity
from sales.stores s 
join production.stocks sk on s.store_id=sk.store_id 
join production.products p on sk.product_id=p.product_id
where sk.quantity =(
-- correlated nested query to find the max quantity for each product
SELECT MAX(quantity) FROM production.stocks  WHERE product_id = p.product_id)
ORDER BY sk.quantity DESC; 

--4-What percentage of staff members are currently active?
select (sum(case when active =1 then 1 else 0 end)*100 / count(staff_id)) as  active_staff_percentage
from sales.staffs;

--5-Which stores have the most active staff?
select store_name ,count(s.staff_id) as active_staff_count
from sales.stores st join sales.staffs s
on st.store_id=s.store_id 
where s.active =1
group by st.store_name
order by count(s.staff_id) desc;


-----------------5. Order Insights-----------------------
--1-What is the average order size by store?
select s.store_name ,avg(oi.quantity) as average_order_size
from sales.stores s 
join sales.orders o on s.store_id=o.store_id
join sales.order_items oi on o.order_id=oi.order_id
group by s.store_name;

--2-What is the percentage of orders that were shipped on time?
select (sum(case when o.shipped_date <= o.required_date then 1 else 0 end)* 100.00 / count(o.order_id))
as required_date from sales.orders o;

--3-Which products are most frequently discounted, and how does that affect sales?
select product_name ,count(oi.order_id) as total_sales,avg(oi.discount) as avg_aiscount
from sales.order_items oi 
join production.products p on oi.product_id=p.product_id
where oi.discount>0
group by p.product_name
order by total_sales desc;
--Conclusion:
--offering moderate discounts in the range of 9% to 11% proves to be the most effective strategy for maximizing sales.
--This balanced approach not only encourages customers to make purchases
--but also helps maintain healthier profit margins compared to both higher and lower discount levels.



----------------------------6. Inventory and Stock Management----------------------

--1-Which products are out of stock at multiple stores?
select p.product_name ,s.store_id,count(st.quantity) as 'out_of_stock_stores'
from production.products p
join production.stocks st on p.product_id=st.product_id
join sales.stores s on st.store_id=s.store_id
where st.quantity=0
group by product_name,s.store_id
Having count(s.store_id)>1;



--2-Which stores have the highest stock levels for the most in-demand products?
select s.store_name,p.product_name,sk.quantity
from production.products p
join production.stocks sk on p.product_id=sk.product_id
join sales.stores s on sk.store_id=s.store_id
where sk.quantity =
(select max(quantity) from production.stocks where product_id=p.product_id)
order by sk.quantity desc;

------------7. Order Fulfillment and Customer Satisfaction---------
--1-What is the average time taken to fulfill and ship an order?
select avg(datediff(day,order_date,shipped_date))as  average_fulfillment_time
from sales.orders 
where shipped_date is not null;

--2-How many orders have been rejected or are pending?
select order_status ,count(order_id) as total_orders
from sales.orders
where  order_status in (3,1)-- 3 = Rejected, 1 = Pending
group by order_status

--3-What percentage of orders were Completed
SELECT (SUM(CASE WHEN order_status = 4 THEN 1 ELSE 0 END) * 100.0 / COUNT(order_id)) AS Complete_percentage
FROM sales.orders;

-----------------8.Product Details and Performance------------------
--1-What are the top 5 most expensive products?
select top 5 product_name,list_price 
from production.products 
order by list_price desc;

--2-Which products have the lowest stock levels across all stores?
select top 10  p.product_name , sum(sk.quantity ) as total_stock
from production.products  p
join production.stocks sk on p.product_id=sk.product_id
group by p.product_name
order by total_stock asc;

-------------------9.Customer Demographics and Preferences----------------

--1- How Many total customers does BikeStore have?
SELECT count(distinct customer_id ) as total_customers
FROM sales.customers;

--2-who already buy succeded orders?
SELECT count(distinct s.customer_id ) as total_customers
FROM sales.customers s join sales.orders o
on s.customer_id=o.customer_id
where order_status != 3;

--3-What are the most popular product categories among customers?
select c.category_name ,count(o.order_id) as total_orders
from sales.orders o 
join sales.order_items oi on o.order_id=oi.order_id
join production.products p on oi.product_id =p.product_id
join production.categories c on p.category_id=c.category_id
group by category_name
order by count(o.order_id) desc;







-------------------------------10.Inventory Management-----------------------------------------------

--1-How many products are available across all stores?
select count(distinct product_id) as total_products_available
from production.stocks
where quantity >0;

--2-Which stores have products with stock levels lower than 5? ?
select top 10 s.store_name ,p.product_name,sk.quantity 
from production.products p 
join production.stocks sk  on p.product_id=sk.product_id
join sales.stores s on sk.store_id=s.store_id
where sk.quantity <5 ---- Stock threshold

-------------------11.Customer Order Patterns------------------------------
--1-What is the average number of items per order?
select avg(items_per_order) as average_items_per_order --Outer Query
from(
select o.order_id, count(oi.item_id) as items_per_order --Inner Query
from sales.orders o  join sales.order_items oi 
on o.order_id=oi.order_id
group by o.order_id 
)as order_item_counts;


--2-What is the total quantity of products ordered by each customer?
select top 10  concat(c.first_name , '',c.last_name)as full_name ,
sum(oi.quantity)as total_quantity_ordered
from sales.customers c 
join sales.orders o on c.customer_id=o.customer_id
join sales.order_items oi on o.order_id =oi.order_id
group by concat(c.first_name , '',c.last_name)
order by total_quantity_ordered desc;

--3-what did the customer with id 250 buy and when ? what is the status of this order?
SELECT  first_name +''+last_name as full_name ,p.product_name,oi.quantity,o.order_date,o.order_status
from sales.customers s
join sales.orders o on s.customer_id =o.customer_id
join sales.order_items oi ON o.order_id = oi.order_id
join production.products p ON oi.product_id = p.product_id
WHERE o.customer_id = 250;

--4-What is the distinct product name, quantity sold, list price, category, model year, and brand name
--for the product with product_id = 40?
select  distinct p.product_name, oi.quantity, p.list_price, c.category_name, p.model_year, b.brand_name
from production.products p
join sales.order_items oi on p.product_id = oi.product_id
join production.categories c on p.category_id = c.category_id
join production.brands b on p.brand_id = b.brand_id
where  p.product_id = 40;



























