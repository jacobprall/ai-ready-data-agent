CREATE OR REPLACE TABLE {{ asset }} AS
SELECT *
FROM {{ asset }}
QUALIFY ROW_NUMBER() OVER (PARTITION BY {{ key_columns }} ORDER BY {{ tiebreaker_column }} DESC) = 1
