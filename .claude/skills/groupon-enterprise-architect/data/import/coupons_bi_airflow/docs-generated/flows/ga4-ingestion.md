---
service: "coupons_bi_airflow"
title: "GA4 Ingestion Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "ga4-ingestion"
flow_type: scheduled
trigger: "Airflow cron schedule (daily)"
participants:
  - "continuumCouponsBiAirflowDags"
  - "GCP Secret Manager"
  - "GA4 Data API"
  - "GCS"
  - "BigQuery"
architecture_ref: "dynamic-continuumCouponsBiAirflow-ga4"
---

# GA4 Ingestion Flow

## Summary

This flow extracts web analytics and conversion data from the Google Analytics 4 Data API and loads it into BigQuery for Coupons BI reporting. It runs on a daily Airflow schedule, retrieves credentials from GCP Secret Manager, stages raw API responses in GCS, and writes transformed metrics to BigQuery partitioned tables. It is the primary source of traffic, session, and conversion data for the Coupons analytics domain.

## Trigger

- **Type**: schedule
- **Source**: Apache Airflow scheduler (Cloud Composer)
- **Frequency**: Daily (cron-based, specific schedule configured per DAG)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Coupons BI Airflow DAGs | Orchestrator — schedules and executes all tasks | `continuumCouponsBiAirflowDags` |
| GCP Secret Manager | Credential provider — supplies GA4 service account key | external |
| GA4 Data API | Data source — provides web analytics report data | external |
| GCS | Landing zone — stores raw API responses | external |
| BigQuery | Data target — receives transformed analytics metrics | external |

## Steps

1. **Retrieve credentials**: Airflow extraction task calls GCP Secret Manager to fetch the GA4 service account credential.
   - From: `continuumCouponsBiAirflowDags`
   - To: GCP Secret Manager
   - Protocol: GCP SDK (google-cloud-secret-manager)

2. **Request GA4 report data**: Extraction task constructs a GA4 Data API report request for the target date partition and submits it using the `google-analytics-data` v1beta client.
   - From: `continuumCouponsBiAirflowDags`
   - To: GA4 Data API
   - Protocol: REST SDK (google-analytics-data v1beta)

3. **Stage raw response to GCS**: Extraction task writes the raw API response (JSON) to the GCS landing bucket under a date-partitioned path.
   - From: `continuumCouponsBiAirflowDags`
   - To: GCS
   - Protocol: GCP SDK (google-cloud-storage)

4. **Transform staged data**: Transformation task reads the raw JSON from GCS, applies pandas-based transformations to produce a structured DataFrame matching the BigQuery table schema.
   - From: `continuumCouponsBiAirflowDags`
   - To: GCS (read)
   - Protocol: GCP SDK (google-cloud-storage)

5. **Load to BigQuery**: Load task writes the transformed DataFrame to the target BigQuery partitioned table using the `google-cloud-bigquery` client.
   - From: `continuumCouponsBiAirflowDags`
   - To: BigQuery
   - Protocol: GCP SDK (google-cloud-bigquery)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GA4 API returns 429 (rate limit) | Airflow task retry with backoff | Task retries up to configured retry count; DAG run fails if retries exhausted |
| GA4 API returns 401/403 (auth error) | Airflow task fails immediately | DAG run fails; alert fires; engineer must verify secret and re-trigger |
| GCS write fails | Airflow task retry | Task retries; if persistent, DAG run fails and data gap occurs |
| BigQuery load fails | Airflow task retry | Task retries; if persistent, DAG run fails and stale data remains in BigQuery |
| Transformation error (pandas) | Airflow task fails | DAG run fails at transformation step; raw data remains in GCS for inspection |

## Sequence Diagram

```
AirflowScheduler -> CouponsBiAirflowDags: Trigger ga4-ingestion DAG run (daily cron)
CouponsBiAirflowDags -> SecretManager: Access secret ga4-api-credentials
SecretManager --> CouponsBiAirflowDags: Return service account key
CouponsBiAirflowDags -> GA4DataAPI: RunReport(property_id, date_range, dimensions, metrics)
GA4DataAPI --> CouponsBiAirflowDags: Return report rows (JSON)
CouponsBiAirflowDags -> GCS: Write raw JSON to gs://[bucket]/ga4/[date]/raw.json
GCS --> CouponsBiAirflowDags: Write confirmed
CouponsBiAirflowDags -> GCS: Read raw JSON from landing path
GCS --> CouponsBiAirflowDags: Return raw JSON
CouponsBiAirflowDags -> CouponsBiAirflowDags: Transform via pandas to target schema
CouponsBiAirflowDags -> BigQuery: Load DataFrame to ga4_metrics table partition [date]
BigQuery --> CouponsBiAirflowDags: Load job success
```

## Related

- Architecture dynamic view: `dynamic-continuumCouponsBiAirflow-ga4`
- Related flows: [Affiliate API Ingestion](affiliate-api-ingestion.md), [Search API Ingestion](search-api-ingestion.md)
