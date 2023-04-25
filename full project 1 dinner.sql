# What is the total amount each customer spent at the restaurant?
select s.customer_id , sum(m.price)
from menu as m
join sales as s
on m.product_id = s.product_id
group by s.customer_id ;


# How many days has each customer visited the restaurant?
with cte1 as(select * , day(order_date) as days 
from sales)
select customer_id , count(distinct days) as total_days
from cte1
group by customer_id ;


# What was the first item from the menu purchased by each customer?
with cte1 as
(select m.product_name,m.price,s.customer_id,s.order_date,s.product_id , 
dense_rank() over (partition by customer_id order by order_date asc) as ranks
from sales as s 
join menu as m
on m.product_id = s.product_id) 
select customer_id, product_name
from cte1
where ranks = 1
group by customer_id,product_id ;


# What is the most purchased item on the menu and how many times was it purchased by all customers?
select m.product_name,count(*) as number_of_times_purchased
from sales as s
join menu as m
on m.product_id=s.product_id
group by m.product_name
order by number_of_times_purchased desc limit 1 ;


# how many times a product purchased by each customer ?
select m.product_name,s.customer_id ,count(*) as number_of_times_purchased
from sales as s
join menu as m
on m.product_id=s.product_id
group by m.product_name ,s.customer_id
order by s.customer_id, number_of_times_purchased desc ;


# What is the most purchased item on the menu and how many times was it purchased by each customer?
with cte1 as(select m.product_name,m.price,s.customer_id,s.order_date,s.product_id ,
dense_rank() over(order by s.product_id desc) as ranks
from sales as s 
join menu as m
on m.product_id = s.product_id),
cte2 as (select product_id,count(*) from cte1 group by product_id ) 
select product_name,customer_id,count(*)
from cte1
where ranks=1
group by PRODUCT_NAME,customer_id ;


# Which item was the most popular for each customer?
with cte1 as(
select m.product_name,s.customer_id,count(*) as total_units
from sales as s 
join menu as m
on m.product_id = s.product_id
group by s.customer_id , m.product_name) ,
cte2 as(
select * , dense_rank() over (partition by customer_id order by total_units desc) as ranks
from cte1)
select customer_id,product_name,total_units
 from cte2 
 where ranks =1 ;
 
 
# Which item was purchased first by the customer after they became a member?
#select s.customer_id, me.product_name,s.order_date,m.join_date
#from sales as s
#join members as m
#on m.customer_id = s.customer_id
#join menu as me
#on me.product_id = s.product_id
#where s.order_date >= m.join_date 
#group by s.customer_id, me.product_name,s.order_date,m.join_date
#order by s.order_date desc ;


# Which item was purchased first by the customer after they became a member?
# ALTERNATIVE WAY--
with cte1 as(
select me.product_name,me.price,s.customer_id,s.order_date,s.product_id,m.join_date ,
 dense_rank() over(partition by s.customer_id order by s.order_date asc) as ranks
from sales as s
join members as m
on m.customer_id = s.customer_id
join menu as me
on me.product_id = s.product_id
where s.order_date >= m.join_date)
select customer_id,product_name , order_date , join_date
from cte1 where ranks =1; 


# Which item was purchased just before the customer became a member?
with cte1 as(
select me.product_name,me.price,s.customer_id,s.order_date,s.product_id,m.join_date ,
 dense_rank() over(partition by s.customer_id order by s.order_date desc) as ranks
from sales as s
join members as m
on m.customer_id = s.customer_id
join menu as me
on me.product_id = s.product_id
where s.order_date <= m.join_date)
select  customer_id,product_name , order_date , join_date
from cte1
 where ranks =1; 


# What is the total items and amount spent for each member before they became a member including the date they joined?
with cte1 as(
select me.product_name,me.price,s.customer_id,s.order_date,s.product_id,m.join_date ,
 dense_rank() over(partition by s.customer_id order by s.order_date desc) as ranks
from sales as s
join members as m
on m.customer_id = s.customer_id
join menu as me
on me.product_id = s.product_id
where s.order_date <= m.join_date)
select customer_id ,sum(price) ,count(*)
# customer_id,product_name , order_date , join_date
from cte1
group by customer_id ;

# What is the total items and amount spent for each member before they became a member?
with cte1 as(
select me.product_name,me.price,s.customer_id,s.order_date,s.product_id,m.join_date ,
 dense_rank() over(partition by s.customer_id order by s.order_date desc) as ranks
from sales as s
join members as m
on m.customer_id = s.customer_id
join menu as me
on me.product_id = s.product_id
where s.order_date < m.join_date)
select customer_id ,sum(price) ,count(*)
# customer_id,product_name , order_date , join_date
from cte1
group by customer_id ;
# where ranks =1


# If each $1 spent equates to 10 points and sushi has a 2x points multiplier
# - how many points would each customer have?
with cte1 as(
select m.product_name,m.price,s.customer_id,s.order_date,s.product_id ,
case when m.product_name in ('curry' , 'ramen') then price * 10
	 when m.product_name like 'sushi' then price * 10 * 2
end as points
from sales as s
join menu as m
on s.product_id = m.product_id)
select customer_id , sum(points)
from cte1
group by customer_id ;


# In the first week after a customer joins the program (including their join date) they earn 
#2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
with cte1 as(
select me.product_name,me.price,s.customer_id,s.order_date,s.product_id,m.join_date , date_add(join_date,INTERVAL 6 DAY) as 1st_week 
from sales as s
join members as m
on m.customer_id = s.customer_id
join menu as me
on me.product_id = s.product_id) ,
# where order_date between join_date and 1st_week
cte2 as(
select * , case when order_date between join_date and 1st_week then price*10*2
		when order_date not between join_date and 1st_week and product_name like 'sushi' then price*10*2
        when order_date not between join_date and 1st_week and product_name like 'curry' then price*10
        when order_date not between join_date and 1st_week and product_name like 'ramen' then price*10
end as points
from cte1)
select customer_id,sum(points) as total_points
from cte2
where MONTH(order_date) = 1
group by customer_id ;