select *
from "web_events"

select distinct("channel")
from "web_events"

select w.channel, sum(a.total) as "total"
-- select *
from "Orders" a
join "Webs_events" w
on a.account_id = w.account_id
-- join "Orders" o
-- on w.account_id = o.account_id
group by w.channel
order by "total" desc;

select a.name, w.channel, sum(o.total) as "total"
from "Account" a
join "Webs_events" w
on a.id = w.account_id
join "Orders" o
on a.id = o.account_id
where a.name like 'P%'
group by a.name, w.channel
order by "total" desc

select r.name, sum(o.total) as "total"
-- select *
from "Orders" o
join "Region" r
on o.id = r.id
group by r.name
order by "total"

select s.name, sum(o.total) as "tt"
select *
from "Orders" o
join "Region" r
on o.id = r.id
join "Sales_reps" s
on r.id = s.region_id
where r.name = 'Midwest'
group by s.name


select w.channel, sum(o.total) as "tot"
from "Orders" as o
join "Webs_events" as w
on o.account_id = w.account_id
group by w.channel
order by "tot" desc

select a.name, w.channel, sum(o.total_amt_usd) as "tot_sales_usd"
from "Orders" as o
join "Webs_events" as w
on o.account_id = w.account_id
join "Account" as a
on w.account_id = a.id
where a.name like '%I%'
group by a.name,w.channel
order by "tot_sales_usd" desc

select s.name, sum(o.total) as "total"
from "Account" as a
join "Orders" as o
on a.id = o.account_id
join "Sales_reps" as s
on a.sales_rep_id = s.id
join "Region" as r
on s.region_id = r.id
where r.name = 'Northeast'
group by s.name
order by "total" desc

which sales rep has the most customerbase
select s.name, count(a.name) as "amount"
from "Account" as a
join "Sales_reps" as s
on a.sales_rep_id = s.id
group by s.name
order by "amount" desc

-- which region has the most revenue by direct channel
select r.name, sum("total_amt_usd") as "tot_rev"
select *
from "Account" a
join "Orders" o
on a.id = o.account_id
join "Webs_events" w
on o.account_id = w.account_id
join "Sales_reps" s
on a.sales_rep_id = s.id
join "Region" r 
on s.region_id = r.id
where w.channel = 'direct'
group by r.name
order by "tot_rev" desc

which account had the highest transaction with organic channel in midwest
select a.name, sum(o.total) as "tot_trans"
from "Account" a
join "Orders" o
on a.id = o.account_id
join "Webs_events" w
on o.account_id = w.account_id
join "Sales_reps" s
on a.sales_rep_id = s.id
join "Region" r 
on s.region_id = r.id
where w.channel = 'organic' and r.name = 'Midwest'
group by a.name
order by "tot_trans" desc

which channel is more popular in the not east region
select w.channel, count(w.channel) as "tot_trans"
from "Account" a
join "Webs_events" w
on a.id = w.account_id
join "Sales_reps" s
on a.sales_rep_id = s.id
join "Region" r 
on s.region_id = r.id
where r.name = 'Northeast'
group by w.channel
order by "tot_trans" desc

--  which weekday had the total sales in amt usd
select "WeekDays", sum("total_amt_usd") as "total_sum"
from
(select *,
case when "weekday" = 0 then 'Saturday'
	 when "weekday" = 1 then 'Sunday'
	 when "weekday" = 2 then 'Monday'
	 when "weekday" = 3 then 'Tuesday'
	 when "weekday" = 4 then 'Wednesday'
	 when "weekday" = 5 then 'Thursday'
else 'Friday' end as "WeekDays"
from
(select *, extract(dow from "occurred_at") as "weekday"
from "Orders") as "t1") as "t2"
group by "WeekDays"

--  1) the most frequent weekdays sales was made by a) each company 

with a1 as
(select *,
case when "weekday" = 1 then 'Saturday'
	 when "weekday" = 0 then 'Sunday'
	 when "weekday" = 2 then 'Monday'
	 when "weekday" = 3 then 'Tuesday'
	 when "weekday" = 4 then 'Wednesday'
	 when "weekday" = 5 then 'Thursday'
else 'Friday' end as "WeekDays"
from
(select *, extract(dow from "occurred_at") as "weekday"
from "Orders") as t1
join "Account" a
on a.id = t1.account_id),
a2 as
(select "name","WeekDays",count("name") as "freq"
from "a1"
group by "name","WeekDays"
order by name,"WeekDays")
select distinct name,
first_value(freq) over(partition by name order by freq desc) as gold,
first_value("WeekDays") over(partition by name order by freq desc) as you
from a2
order by gold desc;

-- b) channel that sold more then the most frequent weekdays these channels sold
with webs as
(select *,
case when "weekday" = 1 then 'Saturday'
	 when "weekday" = 0 then 'Sunday'
	 when "weekday" = 2 then 'Monday'
	 when "weekday" = 3 then 'Tuesday'
	 when "weekday" = 4 then 'Wednesday'
	 when "weekday" = 5 then 'Thursday'
else 'Friday' end as "weekdays"
from
(select *, extract(dow from "occurred_at") as "weekday"
from "Orders") as t1
join "Webs_events" w
on w.id = t1.account_id)
select distinct channel,first_value(num) over(partition by channel order by num) as maxi,
first_value(weekdays) over(partition by channel order by num) as day
from
(select channel,weekdays,count(weekdays) as num
from webs
group by channel,weekdays) as t2
order by maxi desc