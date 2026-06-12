-- 01_create_raw_table.sql
-- BigQuery raw layer
-- Replace YOUR_PROJECT_ID with your actual GCP project ID.

CREATE SCHEMA IF NOT EXISTS `YOUR_PROJECT_ID.raw`;

CREATE OR REPLACE TABLE `YOUR_PROJECT_ID.raw.tokyo_used_condo_transactions` (
  property_type STRING,
  price_info_type STRING,
  municipality_code STRING,
  prefecture STRING,
  municipality STRING,
  district_name STRING,
  nearest_station STRING,
  station_distance_min_raw STRING,
  transaction_price_total_raw STRING,
  floor_plan STRING,
  area_sqm_raw STRING,
  building_year_raw STRING,
  building_structure STRING,
  property_use STRING,
  future_use STRING,
  city_planning STRING,
  building_coverage_ratio_raw STRING,
  floor_area_ratio_raw STRING,
  transaction_period_raw STRING,
  renovation STRING,
  transaction_notes STRING
);
