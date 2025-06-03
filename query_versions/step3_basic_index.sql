


use optimizations_hw

drop index basic_scored_rating on rate;

create index basic_scored_anime_id on rate(anime_id, rating);
create index basic_scored_rating on rate(rating, anime_id);
create index basic_anime on anime(anime_id, name, episodes);

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




