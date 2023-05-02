USE [AM]
GO

SELECT top 1000 [id]
      ,[name]
      ,[sex]
      ,[height]
      ,[weight]
      ,[team]
  FROM [dbo].[athletes]

GO

USE [AM]
GO

SELECT top 1000 [athlete_id]
      ,[games]
      ,[year]
      ,[season]
      ,[city]
      ,[sport]
      ,[event]
      ,[medal]
  FROM [dbo].[athlete_events]

GO

--1 which team has won the maximum gold medals over the years

with cte1 as (select A.team, COUNT(E.medal) as gold_cnt from dbo.athletes A inner join athlete_events E on A.id = E.athlete_id
where E.medal ='Gold'
group by A.team)
--order by gold_cnt desc
select * from cte1
where gold_cnt = (select max(gold_cnt) from cte1)

--2 for each team print total silver medals and year in which they won maximum silver medal..output 3 columns
-- team,total_silver_medals, year_of_max_silver

with cte1 as (select A.team, E.year, COUNT(E.medal) as silver_cnt from dbo.athletes A inner join athlete_events E on A.id = E.athlete_id
where E.medal ='Silver'
group by A.team,E.year)
--order by team, year)
, cte2 as (
select cte1.*,
FIRST_VALUE(year) OVER (PARTITION BY team ORDER BY silver_cnt desc) as year_of_max_silver from cte1)

select team, sum(silver_cnt) as total_silver_medals, MAX(year_of_max_silver) as year_of_max_silver from cte2
group by team
order by team

select A.team, E.year, COUNT(E.medal) as silver_cnt from dbo.athletes A inner join athlete_events E on A.id = E.athlete_id
where E.medal ='Silver'
group by A.team,E.year
order by team, year

--3 which player has won maximum gold medals  amongst the players 
--which have won only gold medal (never won silver or bronze) over the years

with cte1 as (select A.name,E.medal, COUNT(E.medal) as gold_cnt, COUNT(1) OVER (PARTITION BY name) as medal_types from dbo.athletes A inner join athlete_events E on A.id = E.athlete_id
where medal != 'NA'
group by A.name,E.medal)
--order by A.name),

select * from cte1
where gold_cnt = (SELECT max(gold_cnt) from cte1 where medal='Gold' and medal_types=1)


--4 in each year which player has won maximum gold medal . Write a query to print year,player name 
--and no of golds won in that year . In case of a tie print comma separated player names

with cte1 as (select A.name,E.medal,E.year, COUNT(E.medal) as gold_cnt, RANK() OVER (PARTITION BY year ORDER BY COUNT(E.medal) desc) as rn  from dbo.athletes A inner join athlete_events E on A.id = E.athlete_id
where E.medal = 'Gold'
group by A.name,E.year,E.medal)
--order by year, gold_cnt desc)

select year, STRING_AGG(name,', ') as players, MAX(gold_cnt) as num_golds from cte1 
where rn=1
group by year
order by year asc

--5 in which event and year India has won its first gold medal,first silver medal and first bronze medal
--print 3 columns medal,year,sport

with cte1 as (select E.medal,E.year,E.event, Rank() OVER (PARTITION BY medal ORDER BY year asc) as rn from dbo.athletes A inner join athlete_events E on A.id = E.athlete_id
where A.team = 'India' and E.medal !='NA')
--order by year, gold_cnt desc)

select distinct * from cte1 where rn=1

--6 find players who won gold medal in summer and winter olympics both.

select A.name from dbo.athletes A inner join athlete_events E on A.id = E.athlete_id
where E.medal = 'Gold'
group by A.name
having count(distinct season)=2

--7 find players who won gold, silver and bronze medal in a single olympics. print player name along with year.

select A.name,E.year from dbo.athletes A inner join athlete_events E on A.id = E.athlete_id
where E.medal != 'NA'
group by A.name,E.year
having COUNT(DISTINCT medal) =3
order by year

--8 find players who have won gold medals in consecutive 3 summer olympics in the same event . Consider only olympics 2000 onwards. 
--Assume summer olympics happens every 4 year starting 2000. print player name and event name.

with cte1 as (select A.name,E.year,E.event, COUNT(E.medal) as gold_cnt, COUNT(1) OVER (PARTITION BY name,event) as rn
from dbo.athletes A inner join athlete_events E on A.id = E.athlete_id
where E.medal = 'Gold' and year >=2000 and season='Summer'
group by A.name,E.year,E.event),

cte2 as (
select cte1.*,
lag(year,1) over (partition by name,event order by year asc) as prev_yr,
lead(year,1) over (partition by name,event order by year asc) as nxt_yr
from cte1
where rn>=3)

select distinct name,year,event from cte2
where prev_yr = year -4 and nxt_yr= year +4
order by name,event 

