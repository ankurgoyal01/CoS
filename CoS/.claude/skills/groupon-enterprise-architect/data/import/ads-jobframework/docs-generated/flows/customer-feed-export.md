---
service: "ads-jobframework"
title: "Customer Feed Export"
generated: "2026-03-03"
type: flow
flow_name: "customer-feed-export"
flow_type: batch
trigger: "Scheduled daily via Airflow (Cloud Composer)"
participants:
  - "continuumAdsJobframeworkSpark"
  - "continuumAdsJobframeworkHiveWarehouse"
  - "continuumAdsJobframeworkGcsBucket"
  - "continuumAdsJobframeworkMetricsEndpoint"
architecture_ref: "dynamic-ads-jobframework"
---

# Customer Feed Export

## Summary

This flow produces a daily hashed customer demographic feed for CitrusAd audience targeting. It reads global user attribute data from `cia_realtime.user_attrs_gbl`, filters to active customers who purchased within the last 365 days, hashes consumer IDs using HMAC-SHA256, maps country codes to full names, and writes a tab-delimited CSV to GCS. CitrusAd polls the GCS bucket to ingest the feed for customer audience matching.

## Trigger

- **Type**: schedule
- **Source**: Airflow DAG (Cloud Composer) — external to this service
- **Frequency**: Daily

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Ads Spark Job Framework | Executes the job; reads Hive; hashes data; writes to GCS | `continuumAdsJobframeworkSpark` |
| Groupon Data Lake / Hive (`cia_realtime.user_attrs_gbl`) | Source of global customer demographic attributes | `continuumAdsJobframeworkHiveWarehouse` |
| GCS Analytics Bucket | Destination for the customer feed TSV | `continuumAdsJobframeworkGcsBucket` |
| Telegraf / Metrics Endpoint | Receives customer feed record count gauge | `continuumAdsJobframeworkMetricsEndpoint` |

## Steps

1. **Query customer attributes**: Executes Spark SQL against `cia_realtime.user_attrs_gbl` selecting `consumer_id`, `age`, `gender`, `last_billing_zip`, `zip_code`, `rel_primary_consumer_division`, `country_code` for records where `record_date = date_sub(current_date, 2)` and `last_purchase_date >= date_sub(current_date, 365)`.
   - From: `continuumAdsJobframeworkSpark`
   - To: `continuumAdsJobframeworkHiveWarehouse`
   - Protocol: Spark SQL

2. **Emit record count metric**: Publishes `customer_feed_record_count` gauge with the number of matching customer rows.
   - From: `continuumAdsJobframeworkSpark`
   - To: `continuumAdsJobframeworkMetricsEndpoint`
   - Protocol: HTTP/Influx

3. **Transform data**: Applies Spark UDFs to hash `consumer_id` with HMAC-SHA256 using `feeds.secretKey`; converts `age` to `year_of_birth`; normalizes gender codes to `MALE`/`FEMALE`/`UNDEFINED`/`OTHER`; maps country codes to full country names; wraps `country_code` in JSON object format as `target_data`.
   - From: `continuumAdsJobframeworkSpark`
   - To: local Spark transformation

4. **Write feed to GCS**: Coalesces to 10 partitions and writes tab-delimited TSV with header to `gs://{bucketName}/user/grp_gdoop_ai_reporting/feed/customer` using `SaveMode.Overwrite`.
   - From: `continuumAdsJobframeworkSpark`
   - To: `continuumAdsJobframeworkGcsBucket`
   - Protocol: GCS connector (Hadoop FileSystem)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Hive query failure (table unavailable) | Spark exception propagates; YARN app fails | Job marked failed in Airflow; previous GCS feed file is unchanged (overwrite not reached) |
| GCS write failure | Spark exception propagates; YARN app fails | GCS file may be partially written; Airflow retry can rerun (overwrite is idempotent) |
| Zero customers returned | Job completes with count = 0; empty file written to GCS | Metric alert on zero count |

## Sequence Diagram

```
Airflow -> AdsJobFrameworkSpark: Trigger CustomerFeedJob (--bucketName grpn-dnd-prod-analytics-grp-ai-reporting)
AdsJobFrameworkSpark -> HiveWarehouse: SELECT consumer_id, age, gender, zip, country_code FROM user_attrs_gbl WHERE record_date=D-2 AND last_purchase_date>=D-365
HiveWarehouse --> AdsJobFrameworkSpark: Customer DataFrame
AdsJobFrameworkSpark -> TelegrafEndpoint: gauge(customer_feed_record_count)
AdsJobFrameworkSpark -> AdsJobFrameworkSpark: Hash consumer_id (HMAC-SHA256), normalize demographics, map country names
AdsJobFrameworkSpark -> GCSBucket: Write TSV to gs://{bucket}/user/grp_gdoop_ai_reporting/feed/customer (overwrite, 10 partitions)
GCSBucket --> AdsJobFrameworkSpark: Write success
```

## Related

- Architecture dynamic view: `dynamic-ads-jobframework`
- Related flows: [Order Feed Export](order-feed-export.md)
- GCS output path: `gs://{gcp.bucket_name}/user/grp_gdoop_ai_reporting/feed/customer`
