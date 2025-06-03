


use optimizations_hw

explain analyze
with non_null as (
select rating, anime_id from rate where rating > 0
),
scored as (
select anime_id, SUM(rating) as total_score from non_null
group by anime_id
)
select scored.anime_id, scored.total_score, a.name, a.episodes from scored
inner join anime a on a.anime_id = scored.anime_id
order by total_score desc
