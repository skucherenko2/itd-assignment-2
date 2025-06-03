# itd-assignment-2

Optimizing sql queries for sugesting best rated animes. 

Because we need more high-quality anime in our lives, don't we?

Overview:
| N | Optimizations steps | performance | gain |
| --- | --- | --- | --- |
| 0 | Initial query          | 4.45 sec | ---    |
| 1 | Refactoring to use CTE | 4.6  sec | -3.3 % |
| 2 | Optimizing query logic | 4.41 sec | +4.3 % |
| 3 | Introducing indexes    | 3.32 sec | +32.8% |

Analysis: 

CTE's can minorily hurt performance.

Some index usage actually hurts the performance (had to use ignore index)

Tables are highly populated and using indexes is not making as big impact as could have been due to low filtering.

e.g. we are only doing rating-based filtering which mostly satisfies condition.
