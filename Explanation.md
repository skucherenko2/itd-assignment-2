# Optimizations explanation

### Unoptimized

Lots of costly materializations/joins/aggregations, full table scans 🤢🤢🤢🤢🤢

~~~
-> Sort: s.total DESC  (actual time=4464..4465 rows=9367 loops=1)
    -> Stream results  (cost=323148 rows=0) (actual time=4426..4458 rows=9367 loops=1)
        -> Nested loop inner join  (cost=323148 rows=0) (actual time=4426..4456 rows=9367 loops=1)
            -> Filter: (a.anime_id is not null)  (cost=1199 rows=11747) (actual time=0.0285..20 rows=12022 loops=1)
                -> Table scan on a  (cost=1199 rows=11747) (actual time=0.0279..19.5 rows=12022 loops=1)
            -> Index lookup on s using <auto_key0> (anime_id=a.anime_id)  (cost=0.25..27.4 rows=110) (actual time=0.369..0.369 rows=0.779 loops=12022)
                -> Materialize  (cost=0..0 rows=0) (actual time=4425..4425 rows=9593 loops=1)
                    -> Table scan on <temporary>  (actual time=4422..4422 rows=9593 loops=1)
                        -> Aggregate using temporary table  (actual time=4422..4422 rows=9593 loops=1)
                            -> Filter: ((rate.rating <> <cache>(-(1))) and (rate.rating > 0) and (rate.rating is not null))  (cost=488831 rows=1.29e+6) (actual time=1.39..2869 rows=4.1e+6 loops=1)
                                -> Table scan on rate  (cost=488831 rows=4.77e+6) (actual time=1.36..2475 rows=5.06e+6 loops=1)
~~~

### Refactoring to CTE's

No significant performance impact but code is much more readable. Execution plan has changes with regard to using CTE.

~~~
-> Sort: s.total DESC  (actual time=4598..4599 rows=9367 loops=1)
    -> Stream results  (cost=323148 rows=0) (actual time=4559..4592 rows=9367 loops=1)
        -> Nested loop inner join  (cost=323148 rows=0) (actual time=4559..4589 rows=9367 loops=1)
            -> Filter: (a.anime_id is not null)  (cost=1199 rows=11747) (actual time=0.028..19.4 rows=12022 loops=1)
                -> Table scan on a  (cost=1199 rows=11747) (actual time=0.0276..18.9 rows=12022 loops=1)
            -> Index lookup on s using <auto_key0> (anime_id=a.anime_id)  (cost=0.25..27.4 rows=110) (actual time=0.38..0.38 rows=0.779 loops=12022)
                -> Materialize CTE s  (cost=0..0 rows=0) (actual time=4559..4559 rows=9593 loops=1)
                    -> Table scan on <temporary>  (actual time=4555..4555 rows=9593 loops=1)
                        -> Aggregate using temporary table  (actual time=4555..4555 rows=9593 loops=1)
                            -> Filter: ((rate.rating <> <cache>(-(1))) and (rate.rating > 0) and (rate.rating is not null))  (cost=488831 rows=1.29e+6) (actual time=11.5..2964 rows=4.1e+6 loops=1)
                                -> Table scan on rate  (cost=488831 rows=4.77e+6) (actual time=11.4..2581 rows=5.06e+6 loops=1)
~~~

### Optimizing query logic

Changing query logic to use more efficient filtering and reducing amount of rows copied in select statements. Minor performance impact.

~~~
-> Sort: scored.total_score DESC  (actual time=4410..4410 rows=9367 loops=1)
    -> Stream results  (cost=398666 rows=0) (actual time=4371..4403 rows=9367 loops=1)
        -> Nested loop inner join  (cost=398666 rows=0) (actual time=4371..4401 rows=9367 loops=1)
            -> Filter: (a.anime_id is not null)  (cost=1199 rows=11747) (actual time=0.0471..17.6 rows=12022 loops=1)
                -> Table scan on a  (cost=1199 rows=11747) (actual time=0.0459..17 rows=12022 loops=1)
            -> Index lookup on scored using <auto_key0> (anime_id=a.anime_id)  (cost=0.25..33.8 rows=135) (actual time=0.364..0.364 rows=0.779 loops=12022)
                -> Materialize CTE scored  (cost=0..0 rows=0) (actual time=4371..4371 rows=9593 loops=1)
                    -> Table scan on <temporary>  (actual time=4367..4367 rows=9593 loops=1)
                        -> Aggregate using temporary table  (actual time=4367..4367 rows=9593 loops=1)
                            -> Filter: (rate.rating > 0)  (cost=488831 rows=1.59e+6) (actual time=1.03..2758 rows=4.1e+6 loops=1)
                                -> Table scan on rate  (cost=488831 rows=4.77e+6) (actual time=0.991..2503 rows=5.06e+6 loops=1)
~~~

### Introducing indexes

No more full table scans 😊😊😊😊😊. 

Got rid of aggregations, convetred to using covering indexes. Also materialization and joins are quicker now.

Noticable performance change.

However, some covering indexes are actually forcing mysql to use different types of join (nested loop vs hash) or do it in a more inefficient way.

Alternatively forcing index scans with incorrect indexes actually kills performance.

I had to use ignore index hint to use several indexes in different locations.

~~~
-> Sort: scored.total_score DESC  (actual time=3325..3326 rows=9367 loops=1)
    -> Stream results  (cost=1.88e+6 rows=14.8e+6) (actual time=3296..3318 rows=9367 loops=1)
        -> Nested loop inner join  (cost=1.88e+6 rows=14.8e+6) (actual time=3296..3315 rows=9367 loops=1)
            -> Filter: (a.anime_id is not null)  (cost=1199 rows=11747) (actual time=0.0346..8.29 rows=12022 loops=1)
                -> Covering index scan on a using basic_anime  (cost=1199 rows=11747) (actual time=0.0341..7.61 rows=12022 loops=1)
            -> Index lookup on scored using <auto_key0> (anime_id=a.anime_id)  (cost=647944..647978 rows=135) (actual time=0.275..0.275 rows=0.779 loops=12022)
                -> Materialize CTE scored  (cost=647944..647944 rows=1261) (actual time=3296..3296 rows=9593 loops=1)
                    -> Group aggregate: sum(rate.rating)  (cost=647818 rows=1261) (actual time=10.3..3288 rows=9593 loops=1)
                        -> Filter: (rate.rating > 0)  (cost=488831 rows=1.59e+6) (actual time=1.12..2965 rows=4.1e+6 loops=1)
                            -> Covering index scan on rate using basic_scored_anime_id  (cost=488831 rows=4.77e+6) (actual time=0.0078..2637 rows=5.06e+6 loops=1)
~~~


