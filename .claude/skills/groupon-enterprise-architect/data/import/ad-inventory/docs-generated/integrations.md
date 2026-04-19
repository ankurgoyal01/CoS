---
service: "ad-inventory"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 3
---

# Integrations

## Overview

Ad Inventory maintains four external integrations (Google Ad Manager / DFP, LiveIntent, Rokt, CitrusAd) for ad reporting and click forwarding, plus three internal Groupon platform dependencies (Audience Management Service, SMA Metrics, Email/SMTP). External ad network integrations are polling-based (scheduled batch), not event-driven. All outbound HTTP calls use the JTier OkHttp client.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google Ad Manager (DFP) | HTTP/SOAP | Poll and download ad inventory performance reports | yes | `googleAdManager` |
| LiveIntent | HTTP (REST) | Authenticate and consume LiveIntent ad performance reporting feeds | yes | `liveIntent` |
| Rokt | S3 (AWS) | Download Rokt ad performance report CSVs from S3 bucket | yes | `rokt` |
| CitrusAd | HTTP (REST) | Forward sponsored listing click events for attribution | yes | `citrusAdApi` |

### Google Ad Manager (DFP) Detail

- **Protocol**: HTTP/SOAP via Google Ads API (dfp-axis 4.19.0, ads-lib 4.19.0)
- **Base URL / SDK**: Configured via `dfp.networkCode`, `dfp.appName`, `dfp.jsonKeyFilepath` in service config; service account OAuth2 via JSON key file
- **Auth**: Service account OAuth2 (offline credentials, `OfflineCredentials.Builder` with JSON key)
- **Purpose**: Schedules DFP reports and downloads completed report CSVs for ingestion into the Hive warehouse
- **Failure mode**: `DFPScheduleImportJob` logs errors and marks report instances as failed in MySQL; alert email sent by `ReportMonitoringJob`
- **Circuit breaker**: No evidence found of a circuit breaker; retries controlled by Quartz job re-execution

### LiveIntent Detail

- **Protocol**: HTTP (REST/JSON) via OkHttp
- **Base URL / SDK**: `liveIntent.token_uri` (token endpoint) and `liveIntent.reports_uri` (reports endpoint) — configured in service YAML
- **Auth**: Username/password exchanged for a bearer token via `refreshToken()` on `LiveIntentConfiguration`
- **Purpose**: Downloads LiveIntent ad performance data; `LiveIntentReportTask` transforms and loads into Hive tables
- **Failure mode**: Configuration validation throws `ConfigurationException` on missing credentials at startup
- **Circuit breaker**: No evidence found

### Rokt Detail

- **Protocol**: AWS S3 SDK (aws-java-sdk-s3 1.12.255) against `us-west-2` region
- **Base URL / SDK**: `s3Config.s3BucketName`, `s3Config.accessId`, `s3Config.secretAccessKey` — configured via `rokt` config block (extends `S3Config`)
- **Auth**: AWS static credentials (access ID + secret access key)
- **Purpose**: `S3FileDownloaderTask` downloads Rokt report CSVs, normalizes them, and uploads to GCS for downstream validation and Hive load
- **Failure mode**: Batch job logs failure; report instance status updated in MySQL
- **Circuit breaker**: No evidence found

### CitrusAd Detail

- **Protocol**: HTTP (REST) via OkHttp
- **Base URL / SDK**: `citrusAd.baseUrl` + `citrusAd.reportClickPath` — configured in service YAML
- **Auth**: No auth mechanism found in source; `citrusAd.baseUrl` is a configured base URL
- **Purpose**: `SponsoredListingService` forwards sponsored listing click events to CitrusAd for attribution tracking
- **Failure mode**: Click event still persisted in MySQL; failure to forward to CitrusAd logged but not surfaced to caller
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Audience Management Service (AMS) | HTTP (REST) | Validate and fetch authoritative audience definitions during audience create/update | `continuumAudienceManagementService` |
| SMA Metrics | HTTP | Submit placement counter and click count metrics to the Groupon SMA observability stack | `continuumSmaMetrics` |
| Email Service (SMTP) | SMTP | Send report lifecycle notifications (job started, completed, failed, verification results) | `continuumEmailService` |

### Audience Management Service (AMS) Detail

- **Protocol**: HTTP (REST) via JTier OkHttp client
- **Base URL / SDK**: `amsConfig.na.url` (North America) and `amsConfig.intl.url` (International) — region-specific URLs
- **Auth**: No explicit auth mechanism found beyond URL configuration
- **Purpose**: `AMSClient` fetches audience details to validate audience definitions before persisting them; `AiAudienceResource` calls AMS on every create/update request
- **Failure mode**: Validation failure returns an error to the API caller; audience not persisted

### SMA Metrics Detail

- **Protocol**: HTTP via Groupon SMA SDK
- **Base URL / SDK**: Configured via `smaConfig` block
- **Auth**: Internal service-to-service (no explicit auth found)
- **Purpose**: `SMAMetricsLogger` emits placement and click counters consumed by Wavefront dashboards
- **Failure mode**: Metric emission failure is non-blocking to placement serving

### Email Service (SMTP) Detail

- **Protocol**: SMTP (javax.mail 1.6.2, commons-email 1.3.1)
- **Base URL / SDK**: Configured via `email` config block (`EmailConfiguration`)
- **Auth**: SMTP credentials in service configuration
- **Purpose**: `Emailer` component sends Velocity-templated notification emails for report job events (start, success, failure, verification outcomes)
- **Failure mode**: Email failure logged; does not affect report processing pipeline

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known consumers based on API surface:
>
> - Groupon frontend pages and apps — call `/ai/api/v1/placement` for ad slot content
> - Groupon frontend pages and apps — call `/ai/api/v1/slc/{id}` to record sponsored listing clicks
> - Analytics teams — query Hive tables populated by the report pipeline

## Dependency Health

The service performs startup-time configuration validation (`validateConfiguration()`) for all critical external integrations (DFP, Hive, LiveIntent, Rokt, GCS, Email). Missing required config fields cause a `ConfigurationException` and prevent startup. No runtime circuit breakers or health-check endpoints for downstream dependencies are configured.
