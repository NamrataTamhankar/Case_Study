<--1. Fetch all the paintings which are not displayed on any museums?-->
select * from work where museum_id is null

<--2. Are there museums without any paintings?
select museum_id from museum where museum_id not in(select distinct museum_id from work)

<--3. How many paintings have an asking price of more than their regular price?
select * from product_size where sale_price > regular_price

<--4. Identify the paintings whose asking price is less than 50% of its regular price
select * from product_size where sale_price < (regular_price*0.5);

<--5. Which canva size costs the most?
select ps.sale_price, label from(
select *, RANK() over(order by sale_price desc) rnk from product_size as ps )ps
join canvas_size cs on ps.size_id = cs.size_id where rnk =1;
 
<--9. Fetch the top 10 most famous painting subject
select * from (select s.subject, count(1) as no_of_painting, rank() over (order by count(1) desc) as rnk 
from work w join subject s on w.work_id = s.work_id group by s.subject) sq where rnk < 11;

/*10. Identify the museums which are open on both Sunday and Monday. Display museum name, city.*/
select m.museum_id, name, city, state, country  from museum_hours mh join museum m on m.museum_id = mh.museum_id where
day like 'Sunday' and exists 
(select 1 from museum_hours mh2 where mh.museum_id = mh2.museum_id and day like 'Monday');

<--11. How many museums are open every single day?
select count(*) as open_evryday from(
select museum_id, count(day) as daysopen  from museum_hours group by museum_id having count(day) = 7)sq;

<--12. Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)
select m.name as museum, m.city,m.country, workpermuseum from museum m join 
(select m1.name as museum, COUNT(work_id) as workpermuseum, rank() over (order by COUNT(work_id) desc) rnk from 
work w join museum m1 on m1.museum_id = w.museum_id group by m1.name) x on x.museum = m.name where rnk <6 order by rnk;

<--13. Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)
select a.full_name, style, nationality, workperartist, rnk from artist a join 
(select full_name, COUNT(work_id) as workperartist, rank() over (order by COUNT(work_id) desc) rnk from 
work w join artist a on a.artist_id = w.artist_id group by full_name) x on x.full_name = a.full_name 
where rnk <6 order by rnk;

<--14. Display the 3 least popular canva sizes
select label, x.rnk, total from canvas_size cs join(
select size_id, COUNT(work_id) AS total, dense_rank() over (order by COUNT(work_id)) as rnk from product_size group by size_id) x
on x.size_id = cs.size_id where rnk < 4;

<--15. Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?
SELECT museum_name, state AS city, [day] ,[open],[close],
       CONVERT(TIME, [open]) AS open_time, CONVERT(TIME, [close]) AS close_time,
       DATEDIFF(MINUTE, CONVERT(TIME, [open]), CONVERT(TIME, [close])) AS duration
FROM (SELECT m.name AS museum_name, m.state, [day], [open],[close],
           RANK() OVER (ORDER BY DATEDIFF(MINUTE, CONVERT(TIME, [open]), CONVERT(TIME, [close])) DESC) AS rnk
    FROM museum_hours mh JOIN museum m ON m.museum_id = mh.museum_id ) x WHERE x.rnk = 1;

<--16. Which museum has the most no of most popular painting style?
select TOP 1 m.name, [style], count([work_id]) no_of_painting  from work w join museum m on m.museum_id = w.museum_id
group by  m.name, [style] having m.name is not NULL order by count([style]) desc;

<--17. Identify the artists whose paintings are displayed in multiple countries
select a.full_name, COUNT(distinct m.country)paintings_in_no_of_countries from work w join museum m 
on w.museum_id = m.museum_id join artist a on w.artist_id = a.artist_id 
group by a.full_name having COUNT(distinct m.country) >1 order by paintings_in_no_of_countries desc;

<--18. Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country. If there are multiple value, seperate them with comma.
with cte_country as
(select (country), count([museum_id])museum_per_country, rank () over (order by count([museum_id]) desc) as rnk from museum group by country),
cte_city as(
select city, count([museum_id])museum_per_country, rank () over (order by count([museum_id]) desc) as rnk from museum
group by city)
select STRING_AGG((country.country), ', '), STRING_AGG(  city.city, ', ') from cte_country country cross join 
cte_city city where country.rnk = 1 and city.rnk = 1;

/*19. Identify the artist and the museum where the most expensive and least expensive painting is placed. 
Display the artist name, sale_price, painting name, museum name, museum city and canvas label*/
with cte_sale as (
select * , rank() over(order by sale_price desc) as minsp , rank() over(order by sale_price ) as maxsp
		from product_size )
select w.name, cte_sale.sale_price, full_name, m.name, m.city, cs.label from cte_sale join work w on w.work_id = cte_sale.work_id
join museum m on w.museum_id = m.museum_id join artist a on w.artist_id = a.artist_id join canvas_size cs on 
cs.size_id = cte_sale.size_id where maxsp = 1 or minsp =1;

<--20. Which country has the 5th highest no of paintings?
with cte as (
select [country], count(w.[work_id]) total, DENSE_RANK() over (order by count([work_id]) desc)as rnk from work w
 join museum m on w.[museum_id] = m.[museum_id] group by [country])
 select [country], total from cte where rnk = 5;

 <--21. Which are the 3 most popular and 3 least popular painting styles?
with cte as(select [style], count([work_id]) total, DENSE_RANK() over (order by count([work_id]) desc)
as rnk, count(1) over() as noofpaint   from work where style is not null group by [style])
select style, case when rnk <=3 then 'most popular' else 'least popular' end as remark from cte where 
rnk <= 3 or rnk > noofpaint-3; 

<--22. Which artist has the most no of Portraits paintings outside USA?. Display artistname, noof paintings and the artist nationality
with cte as(
select COUNT(s.[work_id]) total, artist_id, RANK() over (order by COUNT(s.[work_id]) desc)rnk from subject s 
join work w on  s.work_id = w.work_id join museum m on m.museum_id = w.museum_id where m.country not in ('USA')
and s.subject = 'Portraits' group by artist_id )
select full_name, nationality, total from cte join artist a on cte.artist_id = a.artist_id where cte.rnk = 1

