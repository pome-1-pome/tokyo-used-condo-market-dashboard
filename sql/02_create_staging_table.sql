-- 02_create_staging_table.sql
-- BigQuery staging layer
-- Replace YOUR_PROJECT_ID with your actual GCP project ID.

CREATE SCHEMA IF NOT EXISTS `YOUR_PROJECT_ID.staging`;

CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.staging.stg_tokyo_used_condo_transactions` AS
WITH typed AS (
  SELECT
    property_type,
    price_info_type,
    municipality_code,
    prefecture,
    municipality,
    district_name,
    nearest_station,
    station_distance_min_raw,
    SAFE_CAST(NULLIF(REGEXP_REPLACE(transaction_price_total_raw, r'[^0-9]', ''), '') AS INT64) AS transaction_price_total,
    floor_plan,
    SAFE_CAST(NULLIF(REGEXP_REPLACE(area_sqm_raw, r'[^0-9.]', ''), '') AS FLOAT64) AS area_sqm,
    building_year_raw,
    SAFE_CAST(REGEXP_EXTRACT(building_year_raw, r'(\d{4})') AS INT64) AS building_year,
    building_structure,
    property_use,
    future_use,
    city_planning,
    SAFE_CAST(NULLIF(REGEXP_REPLACE(building_coverage_ratio_raw, r'[^0-9.]', ''), '') AS FLOAT64) AS building_coverage_ratio,
    SAFE_CAST(NULLIF(REGEXP_REPLACE(floor_area_ratio_raw, r'[^0-9.]', ''), '') AS FLOAT64) AS floor_area_ratio,
    transaction_period_raw,
    SAFE_CAST(REGEXP_EXTRACT(transaction_period_raw, r'(\d{4})') AS INT64) AS transaction_year,
    SAFE_CAST(REGEXP_EXTRACT(transaction_period_raw, r'第([1-4])四半期') AS INT64) AS transaction_quarter,
    renovation,
    transaction_notes
  FROM `YOUR_PROJECT_ID.raw.tokyo_used_condo_transactions`
),

enriched AS (
  SELECT
    *,
    SAFE_DIVIDE(transaction_price_total, area_sqm) AS unit_price_per_sqm,

    CASE
      WHEN transaction_year IS NOT NULL AND transaction_quarter IS NOT NULL
        THEN DATE(transaction_year, 1 + (transaction_quarter - 1) * 3, 1)
      ELSE NULL
    END AS transaction_quarter_start_date,

    CASE
      WHEN station_distance_min_raw IS NULL OR station_distance_min_raw = '' THEN NULL
      WHEN SAFE_CAST(station_distance_min_raw AS INT64) IS NOT NULL
        THEN SAFE_CAST(station_distance_min_raw AS INT64)
      WHEN station_distance_min_raw LIKE '%30%' THEN 30
      WHEN station_distance_min_raw LIKE '%1H%' THEN 60
      WHEN station_distance_min_raw LIKE '%2H%' THEN 120
      ELSE NULL
    END AS station_distance_min,

    CASE
      WHEN transaction_year IS NOT NULL AND building_year IS NOT NULL
        THEN transaction_year - building_year
      ELSE NULL
    END AS building_age
  FROM typed
)

SELECT
  *,

  CASE
    WHEN station_distance_min IS NULL THEN '不明'
    WHEN station_distance_min <= 5 THEN '徒歩5分以内'
    WHEN station_distance_min <= 10 THEN '徒歩6〜10分'
    WHEN station_distance_min <= 15 THEN '徒歩11〜15分'
    WHEN station_distance_min <= 20 THEN '徒歩16〜20分'
    WHEN station_distance_min <= 30 THEN '徒歩21〜30分'
    ELSE '徒歩30分超'
  END AS station_distance_band,

  CASE
    WHEN building_age IS NULL THEN '不明'
    WHEN building_age < 10 THEN '築10年未満'
    WHEN building_age < 20 THEN '築10〜20年'
    WHEN building_age < 30 THEN '築20〜30年'
    WHEN building_age < 40 THEN '築30〜40年'
    ELSE '築40年以上'
  END AS building_age_band

FROM enriched
WHERE
  property_type = '中古マンション等'
  AND price_info_type = '不動産取引価格情報'
  AND prefecture = '東京都'
  AND transaction_price_total IS NOT NULL
  AND area_sqm IS NOT NULL
  AND area_sqm > 0;
