


use optimizations_hw

explain analyze
with non_null as (
select * from rate where rating != -1 and rating > 0 and rating is not null 
),
s as (
select anime_id, SUM(rating) as total from non_null
group by anime_id
)
select s.anime_id, s.total as total_score, a.name, a.episodes from s
inner join anime a on a.anime_id = s.anime_id
order by total desc



