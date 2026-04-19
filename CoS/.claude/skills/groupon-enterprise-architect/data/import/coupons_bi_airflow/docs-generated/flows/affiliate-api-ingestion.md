---
service: "coupons_bi_airflow"
title: "Affiliate API Ingestion Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "affiliate-api-ingestion"
flow_type: scheduled
trigger: "Airflow cron schedule (daily)"
participants:
  - "continuumCouponsBiAirflowDags"
  - "GCP Secret Manager"
  - "AffJet API"
  - "CJ API"
  - "GCS"
  - "BigQuery"
architecture_ref: "dynamic-continuumCouponsBiAirflow-affiliate"
---

# Affiliate API Ingestion Flow

## Summary

This flow extracts affiliate network performance data from AffJet and Commission Junction (CJ) APIs on a daily schedule and loads it into BigQuery for Coupons affiliate revenue reporting. Each affiliate source has its own DAG, but both follow the same extract-stage-transform-load pattern: credentials from Secret Manager, raw data landed to GCS, transformed via pandas, and written to BigQuery.

## Trigger

- **Type**: schedule
- **Source**: Apache Airflow scheduler (Cloud Composer)
- **Frequency**: Daily (cron-based, specific schedule configured per DAG)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Coupons BI Airflow DAGs | Orchestrator — schedules and executes all tasks | `continuumCouponsBiAirflowDags` |
| GCP Secret Manager | Credential provider — supplies affiliate API keys | external |
| AffJet API | Data source — provides affiliate network performance metrics | external |
| CJ API | Data source — provides Commission Junction commission and click data | external |
| GCS | Landing zone — stores raw API responses | external |
| BigQuery | Data target — receives structured affiliate metrics | external |

## Steps

1. **Retrieve API key**: Airflow extraction task calls GCP Secret Manager to fetch the API key for the target affiliate source (AffJet or CJ).
   - From: `continuumCouponsBiAirflowDags`
   - To: GCP Secret Manager
   - Protocol: GCP SDK (google-cloud-secret-manager)

2. **Request affiliate performance data**: Extraction task calls the AffJet or CJ REST API with the target date range and retrieves commission, click, and order data.
   - From: `continuumCouponsBiAirflowDags`
   - To: AffJet API or CJ API
   - Protocol: REST (HTTPS)

3. **Stage raw response to GCS**: Extraction task writes the raw API response to the GCS landing bucket under a date-partitioned path specific to the affiliate source.
   - From: `continuumCouponsBiAirflowDags`
   - To: GCS
   - Protocol: GCP SDK (google-cloud-storage)

4. **Transform staged data**: Transformation task reads raw data from GCS and applies pandas transformations to normalize fields and produce a schema-conformant DataFrame.
   - From: `continuumCouponsBiAirflowDags`
   - To: GCS (read)
   - Protocol: GCP SDK (google-cloud-storage)

5. **Load to BigQuery**: Load task writes the transformed DataFrame to the target affiliate performance BigQuery table partition.
   - From: `continuumCouponsBiAirflowDags`
   - To: BigQuery
   - Protocol: GCP SDK (google-cloud-bigquery)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Affiliate API returns auth error (401/403) | Airflow task fails immediately | DAG run fails; engineer must verify API key in Secret Manager and re-trigger |
| Affiliate API returns 429 (rate limit) | Airflow task retry with backoff | Task retries up to configured retry count |
| GCS write fails | Airflow task retry | Task retries; if persistent, DAG run fails |
| BigQuery load fails | Airflow task retry | Task retries; if persistent, affiliate data for the day is missing |
| API returns empty/malformed response | Transformation task raises exception | DAG run fails at transformation step; raw file in GCS for inspection |

## Sequence Diagram

```
AirflowScheduler -> CouponsBiAirflowDags: Trigger affiliate-ingestion DAG (daily cron)
CouponsBiAirflowDags -> SecretManager: Access secret affjet-api-key or cj-api-key
SecretManager --> CouponsBiAirflowDags: Return API key
CouponsBiAirflowDags -> AffJetAPI: GET /reports?date=[date]&metrics=clicks,commissions
AffJetAPI --> CouponsBiAirflowDags: Return performance data (JSON/CSV)
CouponsBiAirflowDags -> GCS: Write raw response to gs://[bucket]/affjet/[date]/raw
GCS --> CouponsBiAirflowDags: Write confirmed
CouponsBiAirflowDags -> GCS: Read raw response
GCS --> CouponsBiAirflowDags: Return raw data
CouponsBiAirflowDags -> CouponsBiAirflowDags: Transform via pandas to affiliate_metrics schema
CouponsBiAirflowDags -> BigQuery: Load DataFrame to affiliate_metrics table partition [date]
BigQuery --> CouponsBiAirflowDags: Load job success
```

## Related

- Architecture dynamic view: `dynamic-continuumCouponsBiAirflow-affiliate`
- Related flows: [GA4 Ingestion](ga4-ingestion.md), [Search API Ingestion](search-api-ingestion.md)
