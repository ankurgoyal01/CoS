---
service: "ads-jobframework"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 5
---

# Integrations

## Overview

ads-jobframework integrates with three external systems (CitrusAd, DoubleClick/Clarus, Teradata sandbox) via outbound HTTP or JDBC, and five internal Groupon systems via Spark SQL (Hive Data Lake, MySQL ad inventory, GCS, Telegraf metrics, SMTP relay). All integrations are outbound-only or read-from-shared-store — no external system calls into this service.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| CitrusAd API | REST (HTTPS) | Report impression and click callbacks for sponsored listing attribution | yes | `continuumAdsJobframeworkSpark` -> external |
| DoubleClick / Clarus | HTTPS pixel | Report ad impression pings for Clarus campaign measurement | yes | `continuumClarusAdEndpoint` |
| Teradata (sandbox) | Teradata JDBC | Read PPID audience export table for DFP targeting | no | `continuumAdsJobframeworkTeradata` |

### CitrusAd API Detail

- **Protocol**: HTTPS GET (fire-and-forget pixel-style callbacks)
- **Base URL**: `https://us-integration.citrusad.com`
- **Auth**: None observed — ad ID embedded in URL path
- **Purpose**: Notify CitrusAd of impression events (`GET /v1/resource/first-i/{adId}`) and click events (`GET /v1/resource/second-c/{adId}`) for each `sponsoredadid` found in `junoHourly`. Controlled by `--isCitrusReportEnabled` flag at job invocation.
- **Failure mode**: HTTP errors are caught, logged, and counted via `citrus_impressions_report_exception` / `citrus_clicks_report_exception` metrics counters. No automatic retry. Backfill jobs provide manual replay.
- **Circuit breaker**: No circuit breaker implemented

### DoubleClick / Clarus Detail

- **Protocol**: HTTPS GET (impression tracking pixel ping)
- **Base URL (prod)**: `https://ad.doubleclick.net/ddm/trackimp/N6103.275388GROUPONINC/B24778101.292788526;dc_trk_aid=485880052;dc_trk_cid=144162205;...`
- **Auth**: None — full tracking URL with tokens embedded in `clarus.url` config
- **Purpose**: Send impression pings to DoubleClick for Clarus campaign measurement. Triggered by `ClarusAdImpressionsReportJob` and `ClarusAdImpressionsBackfillJob`.
- **Failure mode**: HTTP errors are caught, logged, and counted via `clarus_ad_impressions_report_exception`. No retry.
- **Circuit breaker**: No circuit breaker implemented

### Teradata Sandbox Detail

- **Protocol**: Teradata JDBC (`jdbc:teradata://teradata.groupondev.com/DATABASE=sandbox,DBS_PORT=1025,COP=OFF`)
- **Auth**: Username/password configured in `teraData.tdUser` / `teraData.tdPassword`
- **Purpose**: Full table read of `sandbox.ppid_export` to extract PPID audience members for DFP targeting. Used exclusively by `PPIDAudienceJob`.
- **Failure mode**: `SQLException` propagates and causes job failure; `RuntimeException` is thrown to trigger alerting
- **Circuit breaker**: No circuit breaker implemented

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Groupon Data Lake / Hive | Spark SQL | Read raw event, transaction, user attribute, and taxonomy data; write reporting tables | `continuumAdsJobframeworkHiveWarehouse` |
| MySQL (Ads Job Framework) | JDBC | Read ad inventory and campaign metadata | `continuumAdsJobframeworkMySql` |
| GCS Analytics Bucket | GCS connector (Hadoop) | Write output feeds (customer, order, PPID, max-CPC) | `continuumAdsJobframeworkGcsBucket` |
| Telegraf / Metrics Stack | HTTP/Influx | Publish job counters and gauges for monitoring | `continuumAdsJobframeworkMetricsEndpoint` / `metricsStack` |
| SMTP Relay | SMTP (JavaMail) | Send exception and reconciliation report emails with CSV attachments | `continuumAdsJobframeworkSmtpRelay` / `messagingSaaS` |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Known consumers of outputs produced by ads-jobframework:

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| CitrusAd platform | GCS file poll | Ingests customer and order feed TSV files from GCS for audience and conversion data |
| Internal analytics / BI | Hive SQL | Queries `ai_reporting.pv_with_impressions` and `ai_reporting.sl_imp_clicks` for ads performance reporting |
| Wavefront dashboards | Telegraf / Influx | Consumes metrics emitted by Spark jobs for ops visibility |

## Dependency Health

- **CitrusAd**: Per-request `counter` / `gauge` metrics (`citrus_impressions_report_response_code`, `citrus_clicks_report_response_code`) provide visibility into call success rates. No health-check endpoint or circuit breaker.
- **DoubleClick/Clarus**: Per-request `counter` metric (`clarus_ad_impression_report_response_code`) tracks HTTP response codes. No health-check or circuit breaker.
- **Hive/YARN**: Job-level failure surfaced via YARN application state. Spark retries are not configured at the application level.
- **MySQL**: JDBC connection failures cause job-level exception and YARN failure. No connection pool health check.
- **Teradata**: `SQLException` during query causes `PPIDAudienceJob` to fail with a thrown `RuntimeException`.
- **SMTP**: Email failures are not caught separately — JavaMail exceptions propagate to caller.
