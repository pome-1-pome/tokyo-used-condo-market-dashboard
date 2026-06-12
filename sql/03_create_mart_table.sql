-- 03_create_mart_table.sql
-- BigQuery mart layer
-- ASCII-only SQL to avoid Windows CLI encoding issues.
-- Replace YOUR_PROJECT_ID with your actual GCP project ID.

CREATE SCHEMA IF NOT EXISTS `YOUR_PROJECT_ID.mart`;

CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.mart.mart_tokyo_used_condo_segments` AS
WITH analysis_base AS (
  SELECT
    *
  FROM `YOUR_PROJECT_ID.staging.stg_tokyo_used_condo_transactions`
  WHERE
    transaction_quarter_start_date IS NOT NULL
    AND unit_price_per_sqm IS NOT NULL
    AND unit_price_per_sqm BETWEEN 100000 AND 5000000
),

quarterly_segment AS (
  SELECT
    municipality,
    transaction_year,
    transaction_quarter,
    transaction_quarter_start_date,
    station_distance_band,
    building_age_band,

    COUNT(*) AS transaction_count,
    AVG(unit_price_per_sqm) AS avg_unit_price_per_sqm,
    APPROX_QUANTILES(unit_price_per_sqm, 100)[OFFSET(50)] AS median_unit_price_per_sqm,
    AVG(transaction_price_total) AS avg_transaction_price_total,
    AVG(area_sqm) AS avg_area_sqm

  FROM analysis_base
  GROUP BY
    municipality,
    transaction_year,
    transaction_quarter,
    transaction_quarter_start_date,
    station_distance_band,
    building_age_band
),

with_yoy AS (
  SELECT
    *,
    LAG(avg_unit_price_per_sqm, 4) OVER (
      PARTITION BY municipality, station_distance_band, building_age_band
      ORDER BY transaction_quarter_start_date
    ) AS avg_unit_price_per_sqm_prev_year
  FROM quarterly_segment
)

SELECT
  *,
  SAFE_DIVIDE(
    avg_unit_price_per_sqm - avg_unit_price_per_sqm_prev_year,
    avg_unit_price_per_sqm_prev_year
  ) AS yoy_growth_rate,

  CASE
    WHEN transaction_count >= 30
      AND SAFE_DIVIDE(
        avg_unit_price_per_sqm - avg_unit_price_per_sqm_prev_year,
        avg_unit_price_per_sqm_prev_year
      ) > 0
      THEN 'priority_research_candidate'
    ELSE 'normal_review'
  END AS recommendation_flag

FROM with_yoy;
