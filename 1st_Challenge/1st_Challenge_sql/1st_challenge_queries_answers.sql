# My MySQL version is 8.0.30
-- SELECT VERSION();
# How to check corrent MySQL version? https://phoenixnap.com/kb/how-to-check-mysql-version
# Case Study #1 - Danny's Diner, Find more info here: https://8weeksqlchallenge.com/case-study-1/

USE dannys_diner;

# join tables
with t1 as (SELECT s.customer_id, mn.join_date, s.order_date, me.product_id, me.product_name, me.price
FROM sales AS s
LEFT JOIN members AS mn ON  s.customer_id=mn.customer_id # MySQL has no 'full outer join' function so i use 'left join'. https://stackoverflow.com/questions/4796872/how-can-i-do-a-full-outer-join-in-mysql
left join menu as me on s.product_id=me.product_id
order by 1,3),

-- 1. What is the total amount each customer spent at the restaurant?
-- select customer_id, sum(price)
-- from t1
-- group by 1;

-- 2. How many days has each customer visited the restaurant?
-- select customer_id, count(order_date) as days_counter
-- from(
-- select distinct customer_id, order_date
-- from t1 ) sub1
-- group by 1;

-- 3. What was the first item from the menu purchased by each customer?
-- select t1.customer_id, sub2.first_order, t1.product_name
-- from (
-- select customer_id, min(order_date) as first_order
-- from t1
-- group by 1) sub2 
-- join t1 on sub2.first_order=t1.order_date and t1.customer_id=sub2.customer_id
-- order by 1

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
   -- p1: What is the most purchased item? 
# Find the mode
t2 as (select product_name, count(product_name) as occurs
from t1
group by 1),

-- select product_name, occurs
-- from t2
-- where occurs= (select max(occurs)
-- from t2);

   -- p2: how many times was it purchased by all customers?
-- select t1.customer_id, t1.product_name, count(t1.product_name) as mode_itme_counter
-- from (
-- select product_name, occurs
-- from t2
-- where occurs= (select max(occurs)
-- from t2)) sub4
-- join t1 on t1.product_name=sub4.product_name
-- group by 1

-- 5. Which item was the most popular for each customer?
t3 as (select customer_id, product_name, count(product_name) as product_counter
from t1
group by 1,2),

-- select t3.customer_id, t3.product_name, t3.product_counter
-- from(
-- select customer_id, product_name, max(product_counter)  product_max
-- from t3 
-- group by 1) sub5
-- join t3 on t3.customer_id=sub5.customer_id and t3.product_counter=sub5.product_max

-- 6. Which item was purchased first by the customer after they became a member?
# Add 'joined' column 
t4 as (SELECT customer_id, join_date, order_date, product_id, product_name, price, case when order_date>=join_date then 'Y' else 'N' end as joined
FROM t1
order by 1,3)

-- select t4.customer_id, t4.join_date, t4.order_date, t4.product_name
-- from(
-- select customer_id, join_date, min(order_date) min_order_date, product_name
-- from t4
-- where joined='Y' && join_date<=order_date
-- group by 1) sub5
-- join t4 on t4.customer_id=sub5.customer_id and t4.order_date=sub5.min_order_date


-- 7. Which item was purchased just before the customer became a member?
-- select t4.customer_id, t4.join_date, t4.order_date, t4.product_name
-- from(
-- select customer_id, join_date, max(order_date) max_order_date, product_name
-- from t4
-- where joined='N' 
-- group by 1) sub5
-- join t4 on t4.customer_id=sub5.customer_id and t4.order_date=sub5.max_order_date

-- 8. What is the total items and amount spent for each member before they became a member?
-- select customer_id, count(product_name) counter_product, sum(price) sum_price
-- from t4
-- where joined='N'
-- group by 1

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- select customer_id, sum(sum_points) as sum_points
-- from (
-- select customer_id, case when product_name='sushi' then price*20 else price*10 end as sum_points
-- from t4) sub6
-- group by 1

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
select customer_id, sum(plus_join_points) as total_points
from( 
select customer_id, join_date, order_date, price, joined, product_name, points, plus_join_points
from(
select customer_id,  join_date, order_date, price, joined, product_name, points, case when (join_date+6)>=(order_date) and (join_date)<=(order_date) then points*2 else points end as plus_join_points
from (
select customer_id, join_date, order_date, price, joined, product_name, case when product_name='sushi' then price*20 else price*10 end as points
from t4) sub6) sub7)sub8
where customer_id in ('A','B')
group by 1