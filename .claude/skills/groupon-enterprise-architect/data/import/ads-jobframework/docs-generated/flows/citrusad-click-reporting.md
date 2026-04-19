---
service: "ads-jobframework"
title: "CitrusAd Click Reporting"
generated: "2026-03-03"
type: flow
flow_name: "citrusad-click-reporting"
flow_type: batch
trigger: "Scheduled hourly via Airflow (Cloud Composer)"
participants:
  - "continuumAdsJobframeworkSpark"
  - "continuumAdsJobframeworkHiveWarehouse"
  - "continuumAdsJobframeworkMetricsEndpoint"
architecture_ref: "dynamic-ads-jobframework"
---

# CitrusAd Click Reporting

## Summary

This flow runs hourly to collect all sponsored ad click events recorded in `grp_gdoop_pde.junoHourly` for a configurable delay window and post each distinct ad ID to CitrusAd via an HTTP GET callback. It covers web/mobile clicks (`eventdestination = 'genericClick'`) and email clicks (`eventdestination = 'emailClick'` with `event = 'emailClick'`). The delay parameter allows the job to handle late-arriving data by looking back more than one hour if needed.

## Trigger

- **Type**: schedule
- **Source**: Airflow DAG (Cloud Composer) — external to this service
- **Frequency**: Hourly; lookback controlled by `--delay` argument

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Ads Spark Job Framework | Executes the job; queries Hive; posts click callbacks | `continuumAdsJobframeworkSpark` |
| Groupon Data Lake / Hive (`grp_gdoop_pde.junoHourly`) | Source of raw click events | `continuumAdsJobframeworkHiveWarehouse` |
| CitrusAd API (`us-integration.citrusad.com`) | Receives click callback HTTP GET requests | External |
| Telegraf / Metrics Endpoint | Receives click count gauges and success/failure counters | `continuumAdsJobframeworkMetricsEndpoint` |

## Steps

1. **Calculate time window**: Determines `eventDate` and `startTime` / `endTime` epoch milliseconds for a 1-hour window starting `--delay` hours ago.
   - From: `continuumAdsJobframeworkSpark` (job startup with `--delay` arg)
   - To: local computation

2. **Query web/mobile clicks**: Executes Spark SQL against `grp_gdoop_pde.junoHourly` to retrieve distinct `sponsoredadid` where `eventdestination = 'genericClick'` and `platform IN ('web', 'mobile')` within the time window.
   - From: `continuumAdsJobframeworkSpark`
   - To: `continuumAdsJobframeworkHiveWarehouse`
   - Protocol: Spark SQL

3. **Emit web/mobile click count metric**: Publishes `clicks_report_web_mobile_count` gauge to Telegraf.
   - From: `continuumAdsJobframeworkSpark`
   - To: `continuumAdsJobframeworkMetricsEndpoint`
   - Protocol: HTTP/Influx

4. **Post web/mobile click callbacks** (if `isCitrusReportEnabled = true`): For each distinct ad ID, calls `CitrusAdClient.reportClick(adId)` which issues `GET https://us-integration.citrusad.com/v1/resource/second-c/{adId}`.
   - From: `continuumAdsJobframeworkSpark`
   - To: CitrusAd API (external)
   - Protocol: HTTPS GET

5. **Query email clicks**: Executes Spark SQL against `grp_gdoop_pde.junoHourly` for distinct `sponsoredadid` where `eventdestination = 'emailClick'` and `event = 'emailClick'` and `platform = 'email'` within the time window.
   - From: `continuumAdsJobframeworkSpark`
   - To: `continuumAdsJobframeworkHiveWarehouse`
   - Protocol: Spark SQL

6. **Emit email click count metric**: Publishes `clicks_report_email_count` gauge.
   - From: `continuumAdsJobframeworkSpark`
   - To: `continuumAdsJobframeworkMetricsEndpoint`
   - Protocol: HTTP/Influx

7. **Post email click callbacks** (if `isCitrusReportEnabled = true`): For each distinct ad ID from email clicks, calls `CitrusAdClient.reportClick(adId)`.
   - From: `continuumAdsJobframeworkSpark`
   - To: CitrusAd API (external)
   - Protocol: HTTPS GET

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| CitrusAd HTTP error response | Exception caught per ad ID; `citrus_clicks_report_exception` counter incremented; job continues | Click callback missed for that ad ID; visible in metrics |
| CitrusAd connection exception | Exception caught per ad ID; counter incremented; job continues | Same as above |
| `--delay` not provided | Empty string causes `toInt` exception; YARN app fails | Job must have `--delay` explicitly set |
| Hive query failure | Spark exception propagates; YARN application fails | Job marked failed in Airflow |

## Sequence Diagram

```
Airflow      -> AdsJobFrameworkSpark: Trigger CitrusAdClicksReportJob (--delay N --isCitrusReportEnabled true)
AdsJobFrameworkSpark -> HiveWarehouse: SELECT distinct(sponsoredadid) FROM junoHourly WHERE genericClick, web/mobile, [T-N to T-N+1h]
HiveWarehouse --> AdsJobFrameworkSpark: DataFrame of ad IDs
AdsJobFrameworkSpark -> TelegrafEndpoint: gauge(clicks_report_web_mobile_count)
AdsJobFrameworkSpark -> CitrusAdAPI: GET /v1/resource/second-c/{adId} (per ad ID)
CitrusAdAPI --> AdsJobFrameworkSpark: HTTP 2xx / error
AdsJobFrameworkSpark -> HiveWarehouse: SELECT distinct(sponsoredadid) FROM junoHourly WHERE emailClick, email, [T-N to T-N+1h]
HiveWarehouse --> AdsJobFrameworkSpark: DataFrame of ad IDs
AdsJobFrameworkSpark -> TelegrafEndpoint: gauge(clicks_report_email_count)
AdsJobFrameworkSpark -> CitrusAdAPI: GET /v1/resource/second-c/{adId} (per email ad ID)
CitrusAdAPI --> AdsJobFrameworkSpark: HTTP 2xx / error
```

## Related

- Architecture dynamic view: `dynamic-ads-jobframework`
- Related flows: [CitrusAd Impression Reporting](citrusad-impression-reporting.md)
- Backfill: `CitrusAdClicksReportBackfillJob` (same logic with configurable date/time range)
