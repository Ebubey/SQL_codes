-- drop table if exists athlete_events;
-- create table athlete_events (
-- "ID" numeric,
-- "name" varchar,
-- "sex" text,
-- "age" varchar,
-- "height" varchar,
-- "weight" varchar,
-- "team" varchar,
-- "noc" varchar,
-- "games" varchar,
-- "year" numeric,
-- "season" varchar,
-- "city" varchar,
-- "sport" varchar,
-- "event" varchar,
-- "medal" varchar

-- );
-- drop table if exists noc_regions;
-- create table noc_regions (
-- "noc" text,
-- "region" text,
-- "notes" text

-- );

select *
from athlete_events;

select *
from noc_regions

-- 1. how many olympic games has been held
select count(distinct Games) as total_games_held
from athlete_events;

-- 2. list down all games held so far
select distinct games, city
from athlete_events
order by games

-- 3. mention the total number of nations that participated in each olympics game?
select games, count(distinct noc) as total_nation
from athlete_events
group by games
ORDER BY count(distinct noc)

-- Which year saw the highest and lowest no of countries participating in olympics
WITH countries as
	(select games, count(distinct noc) as total_nation
	from athlete_events
	group by games
	ORDER BY count(distinct noc))
select distinct concat(first_value (games) over(order by total_nation), '-',
			 min(total_nation) over()),concat(first_value (games) over(order by total_nation desc), '-',
			 max(total_nation) over())
from countries;

-- 5. Which nation has participated in all of the olympic games
with games_p as 
	(select nc.region, count(distinct ae.games) as games_participated
	from athlete_events ae
	join noc_regions nc
		on ae.noc = nc.noc
	group by nc.region
	order by count(distinct ae.games) desc),
total_games as
	(select count(distinct games) as tot
	from athlete_events)
select gp.*
from games_p gp
join total_games tg
	on tg.tot = gp.games_participated;

--  6. Identify the sport which was played in all summer olympics
with s_games as 
	(select count(distinct games) as total_summer_games
	from athlete_events
	where season = 'Summer'),
number_of_sports as
	(select sport, count(distinct games) as total_
	from athlete_events
	group by sport)
select ns.*
from number_of_sports ns
join s_games sg on sg.total_summer_games = ns.total_;

-- 7. Which Sports were just played only once in the olympics.
with s_played as 
	(select sport, count(distinct games) as total_
	from athlete_events
	group by sport
	order by count(distinct games))
select *
from s_played
where total_ = 1;

-- 8.Fetch oldest athletes to win a gold medal
with temp as
	(select *
	from athlete_events
	where medal = 'Gold'),
RAnk_ as
	(SELECT *, CAST(COALESCE(NULLIF(age, 'NA'), '0') AS INT) AS age_integer,
									rank() over(order by CAST(COALESCE(NULLIF(age, 'NA'), '0') AS INT) desc)
	FROM temp)
select *
from RAnk_
where rank = 1

-- 10. Find the Ratio of male and female athletes participated in all olympic games.
select concat('1 : ',round(count(sex)::decimal/(select count(sex)
				  from athlete_events
				  where sex = 'F'),2)) as male_to_female_ratio
from athlete_events
where sex = 'M'

-- 11. Fetch the top 5 athletes who have won the most gold medals.
with most as 
	(select name, sex, count(medal) as total_medal
	from athlete_events
	where medal = 'Gold'
	group by name,sex
	order by count(medal) desc),
ranking  as 
(select *, dense_rank() over(order by total_medal desc)
from most)
select *
from ranking
where dense_rank <= 5;

-- 12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
with most as 
	(select name, team, count(medal) as total_medal
	from athlete_events
	where medal <> 'NA'
	group by name,team	
	order by count(medal) desc),
ranking  as 
(select *, dense_rank() over(order by total_medal desc)
from most)
select *
from ranking
where dense_rank <= 5;

-- 13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
select nc.region, ae.team, count(medal) as total_medal
from athlete_events ae
join noc_regions nc
	on ae.noc = nc.noc
where medal <> 'NA'
group by nc.region, ae.team
order by count(medal) desc
limit 5;

-- 14. List down total gold, silver and bronze medals won by each country.
CREATE EXTENSION TABLEFUNC;
select region as country, medal, count(2) as total_medals
from athlete_events ae
join noc_regions nr
	on ae.noc = nr.noc
-- where medal
group by region, medal;

select country,
		coalesce(Bronze,0) as Bronze,
		coalesce(Gold,0) as Gold,
		coalesce(Silver,0) as Silver
from crosstab ('select region as country, medal, count(2) as total_medals
				from athlete_events ae
				join noc_regions nr
					on ae.noc = nr.noc
				--where region in (''Botswana'', ''Burundi'')
				group by region, medal',
			  'values (''Bronze''), (''Gold''), (''Silver'')')
			AS ct (country text, bronze int, gold int, silver int)
			order by gold desc;

-- 15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.
select substring(country, 1, position('-' in country)-2) as games,
		 substring(country, position('-' in country)+2) as country,
		coalesce(Bronze,0) as Bronze,
		coalesce(Gold,0) as Gold,
		coalesce(Silver,0) as Silver
from crosstab ('select concat(games,'' - '', region) as country, medal, count(2) as total_medals
				from athlete_events ae
				join noc_regions nr
					on ae.noc = nr.noc
				where medal <> ''NA''
				group by games, region, medal
				order by games, region, medal',
			  'values (''Bronze''), (''Gold''), (''Silver'')')
			AS ct (country text, bronze int, gold int, silver int)

-- 16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.
with temp as
	(select substring(country, 1, position('-' in country)-2) as games,
			 substring(country, position('-' in country)+2) as country,
			coalesce(Bronze,0) as Bronze,
			coalesce(Gold,0) as Gold,
			coalesce(Silver,0) as Silver
	from crosstab ('select concat(games,'' - '', region) as country, medal, count(2) as total_medals
					from athlete_events ae
					join noc_regions nr
						on ae.noc = nr.noc
					where medal <> ''NA''
					group by games, region, medal
					order by games, region, medal',
				  'values (''Bronze''), (''Gold''), (''Silver'')')
				AS ct (country text, bronze int, gold int, silver int))
select distinct games,
concat(first_value(country) over(partition by games order by gold desc), ' - ', first_value(gold) over(partition by games order by gold desc)) as Gold
,concat(first_value(country) over(partition by games order by silver desc), ' - ', first_value(silver) over(partition by games order by silver desc)) as Silver
,concat(first_value(country) over(partition by games order by bronze desc), ' - ', first_value(bronze) over(partition by games order by bronze desc)) as Bronze
from temp
order by games

-- 17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.
with temp as
	(select substring(country, 1, position('-' in country)-2) as games,
			 substring(country, position('-' in country)+2) as country,
			coalesce(Bronze,0) as Bronze,
			coalesce(Gold,0) as Gold,
			coalesce(Silver,0) as Silver
	from crosstab ('select concat(games,'' - '', region) as country, medal, count(2) as total_medals
					from athlete_events ae
					join noc_regions nr
						on ae.noc = nr.noc
					where medal <> ''NA''
					group by games, region, medal
					order by games, region, medal',
				  'values (''Bronze''), (''Gold''), (''Silver'')')
				AS ct (country text, bronze int, gold int, silver int)),
total_medals as
	(select games, region as country, count(medal) as total_
	from athlete_events ae
	join noc_regions nc 
		on ae.noc = nc.noc
	where medal <> 'NA'
	group by games,region
	order by games,region)
select distinct t.games,
concat(first_value(t.country) over(partition by t.games order by gold desc), ' - ', first_value(gold) over(partition by t.games order by gold desc)) as gold
,concat(first_value(t.country) over(partition by t.games order by silver desc), ' - ', first_value(silver) over(partition by t.games order by silver desc)) as silver
,concat(first_value(t.country) over(partition by t.games order by bronze desc), ' - ', first_value(bronze) over(partition by t.games order by bronze desc)) as bronze
,concat(first_value(t.country) over(partition by t.games order by total_ desc), ' - ', first_value(total_) over(partition by t.games order by total_ desc)) as max_medal
from temp t
join total_medals tm
	on t.games = tm.games and t.country = tm.country
order by t.games

-- 18. Which countries have never won gold medal but have won silver/bronze medals?
select * from (select country,
		coalesce(Bronze,0) as Bronze,
		coalesce(Gold,0) as Gold,
		coalesce(Silver,0) as Silver
from crosstab ('select region as country, medal, count(2) as total_medals
				from athlete_events ae
				join noc_regions nr
					on ae.noc = nr.noc
				group by region, medal',
			  'values (''Bronze''), (''Gold''), (''Silver'')')
			AS ct (country text, bronze int, gold int, silver int)) t
where gold = 0 and (silver > 0 or bronze > 0)
order by gold desc, silver desc, bronze desc

-- 19. In which Sport/event, India has won highest medals.
select sport,count(medal)
from athlete_events ae
join noc_regions nc on ae.noc = nc.noc
where region = 'India' and medal <> 'NA'
group by sport
order by count(medal) desc

--  Break down all olympic games where India won medal for Hockey and how many medals in each olympic games
select region, sport, games, count(medal)
from athlete_events ae
join noc_regions nc on ae.noc = nc.noc
where region = 'India' and medal <> 'NA' and sport = 'Hockey'
group by region, sport, games
order by count(medal) desc