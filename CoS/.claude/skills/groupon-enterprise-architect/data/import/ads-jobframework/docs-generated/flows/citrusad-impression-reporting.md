---
service: "ads-jobframework"
title: "CitrusAd Impression Reporting"
generated: "2026-03-03"
type: flow
flow_name: "citrusad-impression-reporting"
flow_type: batch
trigger: "Scheduled hourly via Airflow (Cloud Composer)"
participants:
  - "continuumAdsJobframeworkSpark"
  - "continuumAdsJobframeworkHiveWarehouse"
  - "continuumAdsJobframeworkMetricsEndpoint"
architecture_ref: "dynamic-ads-jobframework"
---

# CitrusAd Impression Reporting

## Summary

This flow runs hourly to collect all sponsored ad impressions recorded in the Groupon Data Lake for the preceding hour and report each distinct ad ID back to CitrusAd via an HTTP GET callback. It covers web/mobile impressions (`eventdestination = 'dealImpression'`) and email impressions (`eventdestination = 'emailClick'` with `event = 'emailOpenHeader'`). The flow is gated by the `--isCitrusReportEnabled` flag, allowing it to run in dry-run mode without posting callbacks.

## Trigger

- **Type**: schedule
- **Source**: Airflow DAG (Cloud Composer) — external to this service
- **Frequency**: Hourly

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Ads Spark Job Framework | Executes the job; queries Hive; posts callbacks | `continuumAdsJobframeworkSpark` |
| Groupon Data Lake / Hive (`grp_gdoop_pde.junoHourly`) | Source of raw impression events | `continuumAdsJobframeworkHiveWarehouse` |
| CitrusAd API (`us-integration.citrusad.com`) | Receives impression callback HTTP GET requests | External — `continuumAdsJobframeworkSpark` -> CitrusAd |
| Telegraf / Metrics Endpoint | Receives impression count gauges and success/failure counters | `continuumAdsJobframeworkMetricsEndpoint` |

## Steps

1. **Calculate time window**: Determines `eventDate` (current date minus 8 hours) and `startTime` / `endTime` epoch milliseconds covering a 1-hour window.
   - From: `continuumAdsJobframeworkSpark` (job startup)
   - To: local computation

2. **Query web/mobile impressions**: Executes Spark SQL against `grp_gdoop_pde.junoHourly` to retrieve distinct `sponsoredadid` values where `eventdestination = 'dealImpression'` and `platform IN ('web', 'mobile')` within the time window.
   - From: `continuumAdsJobframeworkSpark`
   - To: `continuumAdsJobframeworkHiveWarehouse`
   - Protocol: Spark SQL

3. **Emit web/mobile impression count metric**: Publishes `impressions_report_web_mobile_count` gauge to Telegraf.
   - From: `continuumAdsJobframeworkSpark`
   - To: `continuumAdsJobframeworkMetricsEndpoint`
   - Protocol: HTTP/Influx

4. **Post web/mobile impression callbacks** (if `isCitrusReportEnabled = true`): For each distinct ad ID, calls `CitrusAdClient.reportImpression(adId)` which issues `GET https://us-integration.citrusad.com/v1/resource/first-i/{adId}`. Success and failure counts are emitted as `citrus_impressions_report_success` / `citrus_impressions_report_exception`.
   - From: `continuumAdsJobframeworkSpark`
   - To: CitrusAd API (external)
   - Protocol: HTTPS GET

5. **Query email impressions**: Executes Spark SQL against `grp_gdoop_pde.junoHourly` to retrieve distinct `sponsoredadid` where `eventdestination = 'emailClick'` and `event = 'emailOpenHeader'` and `platform = 'email'` within the time window.
   - From: `continuumAdsJobframeworkSpark`
   - To: `continuumAdsJobframeworkHiveWarehouse`
   - Protocol: Spark SQL

6. **Emit email impression count metric**: Publishes `impressions_report_email_count` gauge.
   - From: `continuumAdsJobframeworkSpark`
   - To: `continuumAdsJobframeworkMetricsEndpoint`
   - Protocol: HTTP/Influx

7. **Post email impression callbacks** (if `isCitrusReportEnabled = true`): For each distinct ad ID from email impressions, calls `CitrusAdClient.reportImpression(adId)`.
   - From: `continuumAdsJobframeworkSpark`
   - To: CitrusAd API (external)
   - Protocol: HTTPS GET

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| CitrusAd HTTP error response | Exception caught per ad ID; `citrus_impressions_report_exception` counter incremented; job continues | Callback missed for that ad ID; visible in metrics |
| CitrusAd connection exception | Exception caught per ad ID; counter incremented; job continues | Same as above |
| Hive query failure | Spark exception propagates; YARN application fails | Job marked failed in Airflow; no callbacks sent |
| `isCitrusReportEnabled` not set | `toBoolean` on empty string throws exception; YARN app fails | Job must have flag explicitly set |

## Sequence Diagram

```
Airflow      -> AdsJobFrameworkSpark: Trigger CitrusAdImpressionsReportJob (hourly)
AdsJobFrameworkSpark -> HiveWarehouse: SELECT distinct(sponsoredadid) FROM junoHourly WHERE dealImpression, web/mobile, [T-8h to T-7h]
HiveWarehouse --> AdsJobFrameworkSpark: DataFrame of ad IDs
AdsJobFrameworkSpark -> TelegrafEndpoint: gauge(impressions_report_web_mobile_count)
AdsJobFrameworkSpark -> CitrusAdAPI: GET /v1/resource/first-i/{adId} (per ad ID)
CitrusAdAPI --> AdsJobFrameworkSpark: HTTP 2xx / error
AdsJobFrameworkSpark -> HiveWarehouse: SELECT distinct(sponsoredadid) FROM junoHourly WHERE emailOpenHeader, email, [T-8h to T-7h]
HiveWarehouse --> AdsJobFrameworkSpark: DataFrame of ad IDs
AdsJobFrameworkSpark -> TelegrafEndpoint: gauge(impressions_report_email_count)
AdsJobFrameworkSpark -> CitrusAdAPI: GET /v1/resource/first-i/{adId} (per email ad ID)
CitrusAdAPI --> AdsJobFrameworkSpark: HTTP 2xx / error
```

## Related

- Architecture dynamic view: `dynamic-ads-jobframework`
- Related flows: [CitrusAd Click Reporting](citrusad-click-reporting.md)
- Backfill: `CitrusAdImpressionsReportBackfillJob` (same logic with configurable date/time range)
