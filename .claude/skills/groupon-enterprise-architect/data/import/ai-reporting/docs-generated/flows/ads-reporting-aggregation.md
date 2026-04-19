---
service: "ai-reporting"
title: "Ads Reporting Aggregation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "ads-reporting-aggregation"
flow_type: synchronous
trigger: "Merchant dashboard requests GET /api/v1/reports, or Quartz scheduler triggers vendor report download jobs"
participants:
  - "continuumAiReportingService_restApi"
  - "continuumAiReportingService_reportsService"
  - "continuumAiReportingService_scheduler"
  - "continuumAiReportingService_citrusAdReportsImportService"
  - "continuumAiReportingService_bigQueryClient"
  - "continuumAiReportingService_gcsClient"
  - "continuumAiReportingService_liveIntentClient"
  - "continuumAiReportingService_roktClient"
  - "continuumAiReportingService_hiveAnalytics"
  - "continuumAiReportingService_mysqlRepositories"
  - "continuumAiReportingMySql"
  - "continuumAiReportingBigQuery"
  - "continuumAiReportingGcs"
  - "continuumAiReportingHive"
  - "liveIntent"
  - "rokt"
  - "googleAdManager"
architecture_ref: "dynamic-ads-reporting-aggregation"
---

# Ads Reporting Aggregation

## Summary

This flow covers two related sub-flows: the scheduled ingestion of vendor performance reports (CitrusAd via GCS, LiveIntent, Rokt, Google Ad Manager) and the synchronous serving of aggregated dashboard data to the merchant via the `/api/v1/reports` endpoint. The Quartz scheduler handles the bulk of data ingestion and storage into BigQuery and MySQL; the REST path then reads from these stores to serve real-time dashboard requests.

## Trigger

- **Type**: api-call (dashboard request) or schedule (vendor report download)
- **Source**: GET `/api/v1/reports` (merchant dashboard) or Quartz scheduler
- **Frequency**: Dashboard: on-demand; Report downloads: scheduled (typically daily)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| REST API Layer | Receives and serves dashboard report requests | `continuumAiReportingService_restApi` |
| Ads Reports Service | Aggregates vendor reports and assembles dashboard response | `continuumAiReportingService_reportsService` |
| Quartz Scheduler | Triggers scheduled report download jobs | `continuumAiReportingService_scheduler` |
| CitrusAd Reports Import Service | Downloads and reconciles CitrusAd billing/performance reports | `continuumAiReportingService_citrusAdReportsImportService` |
| BigQuery Client | Queries CitrusAd analytics datasets for dashboard | `continuumAiReportingService_bigQueryClient` |
| GCS Client | Downloads report files from GCS | `continuumAiReportingService_gcsClient` |
| LiveIntent Client | Retrieves LiveIntent campaign performance data | `continuumAiReportingService_liveIntentClient` |
| Rokt Client | Retrieves Rokt campaign performance data | `continuumAiReportingService_roktClient` |
| Hive Analytics Executor | Runs Hive queries for advisor and audience analytics | `continuumAiReportingService_hiveAnalytics` |
| MySQL JDBI Repositories | Reads reconciled billing and campaign metrics | `continuumAiReportingService_mysqlRepositories` |
| AI Reporting MySQL | Stores reconciled billing and campaign metrics | `continuumAiReportingMySql` |
| AI Reporting BigQuery | Stores CitrusAd analytics and wallet analytics | `continuumAiReportingBigQuery` |
| AI Reporting GCS | Stores downloaded CitrusAd report files | `continuumAiReportingGcs` |
| AI Reporting Hive | Analytics warehouse for advisor/audience data | `continuumAiReportingHive` |
| LiveIntent | External ad partner — performance data source | `liveIntent` |
| Rokt | External ad partner — performance data source | `rokt` |
| Google Ad Manager | External ad network — inventory and performance reports | `googleAdManager` |

## Steps

### Scheduled: Vendor Report Download (background)

1. **Scheduler triggers CitrusAd report download**: Quartz fires the CitrusAd report ingestion job
   - From: `continuumAiReportingService_scheduler`
   - To: `continuumAiReportingService_citrusAdReportsImportService`
   - Protocol: direct (in-process)

2. **Downloads CitrusAd report files from GCS**: Fetches billing and performance report files deposited by CitrusAd
   - From: `continuumAiReportingService_citrusAdReportsImportService`
   - To: `continuumAiReportingGcs` via `continuumAiReportingService_gcsClient`
   - Protocol: GCS SDK

3. **Reconciles billing and updates MySQL**: Compares billed spend with wallet ledger; stores reconciliation records
   - From: `continuumAiReportingService_citrusAdReportsImportService`
   - To: `continuumAiReportingMySql` via `continuumAiReportingService_mysqlRepositories`
   - Protocol: JDBI

4. **Loads CitrusAd analytics to BigQuery**: Writes reconciled impressions, clicks, and spend metrics to BigQuery
   - From: `continuumAiReportingService_citrusAdReportsImportService`
   - To: `continuumAiReportingBigQuery` via `continuumAiReportingService_bigQueryClient`
   - Protocol: BigQuery SDK

5. **Scheduler triggers Hive analytics table creation**: Quartz runs Hive JDBC jobs to prepare advisor/audience analytics tables
   - From: `continuumAiReportingService_scheduler`
   - To: `continuumAiReportingHive` via `continuumAiReportingService_hiveAnalytics`
   - Protocol: Hive JDBC

### Synchronous: Dashboard Report Request

1. **Receives report request**: Merchant dashboard sends GET `/api/v1/reports` with filters (date range, campaign IDs)
   - From: `Merchant Dashboard`
   - To: `continuumAiReportingService_restApi`
   - Protocol: REST (HTTPS/JSON)

2. **Queries CitrusAd analytics from BigQuery**: Ads Reports Service runs analytics query for CitrusAd metrics
   - From: `continuumAiReportingService_reportsService`
   - To: `continuumAiReportingBigQuery` via `continuumAiReportingService_bigQueryClient`
   - Protocol: BigQuery SDK

3. **Fetches LiveIntent performance**: Calls LiveIntent API for campaign performance data
   - From: `continuumAiReportingService_reportsService`
   - To: `liveIntent` via `continuumAiReportingService_liveIntentClient`
   - Protocol: HTTPS/JSON

4. **Fetches Rokt performance**: Calls Rokt API for campaign performance and billing data
   - From: `continuumAiReportingService_reportsService`
   - To: `rokt` via `continuumAiReportingService_roktClient`
   - Protocol: HTTPS/JSON

5. **Fetches Google Ad Manager report**: Retrieves GAM ad inventory and performance data via Google Ads SDK
   - From: `continuumAiReportingService_reportsService`
   - To: `googleAdManager`
   - Protocol: Google Ads SDK (HTTPS)

6. **Fetches vendor report files from GCS**: Reads any downloaded vendor report files needed for dashboard assembly
   - From: `continuumAiReportingService_reportsService`
   - To: `continuumAiReportingGcs` via `continuumAiReportingService_gcsClient`
   - Protocol: GCS SDK

7. **Aggregates and returns dashboard response**: Combines CitrusAd, LiveIntent, Rokt, and GAM metrics into unified report response
   - From: `continuumAiReportingService_restApi`
   - To: `Merchant Dashboard`
   - Protocol: REST (HTTPS/JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| CitrusAd report file missing in GCS | Reconciliation skipped for that cycle; Slack alert fired | Dashboard data may be stale until next successful download |
| BigQuery load failure | Logged; MySQL billing data still updated | Analytics may lag; dashboard falls back to MySQL data |
| LiveIntent API unavailable | Partial report returned; LiveIntent section marked unavailable | Dashboard still shows CitrusAd and other vendor data |
| Rokt API unavailable | Partial report returned; Rokt section marked unavailable | Dashboard still shows other vendor data |
| GAM API unavailable | Partial report returned; GAM section omitted | Dashboard still shows CitrusAd and other vendor data |
| Hive JDBC query failure | Job retried on next Quartz cycle | Advisor/audience analytics table creation deferred |

## Sequence Diagram

```
Note over scheduler: Scheduled background ingestion
scheduler -> citrusAdReportsImportService: triggerReportDownload()
citrusAdReportsImportService -> gcsClient: downloadReportFile(gcsPath)
gcsClient -> continuumAiReportingGcs: GCS GET
citrusAdReportsImportService -> mysqlRepositories: storeReconciliation(data)
citrusAdReportsImportService -> bigQueryClient: loadMetrics(dataset, rows)
bigQueryClient -> continuumAiReportingBigQuery: BigQuery INSERT

scheduler -> hiveAnalytics: createAnalyticsTables()
hiveAnalytics -> continuumAiReportingHive: Hive JDBC DDL/DML

Note over restApi: Synchronous dashboard request
MerchantDashboard -> restApi: GET /api/v1/reports?from=...&to=...
restApi -> reportsService: getAggregatedReport(filters)
reportsService -> bigQueryClient: queryMetrics(campaignIds, dateRange)
bigQueryClient -> continuumAiReportingBigQuery: BigQuery SELECT
reportsService -> liveIntentClient: getPerformance(dateRange)
liveIntentClient -> liveIntent: HTTPS GET
liveIntent --> liveIntentClient: performance data
reportsService -> roktClient: getPerformance(dateRange)
roktClient -> rokt: HTTPS GET
rokt --> roktClient: performance data
reportsService -> gcsClient: fetchVendorReportFile(gcsPath)
reportsService -> reportsService: aggregateVendorData()
restApi --> MerchantDashboard: 200 OK (unified report)
```

## Related

- Architecture dynamic view: `dynamic-ads-reporting-aggregation`
- Related flows: [Merchant Wallet Top-up and Spend](merchant-wallet-topup-and-spend.md), [CitrusAd Feed Transport and Sync](citrusad-feed-transport-and-sync.md)
