---
service: "ads-jobframework"
title: "Order Feed Export"
generated: "2026-03-03"
type: flow
flow_name: "order-feed-export"
flow_type: batch
trigger: "Scheduled daily via Airflow (Cloud Composer)"
participants:
  - "continuumAdsJobframeworkSpark"
  - "continuumAdsJobframeworkHiveWarehouse"
  - "continuumAdsJobframeworkGcsBucket"
  - "continuumAdsJobframeworkMetricsEndpoint"
architecture_ref: "dynamic-ads-jobframework"
---

# Order Feed Export

## Summary

This flow generates a daily hashed order feed for CitrusAd conversion attribution. It reads authorized order records from `user_edwprod.fact_gbl_transactions` for a configurable date range, produces two variants per order (bcookie session and consumer ID session), hashes customer and session identifiers with HMAC-SHA256, and writes a tab-delimited TSV to GCS. CitrusAd ingests this feed to attribute conversions to sponsored listing ad exposures.

## Trigger

- **Type**: schedule
- **Source**: Airflow DAG (Cloud Composer) — external to this service
- **Frequency**: Daily; date range controlled by `--startDate` and `--endDate` arguments

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Ads Spark Job Framework | Executes the job; reads Hive; hashes data; writes to GCS | `continuumAdsJobframeworkSpark` |
| Groupon Data Lake / Hive (`user_edwprod.fact_gbl_transactions`) | Source of global transaction/order data | `continuumAdsJobframeworkHiveWarehouse` |
| GCS Analytics Bucket | Destination for the order feed TSV | `continuumAdsJobframeworkGcsBucket` |
| Telegraf / Metrics Endpoint | Receives order feed record count gauges | `continuumAdsJobframeworkMetricsEndpoint` |

## Steps

1. **Query bcookie-session orders**: Executes Spark SQL against `user_edwprod.fact_gbl_transactions` selecting `order_uuid` (suffixed `_bc`), `user_uuid`, `transaction_qty`, `deal_uuid`, `price_with_discounts`, `order_date_ts`, `bcookie` for `action = 'authorize'` orders in `--startDate` / `--endDate` range with non-negative discount.
   - From: `continuumAdsJobframeworkSpark`
   - To: `continuumAdsJobframeworkHiveWarehouse`
   - Protocol: Spark SQL

2. **Emit bcookie order count metric**: Publishes `order_feed_bcookie_session_record_count` gauge.
   - From: `continuumAdsJobframeworkSpark`
   - To: `continuumAdsJobframeworkMetricsEndpoint`
   - Protocol: HTTP/Influx

3. **Query consumer-ID-session orders**: Executes a second Spark SQL query against the same table using `user_uuid` as `session_id` (suffixed order ID `_cc`) — creating a second attribution variant for logged-in users.
   - From: `continuumAdsJobframeworkSpark`
   - To: `continuumAdsJobframeworkHiveWarehouse`
   - Protocol: Spark SQL

4. **Emit consumer-ID order count metric**: Publishes `order_feed_ccookie_session_record_count` gauge.
   - From: `continuumAdsJobframeworkSpark`
   - To: `continuumAdsJobframeworkMetricsEndpoint`
   - Protocol: HTTP/Influx

5. **Union and transform**: Unions bcookie and consumer-ID DataFrames; formats `order_date` as `yyyy-MM-dd'T'HH:mm:ss'Z'`; hashes `customer_id` and `session_id` with HMAC-SHA256 using `feeds.secretKey`.
   - From: `continuumAdsJobframeworkSpark`
   - To: local Spark transformation

6. **Emit total order count metric**: Publishes `order_feed_record_count` gauge for the combined union count.
   - From: `continuumAdsJobframeworkSpark`
   - To: `continuumAdsJobframeworkMetricsEndpoint`
   - Protocol: HTTP/Influx

7. **Write feed to GCS**: Coalesces to 1 partition and writes tab-delimited TSV with header to `gs://{bucketName}/user/grp_gdoop_ai_reporting/feed/order/deal` using `SaveMode.Overwrite`.
   - From: `continuumAdsJobframeworkSpark`
   - To: `continuumAdsJobframeworkGcsBucket`
   - Protocol: GCS connector

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Hive query failure | Spark exception propagates; YARN app fails | Job marked failed; previous GCS file unchanged |
| GCS write failure | Spark exception propagates; YARN app fails | Retry is safe (overwrite mode) |
| Zero orders for date range | Job completes with zero records; empty file written | Metric alert on zero count |

## Sequence Diagram

```
Airflow -> AdsJobFrameworkSpark: Trigger OrderFeedJob (--bucketName, --startDate, --endDate)
AdsJobFrameworkSpark -> HiveWarehouse: SELECT (bcookie session) FROM fact_gbl_transactions WHERE action='authorize', ds BETWEEN startDate AND endDate
HiveWarehouse --> AdsJobFrameworkSpark: bcookie orders DataFrame
AdsJobFrameworkSpark -> TelegrafEndpoint: gauge(order_feed_bcookie_session_record_count)
AdsJobFrameworkSpark -> HiveWarehouse: SELECT (consumer-ID session) FROM fact_gbl_transactions WHERE same filters
HiveWarehouse --> AdsJobFrameworkSpark: consumer-ID orders DataFrame
AdsJobFrameworkSpark -> TelegrafEndpoint: gauge(order_feed_ccookie_session_record_count)
AdsJobFrameworkSpark -> AdsJobFrameworkSpark: UNION, format date, HMAC-SHA256 hash customer_id + session_id
AdsJobFrameworkSpark -> TelegrafEndpoint: gauge(order_feed_record_count)
AdsJobFrameworkSpark -> GCSBucket: Write TSV to gs://{bucket}/user/grp_gdoop_ai_reporting/feed/order/deal (overwrite, 1 partition)
GCSBucket --> AdsJobFrameworkSpark: Write success
```

## Related

- Architecture dynamic view: `dynamic-ads-jobframework`
- Related flows: [Customer Feed Export](customer-feed-export.md)
- GCS output path: `gs://{gcp.bucket_name}/user/grp_gdoop_ai_reporting/feed/order/deal`
