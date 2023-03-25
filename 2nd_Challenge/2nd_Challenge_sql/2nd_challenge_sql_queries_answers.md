## 2nd Challenge (SQL)
#### Case Study #2 - Pizza Runner
Find more info here: https://8weeksqlchallenge.com/case-study-2/

---


## Cleaning Data
*I use MySQL Workbench version 8.0.30*
- #### Overview:

Tables: pizza_names, runners, pizza_toppings --> No need to clean because these are clean already.

Tables: runner_orders, customer_orders, pizza_recipes --> these will be clean in next steps.

by this code I check column type:

```SQL
SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
where TABLE_SCHEMA = 'pizza_runner'
```
- #### Start clening:

Table: runner_orders:
>- Column *pickup_time*:
 - convert the type from *varchar* to *timestamp*.
   1.  replace 'null' with null by updating the table.
 ```SQL
 USE pizza_runner;
SET SQL_SAFE_UPDATES = 0; -- To disable safe update mode.
UPDATE runner_orders SET pickup_time = NULL WHERE pickup_time = 'null';
SET SQL_SAFE_UPDATES = 1; -- To able safe update mode again.
   ```
   2. convert the type from *varchar* to *timestamp*.
   ```SQL
   USE pizza_runner;
Alter table runner_orders MODIFY COLUMN pickup_time TIMESTAMP;
   ```
- Column *duration*:
 - Since the whole column in the minute unit, I will remove the unit.
   1. Creat fuction that leave only numbers:
 ```SQL
use pizza_runner;
drop function if exists LeaveNumber;
delimiter //
create function LeaveNumber(str varchar(50)) returns varchar(50)
no sql
begin
declare verification varchar(50);
declare result varchar(50) default '';
declare _character varchar(2);
declare i integer default 1;
if char_length(str) > 0 then
    while(i <= char_length(str)) do
        set _character = substring(str,i,1);
        set verification = find_in_set(_character,'1,2,3,4,5,6,7,8,9,0,.');
        if verification > 0 then
            set result = concat(result,_character);
        end if;
        set i = i + 1;
    end while;
return result;
else
return '';
end if;
end //
delimiter ;
DELIMITER $$
```
   2. Set the function and Replace ' ' by null:
```SQL
   USE pizza_runner;
SET SQL_SAFE_UPDATES = 0; -- To disable safe update mode.
UPDATE runner_orders SET duration = pizza_runner.LeaveNumber(duration);
UPDATE runner_orders SET duration = NULL WHERE duration = '';
SET SQL_SAFE_UPDATES = 1; -- To able safe update mode again.
```
 - Convert the column type from *varchar* to *int*.
 ```SQL
 USE pizza_runner;
Alter table runner_orders MODIFY COLUMN duration int;
```
- Column *distance*:
 - Since the whole column in the km unit, remove the unit.
 ```SQL
 USE pizza_runner;
 SET SQL_SAFE_UPDATES = 0; -- To disable safe update mode.
 UPDATE runner_orders SET distance = pizza_runner.LeaveNumber(distance);
 UPDATE runner_orders SET distance = NULL WHERE distance = '';
 SET SQL_SAFE_UPDATES = 1; -- To able safe update mode again.
 ```
 - Convert the column type from *varchar* to *float*.
 ```SQL
 USE pizza_runner;
Alter table runner_orders MODIFY COLUMN distance float;
 ```
- Column *cancellation*:
 - Replace all ' ' and "nall" values with "uncancelled" value.
```SQL
USE pizza_runner;
SET SQL_SAFE_UPDATES = 0; -- To disable safe update mode.
UPDATE runner_orders SET cancellation = 'Uncancelled' WHERE cancellation in ('null', '');
UPDATE runner_orders SET cancellation = 'Uncancelled' WHERE cancellation is null;
SET SQL_SAFE_UPDATES = 1; -- To able safe update mode again.
```

Table: customer_orders:
>- Columns *exclusions, extras*:
 - Replace all ' ' and "nall" values with original null values of MySQL.
 ```SQL
USE pizza_runner;
SET SQL_SAFE_UPDATES = 0; -- To disable safe update mode.
UPDATE customer_orders SET exclusions = NULL WHERE exclusions in('','null');
UPDATE customer_orders SET extras = NULL WHERE extras in('','null');
SET SQL_SAFE_UPDATES = 1; -- To able safe update mode.
```

Table: pizza_recipes:
>- Column *toppings*:
  - Separate 'toppings' and convert column type from *varchar* to *int*.
   ```SQL
  use pizza_runner;
 DELIMITER $$ -- This function is to split the statment by commas.
 CREATE FUNCTION strSplit(x VARCHAR(6500), delim VARCHAR(12), pos INTEGER)
 RETURNS VARCHAR(6500)
 DETERMINISTIC
 BEGIN
   DECLARE output VARCHAR(6500);
   SET output = REPLACE(SUBSTRING(SUBSTRING_INDEX(x, delim, pos)
                  , LENGTH(SUBSTRING_INDEX(x, delim, pos - 1)) + 1)
                  , delim
                  , '');
   IF output = '' THEN SET output = null; END IF;
   RETURN output;
 END $$
 DELIMITER ;
 DELIMITER $$ -- This procedure is to apply the previous function many times creating many rows until the commas disappear.
 CREATE PROCEDURE BadTableToGoodTable()
 BEGIN
   DECLARE i INTEGER;
   SET i = 1;
   create table temp(pizza_id int, toppings VARCHAR(100));
   REPEAT
     INSERT INTO temp(pizza_id, toppings)
       SELECT pizza_id, strSplit(toppings, ', ', i) FROM pizza_recipes
       WHERE strSplit(toppings, ', ', i) IS NOT NULL;
     SET i = i + 1;
     UNTIL ROW_COUNT() = 0
   END REPEAT;
   CREATE TABLE pizza_recipes_separated AS (SELECT distinct *
   FROM temp);
   drop table temp;
 END $$
 DELIMITER;
 call BadTableToGoodTable(); -- Usage the stored procedure.
 Alter table pizza_recipes_separated MODIFY COLUMN toppings int; -- Convert column type to int.
```

---

## Answers:
- #### A. Pizza Metrics
1. How many pizzas were ordered?
>```SQL
select count(*) as pizza_counter from customer_orders
>```
| pizza_counter |
|---------------|
| 14            |

2. How many unique customer orders were made?
>```SQL
create view view1 as -- Create view
with customer_orders1 as(select *, count(*) as duplicates
from customer_orders group by 1,2,3,4,5,6) -- To safe duplicates from the 'join' effects.
select c.order_id, c.customer_id, c.pizza_id, c.exclusions, c.extras, c.order_time, c.duplicates, r.runner_id, r.pickup_time, r.distance, r.duration, r.cancellation
from customer_orders1 c
left join runner_orders r on c.order_id=r.order_id
union
select c.order_id, c.customer_id, c.pizza_id, c.exclusions, c.extras, c.order_time, c.duplicates, r.runner_id, r.pickup_time, r.distance, r.duration, r.cancellation
from customer_orders1 c
right join runner_orders r on c.order_id=r.order_id;
select count(distinct order_id) as unique_orders_counter_Uncancelled
from view1
where cancellation='Uncancelled'
>```
| unique_orders_counter_Uncancelled |
|-----------------------|
| 8                     |

3. How many successful orders were delivered by each runner?
>```SQL
select runner_id, count(distinct order_id) as orders_counter
from view1
where cancellation='Uncancelled'
group by 1
>```
| runner_id | orders_counter |
|-----------|---------------|
| 1         | 4             |
| 2         | 3             |
| 3         | 1             |

4. How many of each type of pizza was delivered?
>```SQL
select p.pizza_name, sum(v.duplicates) as pizza_counter -- Remember the 'duplicates' column?
from view1 v
join pizza_names p on v.pizza_id=p.pizza_id
where cancellation='Uncancelled'
group by 1
>```
| pizza_name | pizza_counter |
|------------|---------------|
| Meatlovers | 9             |
| Vegetarian | 3             |

5. How many Vegetarian and Meatlovers were ordered by each customer?
>```SQL
select v.customer_id, p.pizza_name, sum(v.duplicates) as pizza_counter -- Remember the duplicates column?
from view1 v
join pizza_names p on v.pizza_id=p.pizza_id
where cancellation!='Customer Cancellation'
group by 1,2
order by 1
>```
| customer_id | pizza_name | pizza_counter |
|-------------|------------|---------------|
| 101         | Meatlovers | 2             |
| 101         | Vegetarian | 1             |
| 102         | Meatlovers | 2             |
| 102         | Vegetarian | 1             |
| 103         | Meatlovers | 2             |
| 103         | Vegetarian | 1             |
| 104         | Meatlovers | 3             |
| 105         | Vegetarian | 1             |

6. What was the maximum number of pizzas delivered in a single order?
>```SQL
select max(pizza_counter) max_pizza
from (select v.order_id, sum(v.duplicates) as pizza_counter -- Remember the duplicates column?
from view1 v
where cancellation='Uncancelled'
group by 1) sub
>```
| max_pizza |
|-----------|
| 3         |

7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
>```SQL
SELECT
    v.customer_id,
    CASE
        WHEN
            v.extras IS NOT NULL
                OR v.exclusions IS NOT NULL
        THEN
            COUNT(v.customer_id)
    END AS changes,
    CASE
        WHEN
            v.extras IS NULL
                AND v.exclusions IS NULL
        THEN
            COUNT(v.customer_id)
    END AS no_changes -- In the result null means 0
FROM
    view1 v
WHERE
    cancellation = 'Uncancelled'
GROUP BY 1
>```
| customer_id | changes | no_changes |
|-------------|---------|------------|
| 101         |         | 2          |
| 102         |         | 3          |
| 103         | 2       |            |
| 104         | 3       |            |
| 105         | 1       |            |

8. How many pizzas were delivered that had both exclusions and extras?
>```SQL
SELECT COUNT(v.order_id) pizza_counter
FROM
    view1 v
WHERE
    cancellation = 'Uncancelled' and v.extras IS NOT NULL and v.exclusions IS NOT NULL
>```
| pizza_counter |
|---------------|
| 1             |

9. What was the total volume of pizzas ordered for each hour of the day?
>```sql
SELECT
    hour(order_time) AS hour_order,
    COUNT(order_id) pizza_counter
FROM
    view1
GROUP BY 1
ORDER BY 1
>```
| hour_order | pizza_counter |
|------------|---------------|
| 11         | 1             |
| 13         | 2             |
| 18         | 3             |
| 19         | 1             |
| 21         | 3             |
| 23         | 3             |

10. What was the volume of orders for each day of the week?
>```SQL
SELECT
    dayname(order_time) AS day_of_week_order,
    COUNT(order_id) pizza_counter
FROM
    view1
GROUP BY 1
ORDER BY 1
>```
| day_of_week_order | pizza_counter |
|-------------------|---------------|
| Friday            | 1             |
| Saturday          | 4             |
| Thursday          | 3             |
| Wednesday         | 5             |

- #### B. Runner and Customer Experience
1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
>```SQL
SELECT
    WEEK(registration_date) AS _week,
    COUNT(runner_id) AS runners_counter
FROM
    runners
GROUP BY 1
>```
| _week | runners_counter |
|-------|-----------------|
| 0     | 1               |
| 1     | 2               |
| 2     | 1               |

2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
>```SQL
SELECT
    runner_id, AVG(difference) AS avg_minutes_took_to_pickup
FROM
    (SELECT DISTINCT -- There are orders picked up at one time by one runner.
        runner_id,
            order_time,
            pickup_time,
            TIMESTAMPDIFF(MINUTE, order_time, pickup_time) AS difference
    FROM
        view1
    WHERE
        cancellation = 'Uncancelled') sub
GROUP BY 1
>```
| runner_id | avg_minutes_took_to_pickup |
|-----------|----------------------------|
| 1         | 14.0000                    |
| 2         | 19.6667                    |
| 3         | 10.0000                    |

3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
>```SQL
SELECT
    order_id,
    SUM(duplicates) count_orders,
    TIMESTAMPDIFF(MINUTE,
        order_time,
        pickup_time) AS prepare_minutes
FROM
    view1
WHERE
    cancellation = 'Uncancelled'
GROUP BY 1
ORDER BY 2 DESC
>```
Yes, there is a relationship between the number of pizzas and preparing time. From this result I see preparing one pizza takes less time than more pizzas in one order. order_id:8 is an outlier.
| order_id | count_orders | prepare_minutes |
|----------|--------------|-----------------|
| 4        | 3            | 29              |
| 3        | 2            | 21              |
| 10       | 2            | 15              |
| 1        | 1            | 10              |
| 2        | 1            | 10              |
| 5        | 1            | 10              |
| 7        | 1            | 10              |
| 8        | 1            | 20              |

4. What was the average distance travelled for each customer?
>```SQL
SELECT
    customer_id, AVG(distance) AS avg_distance
FROM
    (SELECT DISTINCT
        runner_id, order_id, customer_id, distance
    FROM
        view1) sub
GROUP BY 1
>```
| customer_id | avg_distance       |
|-------------|--------------------|
| 101         | 20                 |
| 102         | 18.399999618530273 |
| 103         | 23.399999618530273 |
| 104         | 10                 |
| 105         | 25                 |

5. What was the difference between the longest and shortest delivery times for all orders?
>```SQL
SELECT
    MAX(duration) - MIN(duration) AS difference_minutes
FROM
    view1
>```
| difference_minutes |
|--------------------|
| 30                 |

6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
>```SQL
SELECT
    sub1.*, sub2.avg_speed_km_per_hour_by_runner
FROM
    (SELECT
        runner_id,
            order_id,
            SUM(duplicates) pizzas_counter,
            distance,
            duration,
            round((60*distance / duration),1) AS speed_km_per_hour
    FROM
        view1
    WHERE
        cancellation = 'Uncancelled'
    GROUP BY 2) sub1
        JOIN
    (SELECT
        runner_id, round(AVG(60*distance / duration),1) AS avg_speed_km_per_hour_by_runner
    FROM
        view1
    WHERE
        cancellation = 'Uncancelled'
    GROUP BY 1) sub2 ON sub1.runner_id = sub2.runner_id
ORDER BY 1
>```
From this result, I do not think there is trend for these values. But runner_id:2 has strange speed with that same distances values, he could has speeding violations.
| runner_id | order_id | pizzas_counter | distance | duration | speed_km_per_hour | avg_speed_km_per_hour_by_runner |
|-----------|----------|----------------|----------|----------|-------------------|---------------------------------|
| 1         | 1        | 1              | 20       | 32       | 37.5              | 47.1                            |
| 1         | 2        | 1              | 20       | 27       | 44.4              | 47.1                            |
| 1         | 3        | 2              | 13.4     | 20       | 40.2              | 47.1                            |
| 1         | 10       | 2              | 10       | 10       | 60                | 47.1                            |
| 2         | 4        | 3              | 23.4     | 40       | 35.1              | 55.9                            |
| 2         | 7        | 1              | 25       | 25       | 60                | 55.9                            |
| 2         | 8        | 1              | 23.4     | 15       | 93.6              | 55.9                            |
| 3         | 5        | 1              | 10       | 15       | 40                | 40                              |

7. What is the successful delivery percentage for each runner?
>```SQL
select runner_id, concat(round(sum(case when cancellation='Uncancelled' then duplicates end )*100/sum(duplicates),1),'%') as percentage
from view1
group by 1
>```
| runner_id | percentage |
|-----------|------------|
| 1         | 100.0%     |
| 2         | 83.3%      |
| 3         | 50.0%      |

- #### C. Ingredient Optimisation
1. What are the standard ingredients for each pizza?
>```SQL
SELECT
    n.pizza_name, GROUP_CONCAT(' ',t.topping_name) AS toppins_recipe -- The space is not important.
FROM
    pizza_names n
        JOIN
    pizza_recipes_separated r ON n.pizza_id = r.pizza_id
        JOIN
    pizza_toppings t ON r.toppings = t.topping_id
GROUP BY 1
>```
| pizza_name | toppins_recipe |
|------------|----------------|
| Meatlovers |  Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| Vegetarian |  Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce |

2. What was the most commonly added extra?
>```SQL
SELECT
    topping_name, COUNT(findings) occurs
FROM
    (SELECT
        order_id,
            t.topping_id,
            t.topping_name,
            v.extras,
            FIND_IN_SET(t.topping_id, REPLACE(v.extras, ' ', '')) findings
    FROM
        view1 v
    JOIN pizza_recipes_separated r ON v.pizza_id = r.pizza_id
    JOIN pizza_toppings t ON r.toppings = t.topping_id
    WHERE
        v.extras IS NOT NULL
    HAVING FIND_IN_SET(t.topping_id, REPLACE(v.extras, ' ', '')) != 0) AS sub
GROUP BY 1
>```
| topping_name | occurs |
|--------------|--------|
| Bacon        | 3      |
| Cheese       | 1      |
| Chicken      | 1      |


3. What was the most common exclusion?
>```SQL
CREATE DEFINER=`root`@`localhost` PROCEDURE `BadTableToGoodTable`()
BEGIN -- Edit the BadTableToGoodTable() procedure.
  DECLARE i INTEGER;
  SET i = 1;
  drop table if exists temp;
  create table temp(order_id int, extras VARCHAR(100));
  REPEAT
    INSERT INTO temp(order_id, extras)
      SELECT order_id, strSplit(extras, ', ', i) FROM customer_orders
      WHERE strSplit(extras, ', ', i) IS NOT NULL;
    SET i = i + 1;
    UNTIL ROW_COUNT() = 0
  END REPEAT;
  drop table if exists separate_extras_from_costomer_orders;
  CREATE TABLE separate_extras_from_costomer_orders AS (SELECT *
  FROM temp);
  drop table temp;
END
SET SQL_SAFE_UPDATES = 0; -- To disable safe update mode.
UPDATE separate_extras_from_costomer_orders SET extras = replace(extras,' ',''); -- Remove spaces before convert column type.
SET SQL_SAFE_UPDATES = 1; -- To able safe update mode again.
Alter table separate_extras_from_costomer_orders MODIFY COLUMN extras int; -- Convert column type to int.
>```
>```SQL
call BadTableToGoodTable(); -- Call it once!!!!!!!!
select topping_name, count(*) extras_counter
from
(
select distinct c.order_id, c.extras as extras1, ce.extras as extras2, t.topping_name
from customer_orders c
join separate_extras_from_costomer_orders ce on c.order_id=ce.order_id and c.extras is not null
join pizza_recipes_separated r on r.toppings=ce.extras
join pizza_toppings t on ce.extras=t.topping_id
where ce.extras=t.topping_id
) as sub
group by 1
>```
| topping_name | extras_counter |
|--------------|----------------|
| Bacon        | 4              |
| Cheese       | 1              |
| Chicken      | 1              |

4. Generate an order item for each record in the customers_orders table in the format of one of the following:
 - Meat Lovers
 - Meat Lovers - Extra Bacon
 - Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
    - Here I indexed records per order_id using *ROW_NUMBER()*, and remove 'duplicates' column. I think this way is better way to safe duplicate records than the 'duplicates' column idea.
    ```SQL
    create view view2 as(
SELECT  c.order_id, ROW_NUMBER() OVER (partition by c.order_id order BY c.order_id) as  index_orders, c.customer_id, c.pizza_id, c.exclusions, c.extras, c.order_time, r.pickup_time, r.distance, r.duration, r.cancellation
FROM customer_orders c
left join runner_orders r on c.order_id=r.order_id
union
SELECT  c.order_id, ROW_NUMBER() OVER (partition by c.order_id order BY c.order_id) as  index_orders, c.customer_id, c.pizza_id, c.exclusions, c.extras, c.order_time, r.pickup_time, r.distance, r.duration, r.cancellation
FROM customer_orders c
right join runner_orders r on c.order_id=r.order_id)
```
    - Also, I separated *exclusions* column using stored procedure:
    ```SQL
    CREATE DEFINER=`root`@`localhost` PROCEDURE `BadTableToGoodTable`()
BEGIN
  DECLARE i INTEGER;
  SET i = 1;
  drop table if exists temp;
  create table temp(order_id int,index_orders int,exclusions VARCHAR(100));
  REPEAT
    INSERT INTO temp(order_id,index_orders,exclusions)
      SELECT order_id, index_orders, strSplit(exclusions, ', ', i) FROM view2
      WHERE strSplit(exclusions, ', ', i) IS NOT NULL;
    SET i = i + 1;
    UNTIL ROW_COUNT() = 0
  END REPEAT;
  drop table if exists separate_exclusions_from_view2;
  CREATE TABLE separate_exclusions_from_view2 AS (SELECT *
  FROM temp);
  drop table temp;
  Alter table separate_exclusions_from_view2 MODIFY COLUMN exclusions int; -- Convert type to int
END -- And then call it by -- call pizza_runner.BadTableToGoodTable();
```

 >```SQL
 with t1 as (select order_id, index_orders, GROUP_CONCAT(extras_names) as extras_names from (select distinct v.order_id, v.index_orders ,st.extras,pt.topping_name as extras_names
 from view2 v
 join pizza_names pn on v.pizza_id=pn.pizza_id
 join pizza_recipes_separated ps on v.pizza_id=ps.pizza_id
 left join separate_extras_from_view2 st on v.order_id=st.order_id and v.index_orders=st.index_orders
 join pizza_toppings pt on st.extras=pt.topping_id
 where  st.extras is not null
 order by 1) sub1 group by 1,2),
 t2 as (select order_id, index_orders,GROUP_CONCAT(exclusions_names) as exclusions_names from (select distinct v.order_id, v.index_orders, sc.exclusions,pt.topping_name as exclusions_names
 from view2 v
 join pizza_names pn on v.pizza_id=pn.pizza_id
 join pizza_recipes_separated ps on v.pizza_id=ps.pizza_id
 left join separate_exclusions_from_view2 sc on v.order_id=sc.order_id and v.index_orders=sc.index_orders
 left join pizza_toppings pt on sc.exclusions=pt.topping_id
 where  sc.exclusions is not null
 order by 1)as sub2 group by 1,2)
 select distinct v.order_id, v.index_orders, v.customer_id, v.pizza_id, concat(pn.pizza_name, case when t1.extras_names is null and t2.exclusions_names is null then '' else ':' end,ifnull(concat(' + Extra: ',t1.extras_names,'. '), ''),ifnull(concat(' - Exclude: ',t2.exclusions_names,'. '), '')) as order_item,v.order_time
 from view2 v
 join pizza_names pn on v.pizza_id=pn.pizza_id
 join pizza_recipes_separated ps on v.pizza_id=ps.pizza_id
 join pizza_toppings pt on ps.toppings = pt.topping_id
 left join t1 on v.order_id=t1.order_id and v.index_orders=t1.index_orders
 left join t2 on v.order_id=t2.order_id and v.index_orders=t2.index_orders
 order by 1
 >```
 | order_id | index_orders | customer_id | pizza_id | order_item                                                          | order_time          |
|----------|--------------|-------------|----------|---------------------------------------------------------------------|---------------------|
| 1        | 1            | 101         | 1        | Meatlovers                                                          | 2020-01-01 18:05:02 |
| 2        | 1            | 101         | 1        | Meatlovers                                                          | 2020-01-01 19:00:52 |
| 3        | 1            | 102         | 1        | Meatlovers                                                          | 2020-01-02 23:51:23 |
| 3        | 2            | 102         | 2        | Vegetarian                                                          | 2020-01-02 23:51:23 |
| 4        | 1            | 103         | 1        | Meatlovers: - Exclude: Cheese.                                      | 2020-01-04 13:23:46 |
| 4        | 2            | 103         | 1        | Meatlovers: - Exclude: Cheese.                                      | 2020-01-04 13:23:46 |
| 4        | 3            | 103         | 2        | Vegetarian: - Exclude: Cheese.                                      | 2020-01-04 13:23:46 |
| 5        | 1            | 104         | 1        | Meatlovers: + Extra: Bacon.                                         | 2020-01-08 21:00:29 |
| 6        | 1            | 101         | 2        | Vegetarian                                                          | 2020-01-08 21:03:13 |
| 7        | 1            | 105         | 2        | Vegetarian: + Extra: Bacon.                                         | 2020-01-08 21:20:29 |
| 8        | 1            | 102         | 1        | Meatlovers                                                          | 2020-01-09 23:54:33 |
| 9        | 1            | 103         | 1        | Meatlovers: + Extra: Chicken,Bacon.  - Exclude: Cheese.             | 2020-01-10 11:22:59 |
| 10       | 1            | 104         | 1        | Meatlovers                                                          | 2020-01-11 18:34:49 |
| 10       | 2            | 104         | 1        | Meatlovers: + Extra: Cheese,Bacon.  - Exclude: Mushrooms,BBQ Sauce. | 2020-01-11 18:34:49 |

5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
 - For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
>```SQL
with t1 as (
select distinct c1.id, c1.order_id, pn.pizza_name, c1.pizza_id, pt.topping_name, pt.topping_id , case when pt.topping_id in (select extras from separate_extras_from_c1 where id=c1.id) then'2x' else '' end as doupled-- ,case when cc1.exclusions=pt.topping_id then'0x'end,case when tc1.extras=pt.topping_id then tc1.extras end
from customer_orders1 c1
join pizza_names pn on c1.pizza_id=pn.pizza_id
join pizza_recipes_separated ps on c1.pizza_id=ps.pizza_id
left join separate_extras_from_c1 tc1 on c1.id=tc1.id
left join separate_exclusions_from_c1 cc1 on c1.id=cc1.id
join pizza_toppings pt on (ps.toppings=pt.topping_id or pt.topping_id=tc1.extras)
where (pt.topping_id not in (select exclusions from separate_exclusions_from_c1 where id=c1.id)) -- Delete exclusions.
order by 1,5 )
select id as row_number_, order_id, pizza_id,  replace(concat(pizza_name,': ',group_concat(concat(doupled,topping_name)),'.'),',','\\') as ingredient -- Replace ',' to '\\' does not matter.
from t1
group by 1,2,3
order by 1
>```
| row_number_ | order_id | pizza_id | ingredient                                                                    |
|-------------|----------|----------|-------------------------------------------------------------------------------|
| 1           | 1        | 1        | Meatlovers: Bacon\BBQ Sauce\Beef\Cheese\Chicken\Mushrooms\Pepperoni\Salami.   |
| 2           | 2        | 1        | Meatlovers: Bacon\BBQ Sauce\Beef\Cheese\Chicken\Mushrooms\Pepperoni\Salami.   |
| 3           | 3        | 1        | Meatlovers: Bacon\BBQ Sauce\Beef\Cheese\Chicken\Mushrooms\Pepperoni\Salami.   |
| 4           | 3        | 2        | Vegetarian: Cheese\Mushrooms\Onions\Peppers\Tomato Sauce\Tomatoes.            |
| 5           | 4        | 1        | Meatlovers: Bacon\BBQ Sauce\Beef\Chicken\Mushrooms\Pepperoni\Salami.          |
| 6           | 4        | 1        | Meatlovers: Bacon\BBQ Sauce\Beef\Chicken\Mushrooms\Pepperoni\Salami.          |
| 7           | 4        | 2        | Vegetarian: Mushrooms\Onions\Peppers\Tomato Sauce\Tomatoes.                   |
| 8           | 5        | 1        | Meatlovers: 2xBacon\BBQ Sauce\Beef\Cheese\Chicken\Mushrooms\Pepperoni\Salami. |
| 9           | 6        | 2        | Vegetarian: Cheese\Mushrooms\Onions\Peppers\Tomato Sauce\Tomatoes.            |
| 10          | 7        | 2        | Vegetarian: 2xBacon\Cheese\Mushrooms\Onions\Peppers\Tomato Sauce\Tomatoes.    |
| 11          | 8        | 1        | Meatlovers: Bacon\BBQ Sauce\Beef\Cheese\Chicken\Mushrooms\Pepperoni\Salami.   |
| 12          | 9        | 1        | Meatlovers: 2xBacon\BBQ Sauce\Beef\2xChicken\Mushrooms\Pepperoni\Salami.      |
| 13          | 10       | 1        | Meatlovers: Bacon\BBQ Sauce\Beef\Cheese\Chicken\Mushrooms\Pepperoni\Salami.   |
| 14          | 10       | 1        | Meatlovers: 2xBacon\Beef\2xCheese\Chicken\Pepperoni\Salami.                   |


6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
>```SQL
with t1 as (
select distinct c1.id,r.cancellation, c1.order_id, pn.pizza_name, c1.pizza_id, pt.topping_name, pt.topping_id , case when pt.topping_id in (select extras from separate_extras_from_c1 where id=c1.id) then'2x' else '' end as doupled
from customer_orders1 c1
join runner_orders r on c1.order_id=r.order_id
join pizza_names pn on c1.pizza_id=pn.pizza_id
join pizza_recipes_separated ps on c1.pizza_id=ps.pizza_id
left join separate_extras_from_c1 tc1 on c1.id=tc1.id
left join separate_exclusions_from_c1 cc1 on c1.id=cc1.id
join pizza_toppings pt on (ps.toppings=pt.topping_id or pt.topping_id=tc1.extras)
where (pt.topping_id not in (select exclusions from separate_exclusions_from_c1 where id=c1.id))
order by 1,5 )
select topping_name, count(*) as occurs
from t1
where cancellation='Uncancelled'
group by 1
order by 2 desc
>```
| topping_name | occurs |
|--------------|--------|
| Mushrooms    | 11     |
| Bacon        | 10     |
| Pepperoni    | 9      |
| Chicken      | 9      |
| Beef         | 9      |
| Cheese       | 9      |
| Salami       | 9      |
| BBQ Sauce    | 8      |
| Onions       | 3      |
| Peppers      | 3      |
| Tomatoes     | 3      |
| Tomato Sauce | 3      |

- #### D. Pricing and Ratings
1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
>```SQL
SELECT
    SUM(cost) revenues
FROM
    (SELECT
        order_id,
            index_orders,
            CASE
                WHEN pizza_id = 1 THEN 12
                WHEN pizza_id = 2 THEN 10
            END cost
    FROM
        view2
    WHERE
        cancellation = 'Uncancelled') AS sub
>```
| revenues |
|----------|
| 138      |

2. What if there was an additional $1 charge for any pizza extras?
 - Add cheese is $1 extra

 >```SQL
SELECT
    SUM(cost_with_extras_charge) revenues
FROM
    (SELECT
        id,
            order_id,
            extras,
            CASE
                WHEN extras IS NOT NULL THEN cost + 1
                ELSE cost
            END AS cost_with_extras_charge
    FROM
        (SELECT
        c1.id,
            c1.order_id,
            ct1.extras,
            CASE
                WHEN c1.pizza_id = 1 THEN 12
                WHEN c1.pizza_id = 2 THEN 10
            END cost
    FROM
        customer_orders1 c1
    LEFT JOIN runner_orders r ON c1.order_id = r.order_id
    LEFT JOIN separate_extras_from_c1 ct1 ON c1.id = ct1.id
    WHERE
        cancellation = 'Uncancelled') AS sub1) AS sub2
 >```
| revenues |
|----------|
| 154      |

3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
 - First, I created a new table, then created a procedure to insert the fake ratings into it.
 >```SQL
 create table if not exists customer_ratings (select v.order_id,v.index_orders,v.customer_id,r.runner_id
from view2 v
left join runner_orders r on v.order_id=r.order_id
where r.cancellation='Uncancelled');
ALTER TABLE customer_ratings
ADD COLUMN rating_order int(1),
ADD COLUMN rating_runner int(1),
ADD COLUMN average_rate float,
ADD COLUMN comment_ varchar(100);
DELIMITER //
create procedure customer_rates_order_and_runner(in order_id_A int(2), in customer_id_A int(3),in f_rating_order int(1),in f_rating_runner int(1),in f_comment varchar(100))
begin
SET SQL_SAFE_UPDATES = 0;
UPDATE customer_ratings SET rating_order=f_rating_order where customer_id=customer_id_A and order_id=order_id_A and f_rating_order in (1,2,3,4,5);
UPDATE customer_ratings SET rating_runner=f_rating_runner where customer_id=customer_id_A and order_id=order_id_A and f_rating_runner in (1,2,3,4,5);
UPDATE customer_ratings SET comment_=f_comment where customer_id=customer_id_A and order_id=order_id_A;
UPDATE customer_ratings SET average_rate=round(((rating_order+rating_runner)/2),1) where customer_id=customer_id_A and order_id=order_id_A;
SET SQL_SAFE_UPDATES = 1;
select * from customer_ratings;
end;
// DELIMITER
call customer_rates_order_and_runner (1,101,5,5,'good'); -- Usage the stored procedure. This is an example.
>```
Then this is the output of my fake records:
| order_id | index_orders | customer_id | runner_id | rating_order | rating_runner | average_rate | comment_                                                         |
|----------|--------------|-------------|-----------|--------------|---------------|--------------|------------------------------------------------------------------|
| 1        | 1            | 101         | 1         | 5            | 5             | 5            | good                                                             |
| 2        | 1            | 101         | 1         | 5            | 5             | 5            | very good                                                        |
| 3        | 1            | 102         | 1         | 5            | 5             | 5            |                                                                  |
| 3        | 2            | 102         | 1         | 5            | 5             | 5            |                                                                  |
| 4        | 1            | 103         | 2         | 1            | 1             | 1            | the pizza is cold, and arrived late. never order from here again |
| 4        | 2            | 103         | 2         | 1            | 1             | 1            | the pizza is cold, and arrived late. never order from here again |
| 4        | 3            | 103         | 2         | 1            | 1             | 1            | the pizza is cold, and arrived late. never order from here again |
| 5        | 1            | 104         | 3         | 5            | 5             | 5            |                                                                  |
| 7        | 1            | 105         | 2         | 4            | 5             | 4.5          | ok                                                               |
| 8        | 1            | 102         | 2         | 5            | 5             | 5            | delicious and fast!                                              |
| 10       | 1            | 104         | 1         | 1            | 5             | 3            | there is BBQ Sauce which i asked to exclude it!!!!!!!!           |
| 10       | 2            | 104         | 1         | 1            | 5             | 3            | there is BBQ Sauce which i asked to exclude it!!!!!!!!           |

4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
 - *customer_id, order_id, runner_id, rating, order_time, pickup_time,* Time between order and pickup, Delivery duration, Average speed, Total number of pizzas.

 >```SQL
select *,  count(*) as total_number_of_pizzas
from (
select distinct c.order_id,c.customer_id, c.index_orders, r.runner_id, cr.average_rate as average_rating, c.order_time, r.pickup_time,
TIMESTAMPDIFF(MINUTE,c.order_time,r.pickup_time) as prepare_minutes, r.duration as delivery_duration, round((60*r.distance / r.duration),1) AS speed_km_per_hour
from view2 c
left join runner_orders r on c.order_id=r.order_id
left join customer_ratings cr on c.order_id=cr.order_id
where r.cancellation='Uncancelled'
order by 1) as sub
group by 1
 >```
| order_id | customer_id | index_orders | runner_id | average_rating | order_time          | pickup_time         | prepare_minutes | delivery_duration | speed_km_per_hour | total_number_of_pizzas |
|----------|-------------|--------------|-----------|----------------|---------------------|---------------------|-----------------|-------------------|-------------------|------------------------|
| 1        | 101         | 1            | 1         | 5              | 2020-01-01 18:05:02 | 2020-01-01 18:15:34 | 10              | 32                | 37.5              | 1                      |
| 2        | 101         | 1            | 1         | 5              | 2020-01-01 19:00:52 | 2020-01-01 19:10:54 | 10              | 27                | 44.4              | 1                      |
| 3        | 102         | 1            | 1         | 5              | 2020-01-02 23:51:23 | 2020-01-03 00:12:37 | 21              | 20                | 40.2              | 2                      |
| 4        | 103         | 1            | 2         | 1              | 2020-01-04 13:23:46 | 2020-01-04 13:53:03 | 29              | 40                | 35.1              | 3                      |
| 5        | 104         | 1            | 3         | 5              | 2020-01-08 21:00:29 | 2020-01-08 21:10:57 | 10              | 15                | 40                | 1                      |
| 7        | 105         | 1            | 2         | 4.5            | 2020-01-08 21:20:29 | 2020-01-08 21:30:45 | 10              | 25                | 60                | 1                      |
| 8        | 102         | 1            | 2         | 5              | 2020-01-09 23:54:33 | 2020-01-10 00:15:02 | 20              | 15                | 93.6              | 1                      |
| 10       | 104         | 1            | 1         | 3              | 2020-01-11 18:34:49 | 2020-01-11 18:50:20 | 15              | 10                | 60                | 2                      |


5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
>```SQL
select round(sum(pizza_cost)- sum(distance*0.3),2) as profit,sum(pizza_cost) as revenues, round(sum(distance*0.3),2) as travele_cost  -- 'travele_cost' i do the summation per order not per pizza
from(
SELECT  distinct c.order_id, c.index_orders, r.runner_id, sum(CASE WHEN pizza_id = 1 THEN 12 WHEN pizza_id = 2 THEN 10 END) as pizza_cost, r.distance
from view2 c
left join runner_orders r on c.order_id=r.order_id
WHERE r.cancellation = 'Uncancelled'
group by 1) AS sub1
>```
| profit | revenues | travele_cost |
|--------|----------|--------------|
| 94.44  | 138      | 43.56        |

- #### E. Bonus Questions

---

### References:
##### links and "How to...":
- How to check column type in sql: https://datatofish.com/data-type-columns-sql-server/#:~:text=You%20can%20use%20the%20following%20query%20to%20get,in%20a%20particular%20table%3B%20for%20a%20specific%20column
- How to add tables to markdown: https://tableconvert.com/csv-to-markdown
- Good cheatsheat of markdown: https://www.markdown-cheatsheet.com/
- How to replace a value with null: https://stackoverflow.com/questions/12324931/replace-0-with-null-in-mysql
- How to convert column type in sql: https://stackoverflow.com/questions/4611965/change-a-mysql-column-datatype-from-text-to-timestamp
- Create function that leave only numbers: https://stackoverflow.com/questions/5146292/how-to-replace-non-numeric-characters-in-mysql
- How to split commas into rows: https://stackoverflow.com/questions/6152137/mysql-string-split/6153288#6153288
- How to rename table: https://popsql.com/learn-sql/mysql/how-to-rename-a-table-in-mysql
- How to count by hour: https://stackoverflow.com/questions/6272957/mysql-query-for-obtaining-count-per-hour
- Mysql WEEKDAY() vs Mysql DayofWeek(): https://stackoverflow.com/questions/47589759/mysql-weekday-vs-mysql-dayofweek
- How to calculate the difference in minutes: https://learnsql.com/cookbook/how-to-calculate-the-difference-between-two-timestamps-in-mysql/#:~:text=To%20calculate%20the%20difference%20between%20the%20timestamps%20in,seconds%20as%20we%20have%20done%20here%2C%20choose%20SECOND
- How to calculate average speed: https://www.wikihow.com/Calculate-Average-Speed
- How to sum by condition: https://stackoverflow.com/questions/8732036/mysql-sum-query-with-if-condition
- How to add % sign: https://www.tutorialspoint.com/add-a-percentage-sign-at-the-end-to-each-value-while-using-mysql-select-statement#:~:text=To%20add%20percentage%20sign%20at%20the%20end%2C%20use,records%20in%20the%20table%20using%20insert%20command%20%E2%88%92
- How to group strings: https://stackoverflow.com/questions/19558443/comma-separated-string-of-selected-values-in-mysql
- How to remove spaces: https://stackoverflow.com/questions/7313803/mysql-remove-all-whitespaces-from-the-entire-column
- Hoe to index by column: https://stackoverflow.com/questions/1895110/row-number-in-mysql
- How to use concat() with nulls: https://stackoverflow.com/questions/8233746/concatenate-with-null-values-in-sql
- How to add 2x:https://github.com/AlysterF/8week-SQL-challenge/blob/main/Case%20Study%20%232%20-%20Pizza%20Runner/C%20-%20Ingredient%20Optimisation.md Q:b.5
##### Solved errors:
- error code: 1175: https://stackoverflow.com/questions/11448068/mysql-error-code-1175-during-update-in-mysql-workbench
- error 1418: https://stackoverflow.com/questions/61205382/mysql-how-to-fix-function-creation-error-1418
-
