use credit_card;

select * from credit_card_trans



select MIN(transaction_date) as old_date, MAX(transaction_date) as latest_date from credit_card; --10/2013-05/2015

select distinct card_type from credit_card;--- card type: silver, signature, gold, platinum

select count(distinct city) from credit_card; -- multiple city --986

select distinct exp_type from credit_card;  --expense type: Entertainment, food, bills, fuel, travel, grocery

/ --Q1) Write a query to print top 5 cities with highest spends and their percentage
--n contribution of total credit card spends.

with cte1 as (
select city, SUM(amount) as highest_spend from credit_card_trans
group by city),
tota_spent as (select SUM(cast(amount as bigint)) as total_amount from credit_card_trans
)
select top 5 cte1.*, round(highest_spend*1.0/total_amount*100,2) as Percentge from cte1, tota_spent
order by  highest_spend desc;

--Q2) write a query to print highest spend month and amount spent in that month 
--for each card type?


with cte as(
select card_type, datepart(year,transaction_date) as yt,datepart(month,transaction_date) as months, SUM(amount)as total_spend
from credit_card_trans
group by card_type,datepart(year,transaction_date),
datepart(MONTH,transaction_date)

)
select * from (select * ,RANK() over (partition by card_type order by total_spend desc) as rn
from cte) a where rn=1

-- Q3) write a query to print the transaction details(all columns from the table)
--for each card type when it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type) 

with cte as(
select *,SUM(amount) over (Partition by card_type order by transaction_date, transaction_id asc)
as cumulative_sum from credit_card_trans
) 
select * from ( select *, RANK() over (partition by card_type 
order by cumulative_sum asc) as rn from cte where cumulative_sum > 1000000) a
where rn=1
 
--Q4) write a query to find city which had lowest percentage spend for
--gold card type

with cte as(
select city, card_type, sum(amount) as amount, 
SUM(case when card_type='Gold' then amount else 0 end) as Gold_amount
from credit_card_trans
group by city, card_type
)
select city,SUM(gold_amount)*1.0/ SUM(amount) as gold_ratio
from cte
group by city
having SUM(Gold_amount) is not null
order by gold_ratio
;

--Q5) write a query to print 3 columns:  city, highest_expense_type ,
--lowest_expense_type (example format : Delhi , bills, Fuel)

with cte as(

select city, exp_type, SUM(amount) as total_amount from credit_card_trans
group by city, exp_type                                                       -------First step
) 
select
city, min(case when rn_desc=1 then exp_type end) as highest_exp_type,
max(case when rn_asc=1 then exp_type end) as lowest_exp_type                  -------- Third step
from
(Select *
,RANK() over (partition by city order by total_amount desc) as rn_desc        --------- Second step
,RANK() over (partition by city order by total_amount asc) as rn_asc 
from cte) A
group by city
 

 --Q6) write a query to find percentage contribution of spends by 
 --females for each expense type 

 
 select exp_type, 
 sum(case when gender='F' then amount else 0 end)*1.0/SUM(amount)*100 as 
 percent_contri from credit_card_trans
 group by exp_type
 order by Percent_Contri desc;

 -------I tried below---------

 WITH cte AS (
    SELECT exp_type,
           SUM(amount) AS total_amount
    FROM credit_card_trans
    WHERE gender = 'F'
    GROUP BY exp_type
),
total_expenses AS (
    SELECT exp_type,
           SUM(amount) AS total_amount1
    FROM credit_card_trans
	GROUP BY exp_type
	)
	Select * from (select cte.exp_type, total_amount*1.0/total_amount1 as Percent_cont from cte, total_expenses group by exp_typem ) b
	group by exp_type,Percent_cont
	order by Percent_cont desc;

 --Q7)  which card and expense type combination saw highest month over
 --month growth percent in Jan-2014 ?

  with cte as(
 select card_type, exp_type, DATEPART(YEAR,transaction_date) YT, DATEPART(month,transaction_date) MT,  SUM(amount) as total_spent
 from credit_card_trans
 group by card_type, exp_type, DATEPART(YEAR,transaction_date), DATEPART(month,transaction_date)
 )
 select top 1*, (total_spent-prev_month_spent)*1.0/prev_month_spent*100 as mom_growth
 from(
 select *, lag(total_spent,1) over (partition by card_type, exp_type order by yt, mt) as Prev_month_spent
 from cte) b
where prev_month_spent is not null and YT=2014 and MT=1
order by mom_growth desc

--Q8) During weekends which city has highest total spend to total no of transcations
--ratio 

select top 1 city,  
SUM(amount)*1.0/COUNT(transaction_id) as Transaction_ratio
from credit_card_trans
where DATEPART(weekday,transaction_date) in (1,7)
group by city
order by Transaction_ratio desc

--Q9) which city took least number of days to reach its 500th transaction
--after the first transaction in that city?

with cte as(
select *, ROW_NUMBER() over (partition by city order by transaction_date,transaction_id)
as rn
from credit_card_trans
)
select top 1 city, datediff(day,MIN(transaction_date), MAX(transaction_date)) as date_diff
from cte
where rn=1 or rn=500
group by city
having COUNT(1)=2  -- Count(1)  means city and (=2) means it will have two rows.
order by date_diff 


