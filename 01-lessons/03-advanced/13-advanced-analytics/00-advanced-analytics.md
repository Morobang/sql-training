# Advanced Analytics

This guide covers advanced GROUP BY capabilities (GROUPING SETS, CUBE, ROLLUP) and higher-level analytic patterns (cohort analysis, retention, percentiles) using the TechStore schema.

## GROUPING SETS / ROLLUP / CUBE

- GROUPING SETS: explicit list of grouping combinations in a single query.

- ROLLUP: hierarchical aggregation (from detailed to grand totals along specified columns).

- CUBE: all combinations of aggregations for N columns (2^N groups) useful for multi-dimensional reporting.

- GROUPING() and GROUPING_ID(): functions to detect which columns are aggregated (help to label subtotal rows).

## Use cases

- Sales reports with subtotals and grand totals.

- Multi-dimensional analysis across Category / Region / Month.

- Cohort analysis: retention and repeat purchase behavior over time.

- Percentiles and advanced window analytics for customer lifetime value (CLV) and segmentation.

## Performance tips

- GROUPING SETS and ROLLUP can be more efficient than many UNION ALL queries.

- CUBE grows exponentially; use selectively and consider filtering or pre-aggregating.

- Materialize intermediate aggregates with indexed staging tables for very large data.

## Next steps

- `01-grouping-sets.sql` — examples with GROUPING SETS.

- `02-cube-rollup.sql` — CUBE and ROLLUP examples and GROUPING_ID decoding.

- `03-advanced-window-functions.sql` — complex PARTITION BY, ROWS/RANGE frames, gaps and islands, cohort analysis.

-- End of guide
