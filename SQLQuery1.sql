  select * from credit_card_transcactions


--Ques 1: Write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

  select city, total_spent, round( 100.0*(total_spent/total) , 2) as Percentage from
  (select top 5 city, sum(amount) as total_spent from credit_card_transcactions
  group by city
  order by sum(amount) desc ) A
  inner join 
  (select sum(amount) as total from credit_card_transcactions) B on 1=1

--Ques 2: Write a query to print highest spend month and amount spent in that month for each card type

 with highest_spend_month as
  (select top 1 datepart(month, transaction_date) as mnth, sum(amount) as total_spend 
  from credit_card_transcactions 
  group by datepart(month, transaction_date)
  order by sum(amount) desc) 
  ,

  month_card_type_spend as 
  (select datepart(month, transaction_date) as mnth, card_type, sum(amount) as t_amount
  from credit_card_transcactions
  group by datepart(month, transaction_date), card_type)
  

  select B.mnth, B.card_type, B.t_amount
  from highest_spend_month A
  inner join month_card_type_spend B on A.mnth=B.mnth

/*Ques 3:  Write a query to print the transaction details(all columns from the table) for each card type when it
             reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type) */

  
  with running_sum as (
  select *,sum(amount) over(partition by card_type order by transaction_date,transaction_id) as total_spend
  from credit_card_transcactions
  )
  select * from (select *, rank() over(partition by card_type order by total_spend) as rn  
  from running_sum where total_spend >= 1000000) a where rn=1

-- Ques 4:  Write a query to find city which had lowest percentage spend for gold card type\

  with city_gold_spend as
  (select city, card_type, sum(amount) as t_amount
  from credit_card_transcactions
  where card_type='Gold'
  group by city, card_type)

  select top 1 city from
  (select *, A.t_amount/B.total_spend as ratio from
  (select * from city_gold_spend) A
  inner join
  (select sum(t_amount) total_spend from 
  city_gold_spend) B on 1=1
  ) C
  order by ratio

--Ques 5: write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

  with city_wise_highest_expense as 
  (select city,max(t_amount) as maximum from
  (select city, exp_type, sum(amount) as t_amount
  from credit_card_transcactions
  group by city, exp_type) E
  group by city)

, city_exp_type_amount_spend as 
  (select city, exp_type, sum(amount) as t_amount
  from credit_card_transcactions
  group by city, exp_type)
  
, city_wise_lowest_expense as
  (select city, min(t_amount) as minimum from
  (select city, exp_type, sum(amount) as t_amount
  from credit_card_transcactions
  group by city, exp_type) D
  group by city)

  select X.city, X.highest_expense_type, Y.lowest_expense_type from
  (select A.city, B.exp_type as highest_expense_type from city_wise_highest_expense A 
  inner join city_exp_type_amount_spend B 
  on A.city=B.city and B.t_amount=A.maximum ) X
  inner join
  (select C.city, B.exp_type as lowest_expense_type from city_wise_lowest_expense C
  inner join city_exp_type_amount_spend B 
  on C.city=B.city and B.t_amount=C.minimum) Y
  on X.city=Y.city
  order by X.city

-- Ques 6: Write a query to find percentage contribution of spends by females for each expense type

  select A.exp_type, round(100.0*t_amount/total,2) as female_percent_contribution from
  (select exp_type, gender, sum(amount) as t_amount
  from credit_card_transcactions
  group by exp_type, gender
  ) A
  inner join
  (select exp_type,sum(t_amount) as total from
  (select exp_type, gender, sum(amount) as t_amount
  from credit_card_transcactions
  group by exp_type, gender
  )A
  group by exp_type) B
  on A.exp_type=B.exp_type
  where A.gender='F'

-- Ques 7: Which card and expense type combination saw highest month over month growth in Jan-2014

 with mom_growth_Jan_2014 as
  (select * , round(100.0*t_amount/lag_amount,2) as ratio from
  (select *, lag(t_amount,1) over(order by card_type, exp_type, yr, mnth) as lag_amount from 
  (select card_type, exp_type, datepart(month, transaction_date) as mnth, datepart(year, transaction_date) as yr, sum(amount) as t_amount
  from credit_card_transcactions
  group by card_type, exp_type, datepart(month, transaction_date) , datepart(year, transaction_date)
   ) A) B
  where mnth=1 and yr=2014)
, card_wise_max_growth as
  (select card_type, max(ratio) as maximum
  from mom_growth_Jan_2014
  group by card_type)

  select A.card_type, A.exp_type from 
  mom_growth_Jan_2014 A inner join
  card_wise_max_growth B on A.card_type=B.card_type and A.ratio=B.maximum

-- Ques 8: During weekends which city has highest total spend to total no of transcations ratio 

 select top 1 city from
 (select city, round(t_amount/No_of_transactions,2) as ratio from
 (select city, sum(amount) as t_amount, count(*) as No_of_transactions
 from credit_card_transcactions
 where datename(weekday, transaction_date) in ('Saturday', 'Sunday')
 group by city) A)B
 order by ratio desc

-- Ques 9: Which city took least number of days to reach its 500th transaction after the first transaction in that city
 
 

 with city_500th_trans_date as
 (select * from 
 (select city, case when rn=500 then transaction_date end as _500th_date from
 (select city, transaction_id,  transaction_date, row_number() over(partition by city order by transaction_id) as rn
  from credit_card_transcactions
  group by city, transaction_id,  transaction_date) A ) B
  where _500th_date is not null
 )

 , city_min_trans_date as
 (select city, min(transaction_date) as minimum from credit_card_transcactions
  group by city
 )

 , days_difference as
 (select A.city, datediff(day, B.minimum, A._500th_date) as day_diff from city_500th_trans_date A
 inner join city_min_trans_date B on A.city=B.city
 ) 

 select city from days_difference
 where day_diff= (select min(day_diff) from days_difference)
 


