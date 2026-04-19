---
service: "coupons_bi_airflow"
title: "Search API Ingestion Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "search-api-ingestion"
flow_type: scheduled
trigger: "Airflow cron schedule (daily)"
participants:
  - "continuumCouponsBiAirflowDags"
  - "GCP Secret Manager"
  - "AccuRanker API"
  - "Google Search Console API"
  - "GCS"
  - "BigQuery"
architecture_ref: "dynamic-continuumCouponsBiAirflow-search"
---

# Search API Ingestion Flow

## Summary

This flow extracts organic search performance data from AccuRanker (keyword ranking) and Google Search Console (impressions, clicks, CTR, position) on a daily schedule and loads it into BigQuery. It provides the SEO performance dataset that underpins Coupons search visibility reporting. Each source operates as a separate DAG following the extract-stage-transform-load pattern.

## Trigger

- **Type**: schedule
- **Source**: Apache Airflow scheduler (Cloud Composer)
- **Frequency**: Daily (cron-based, specific schedule configured per DAG)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Coupons BI Airflow DAGs | Orchestrator — schedules and executes all tasks | `continuumCouponsBiAirflowDags` |
| GCP Secret Manager | Credential provider — supplies AccuRanker API key and Search Console service account | external |
| AccuRanker API | Data source — provides keyword ranking position data | external |
| Google Search Console API | Data source — provides organic search impression and click data | external |
| GCS | Landing zone — stores raw API responses | external |
| BigQuery | Data target — receives structured search metrics | external |

## Steps

1. **Retrieve credentials**: Airflow extraction task calls GCP Secret Manager to fetch the API key (AccuRanker) or service account key (Search Console) for the target search data source.
   - From: `continuumCouponsBiAirflowDags`
   - To: GCP Secret Manager
   - Protocol: GCP SDK (google-cloud-secret-manager)

2. **Request search data**: Extraction task calls the AccuRanker REST API or Google Search Console API for the target date range, retrieving ranking positions or impression/click metrics respectively.
   - From: `continuumCouponsBiAirflowDags`
   - To: AccuRanker API or Google Search Console API
   - Protocol: REST / REST SDK (google-search-console)

3. **Stage raw response to GCS**: Extraction task writes the API response to the GCS landing bucket under a source- and date-partitioned path.
   - From: `continuumCouponsBiAirflowDags`
   - To: GCS
   - Protocol: GCP SDK (google-cloud-storage)

4. **Transform staged data**: Transformation task reads raw data from GCS and applies pandas transformations to normalize keyword, URL, and metric fields to the target BigQuery schema.
   - From: `continuumCouponsBiAirflowDags`
   - To: GCS (read)
   - Protocol: GCP SDK (google-cloud-storage)

5. **Load to BigQuery**: Load task writes the transformed DataFrame to the target search metrics BigQuery table partition.
   - From: `continuumCouponsBiAirflowDags`
   - To: BigQuery
   - Protocol: GCP SDK (google-cloud-bigquery)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AccuRanker API returns auth error | Airflow task fails; engineer verifies API key | SEO ranking data missing for the day |
| Search Console API quota exceeded | Airflow task retry with backoff | Task retries; if quota not restored, data gap for the period |
| GCS write fails | Airflow task retry | Task retries; if persistent, DAG run fails |
| BigQuery load fails | Airflow task retry | Task retries; if persistent, search data unavailable for reporting |
| Malformed API response | Transformation task raises exception | DAG fails at transform step; raw file in GCS for debugging |

## Sequence Diagram

```
AirflowScheduler -> CouponsBiAirflowDags: Trigger search-ingestion DAG (daily cron)
CouponsBiAirflowDags -> SecretManager: Access secret accuranker-api-key
SecretManager --> CouponsBiAirflowDags: Return API key
CouponsBiAirflowDags -> AccuRankerAPI: GET /keywords/rankings?date=[date]
AccuRankerAPI --> CouponsBiAirflowDags: Return keyword rankings (JSON)
CouponsBiAirflowDags -> GCS: Write raw JSON to gs://[bucket]/accuranker/[date]/raw.json
GCS --> CouponsBiAirflowDags: Write confirmed
CouponsBiAirflowDags -> SecretManager: Access secret search-console-credentials
SecretManager --> CouponsBiAirflowDags: Return service account key
CouponsBiAirflowDags -> SearchConsoleAPI: Query searchAnalytics.query(date, dimensions, metrics)
SearchConsoleAPI --> CouponsBiAirflowDags: Return impressions, clicks, CTR, position (JSON)
CouponsBiAirflowDags -> GCS: Write raw JSON to gs://[bucket]/search_console/[date]/raw.json
GCS --> CouponsBiAirflowDags: Write confirmed
CouponsBiAirflowDags -> GCS: Read both raw files
GCS --> CouponsBiAirflowDags: Return raw data
CouponsBiAirflowDags -> CouponsBiAirflowDags: Transform via pandas to search_metrics schema
CouponsBiAirflowDags -> BigQuery: Load DataFrame to search_metrics table partition [date]
BigQuery --> CouponsBiAirflowDags: Load job success
```

## Related

- Architecture dynamic view: `dynamic-continuumCouponsBiAirflow-search`
- Related flows: [GA4 Ingestion](ga4-ingestion.md), [Affiliate API Ingestion](affiliate-api-ingestion.md)
