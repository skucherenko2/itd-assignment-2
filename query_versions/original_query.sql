
use optimizations_hw

explain analyze
select s.anime_id, s.total as total_score, a.name, a.episodes from (
select anime_id, SUM(rating) as total from
( select * from rate where rating != -1 and rating > 0 and rating is not null ) non_null
group by anime_id) s
inner join anime a on a.anime_id = s.anime_id
order by total desc


