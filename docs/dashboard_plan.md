# Looker Studio ダッシュボード設計メモ

## 接続先

BigQuery:
- project: tokyo-condo-0612-pome
- dataset: mart
- table: mart_tokyo_used_condo_segments

## ダッシュボード目的

中古マンション買取再販業者が、営業・仕入れ調査を優先すべきエリア×物件セグメントを把握する。

## 主要KPI

- 取引件数
- 平均㎡単価
- 中央値㎡単価
- 前年同期比成長率
- 重点調査候補セグメント数

## 作成するグラフ

1. KPIカード
   - mart対象取引数
   - 重点調査候補数
   - 平均㎡単価
   - 中央値㎡単価

2. 区別の取引件数ランキング
   - dimension: municipality
   - metric: SUM(transaction_count)

3. 区別の平均㎡単価ランキング
   - dimension: municipality
   - metric: AVG(avg_unit_price_per_sqm)

4. 駅距離帯×築年帯のヒートマップ
   - row: station_distance_band
   - column: building_age_band
   - metric: AVG(avg_unit_price_per_sqm)

5. 重点調査候補一覧テーブル
   - municipality
   - transaction_year
   - transaction_quarter
   - station_distance_band
   - building_age_band
   - transaction_count
   - avg_unit_price_per_sqm
   - median_unit_price_per_sqm
   - yoy_growth_rate
   - recommendation_flag
