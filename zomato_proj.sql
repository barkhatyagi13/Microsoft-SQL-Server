-- Step 1: Create database
CREATE DATABASE zomato_proj

-- Step 2: Change scope to preferred database
USE zomato_proj

-- Step 3: Create table and insert values for members having gold membership
CREATE TABLE goldusers_signup
	(user_id integer,
	 gold_signup_date date);

INSERT INTO goldusers_signup
VALUES
(1, '09-22-2017'),
(3, '04-21-2017');

-- Step 4: Create table and insert values for sales order
CREATE TABLE users
(user_id integer,
 signup_date date); 

INSERT INTO users
VALUES 
(1, '09-02-2014'),
(2, '01-15-2015'),
(3, '04-11-2014');

-- Step 5: Create table and insert values for sales order
CREATE TABLE sales
(user_id integer,
 order_date date,
 product_id integer); 

INSERT INTO sales 
VALUES
(1, '04-19-2017', 2),
(3, '12-18-2019', 1),
(2, '07-20-2020', 3),
(1, '10-23-2019', 2),
(1, '03-19-2018', 3),
(3, '12-20-2016', 2),
(1, '11-09-2016', 1),
(1, '05-20-2016', 3),
(2, '09-24-2017', 1),
(1, '03-11-2017', 2),
(1, '03-11-2016', 1),
(3, '11-10-2016', 1),
(3, '12-07-2017', 2),
(3, '12-15-2016', 2),
(2, '11-08-2017', 2),
(2, '09-10-2018', 3);

-- Step 6: Create table and insert values for products
CREATE TABLE product
(product_id integer,
 product_name text,
 price integer); 

INSERT INTO product
VALUES
(1, 'p1', 980),
(2, 'p2', 870),
(3, 'p3', 330);

-- Step 7: Checking the inserted data
select * from goldusers_signup;
select * from sales;
select * from product;
select * from users;

-- Q.1 What is the total amount each customer spends on zomato?
select s.user_id as [User ID], sum(p.price) as [Total Amount Spent]
from sales s inner join product p 
		on s.product_id = p.product_id
group by s.user_id;

-- Q.2 How many days did each customer order from zomato?
select user_id as [User ID], COUNT(distinct order_date) as [Total no. of days ordered]
from sales
group by user_id;

-- Q.3 What was the first product purchased by each customer?
select * from
(select *, rank() over(partition by user_id order by order_date) rnk from sales) a
where rnk = 1;

-- Q.4 What is the most purchased item on the menu and how many times was it purchased by all customers?
select user_id as [User ID], COUNT(product_id) as [Count]
from sales 
where product_id =
		(select top 1 product_id
		from sales
		group by product_id
		order by COUNT(product_id) desc)
group by user_id

-- Q.5 Which item was the most popular for each customer?
select * from
	(select *, rank() over(partition by user_id order by cnt desc) rnk 
	 from 
		(select USER_ID, product_id, COUNT(product_id) cnt
		 from sales
		 group by user_id , product_id) a
	) b
where rnk = 1;

-- Q.6 Which item was purchased first by the customer after they became a member?
select * from
	(select c.*, rank() over(partition by user_id order by order_date) rnk from
		(select s.*, g.gold_signup_date
		 from sales s inner join goldusers_signup g
				 on s.user_id = g.user_id
		 where order_date >= gold_signup_date) c
	) d
where rnk = 1;

-- Q.7 Which item was purchased just before the customer became a member?
select * from
	(select c.*, rank() over(partition by user_id order by order_date desc) rnk from
		(select s.*, g.gold_signup_date
		 from sales s inner join goldusers_signup g
				 on s.user_id = g.user_id
		 where order_date <= gold_signup_date) c
	) d
where rnk = 1;

-- Q.8 What is the total no. of orders and amount spent by each member before they became a member?
select user_id, count(order_date) as [Total no. of orders], sum(price) as [Amount Spent]
from 
 (select c.*, d.price 
  from
   (select s.*, g.gold_signup_date
    from sales s inner join goldusers_signup g
	 		on s.user_id = g.user_id
    where order_date <= gold_signup_date) c inner join product d 
			on c.product_id = d.product_id)e
group by user_id;

-- Q.9 If buying each product generates points for eg. 5 Rs. = 2 zomato points and each product has different purchasing points.
--     eg. For p1 5 Rs. = 1 zomato point, for p2 10 Rs. = 5 zomato points (i.e. 2 Rs. = 1 zomato point) and for 
--     p3 5 Rs. = 1 zomato point.
--     Calculate points collected by each customers and for which product most points have been given till now.
select user_id, sum(total_points) * 2.5 as [Total Money Earned]
from
(select e.*, amt/points as total_points
 from
 (select d.*, 
         case 
			when product_id = 1 then 5 
			when product_id = 2 then 2
			when product_id = 3 then 5
			else 0
		 end as points
  from
  (select c.user_id, c.product_id, sum(price) amt
   from
   (select a.*, b.price 
    from sales a inner join product b on a.product_id = b.product_id) c
   group by user_id, product_id)
   d) 
  e) 
 f
group by user_id;

select * from
(select *, rank() over(order by [Total Points Earned] desc) rnk
 from
  (select product_id, sum(total_points) as [Total Points Earned]
   from
   (select e.*, amt/points as total_points
    from
    (select d.*, 
         case 
			when product_id = 1 then 5 
			when product_id = 2 then 2
			when product_id = 3 then 5
			else 0
		 end as points
     from
     (select c.user_id, c.product_id, sum(price) amt
      from
      (select a.*, b.price 
       from sales a inner join product b on a.product_id = b.product_id) c
       group by user_id, product_id) d
	  ) e
	 ) f
  group by product_id) g
) h
where rnk = 1;

-- Q10 In the first one year after a customer joins the gold program (including the join date) irrespective of what customer has purchased they 
--     earn 5 zomato points for every 10rs spent. Who earned more more 1 or 3 and what was their points earning in first yearr?
SELECT c.*, (d.price)*0.5 Total_Points_Earned
from 
 (select a.user_id, a.order_date, a.product_id, b.gold_signup_date 
  from sales as a inner join goldusers_signup as b
		on a.user_id = b.user_id 
  where
  order_date >= gold_signup_date
  and order_date <= DATEADD(year, 1, gold_signup_date))c
				  inner join product d 
					on c.product_id = d.product_id;
 
-- Q.11 rnk all transaction of the customers?
select *, rank() over(partition by user_id order by order_date) as Transaction_Ranking
from sales;

-- Q.12 Rank all transaction for each member whenever they are zomato gold member for every non gold member transaction 
--      mark as NA
select e.*, 
case 
	when rnk = 0 then 'NA' 
	else rnk 
end as rnkk
from 
 (SELECT c.*, 
         cast((case 
				when gold_signup_date is null then 0 
				else rank() over(partition by user_id order by order_date desc)
			   end) as varchar) 
		 as rnk 
  from 
  (select a.user_id, a.order_date, a.product_id, b.gold_signup_date 
   from sales as a left join goldusers_signup as b 
	 	on a.user_id = b.user_id
		and order_date >= gold_signup_date) c) e;