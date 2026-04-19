---
service: "coupons_bi_airflow"
title: "Dimensioning Reference Loads Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "dimensioning-reference-loads"
flow_type: scheduled
trigger: "Airflow cron schedule (periodic)"
participants:
  - "continuumCouponsBiAirflowDags"
  - "GCP Secret Manager"
  - "Google Sheets API"
  - "Teradata"
architecture_ref: "dynamic-continuumCouponsBiAirflow-dimensioning"
---

# Dimensioning Reference Loads Flow

## Summary

This flow loads dimensional reference and lookup tables into Teradata to support BI reporting and data quality. Reference data originates from Google Sheets (analyst-maintained lookup tables) or is computed within the DAG from known constants. DAGs in this group run periodically or on-demand to keep Teradata dimension tables current. These dimension tables serve as the authoritative reference layer for joining and enriching fact data in downstream BI queries.

## Trigger

- **Type**: schedule
- **Source**: Apache Airflow scheduler (Cloud Composer)
- **Frequency**: Periodic (daily or as configured per dimension DAG; some may be manual-trigger)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Coupons BI Airflow DAGs | Orchestrator — schedules and executes dimension load tasks | `continuumCouponsBiAirflowDags` |
| GCP Secret Manager | Credential provider — supplies Google Sheets and Teradata credentials | external |
| Google Sheets API | Reference data source — analyst-maintained lookup spreadsheets | external |
| Teradata | Data target — enterprise warehouse receiving dimension table loads | external |

## Steps

1. **Retrieve credentials**: Airflow task calls GCP Secret Manager to retrieve the Google Sheets service account key and Teradata connection credentials.
   - From: `continuumCouponsBiAirflowDags`
   - To: GCP Secret Manager
   - Protocol: GCP SDK (google-cloud-secret-manager)

2. **Read reference data from Google Sheets**: Extraction task reads analyst-managed lookup tables from Google Sheets using the Sheets API SDK.
   - From: `continuumCouponsBiAirflowDags`
   - To: Google Sheets API
   - Protocol: REST SDK (google-sheets API)

3. **Transform reference data**: Transformation task applies pandas-based normalization and validation to the raw Sheets data, producing a DataFrame conformant to the target Teradata dimension table schema.
   - From: `continuumCouponsBiAirflowDags`
   - To: (in-memory processing)
   - Protocol: pandas (in-process)

4. **Truncate and reload Teradata dimension table**: Load task connects to Teradata via `teradatasql`, truncates the existing dimension table rows (full-refresh pattern), and bulk inserts the new reference data.
   - From: `continuumCouponsBiAirflowDags`
   - To: Teradata
   - Protocol: teradatasql (JDBC-compatible)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Google Sheets API auth error | Airflow task fails; engineer verifies Sheets service account in Secret Manager | Reference data not updated; Teradata dimension table retains prior values |
| Google Sheets data malformed | Transformation task raises exception | DAG fails at transform step; Teradata not modified |
| Teradata connection failure | Airflow task retry; if persistent, DAG run fails | Dimension table not updated; downstream BI queries use stale reference data |
| Teradata truncate/insert error | Airflow task fails mid-load | Partial load risk — table may be empty if truncated before failed insert; engineer must re-trigger |

## Sequence Diagram

```
AirflowScheduler -> CouponsBiAirflowDags: Trigger dimensioning-reference-load DAG (cron)
CouponsBiAirflowDags -> SecretManager: Access secret google-sheets-credentials
SecretManager --> CouponsBiAirflowDags: Return service account key
CouponsBiAirflowDags -> GoogleSheetsAPI: spreadsheets.values.get(spreadsheetId, range)
GoogleSheetsAPI --> CouponsBiAirflowDags: Return reference data rows (JSON)
CouponsBiAirflowDags -> CouponsBiAirflowDags: Transform via pandas to Teradata dimension schema
CouponsBiAirflowDags -> SecretManager: Access Teradata connection credentials
SecretManager --> CouponsBiAirflowDags: Return Teradata credentials
CouponsBiAirflowDags -> Teradata: TRUNCATE dimension_table
Teradata --> CouponsBiAirflowDags: Truncate confirmed
CouponsBiAirflowDags -> Teradata: INSERT INTO dimension_table VALUES (...)
Teradata --> CouponsBiAirflowDags: Insert confirmed
```

## Related

- Architecture dynamic view: `dynamic-continuumCouponsBiAirflow-dimensioning`
- Related flows: [GA4 Ingestion](ga4-ingestion.md), [Affiliate API Ingestion](affiliate-api-ingestion.md), [Search API Ingestion](search-api-ingestion.md)
