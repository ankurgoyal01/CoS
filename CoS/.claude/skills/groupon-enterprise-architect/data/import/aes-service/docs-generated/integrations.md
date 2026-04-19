---
service: "aes-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 5
internal_count: 3
---

# Integrations

## Overview

AES integrates with five external ad-platform systems and three internal Groupon systems. External integrations are all outbound: AES pushes audience membership updates to Facebook, Google, Microsoft, and TikTok, and stores temporary export artifacts in GCP Cloud Storage. Internal integrations cover audience metadata (CIA), source customer data (Cerebro/Hive warehouse), and the MBus message bus for GDPR and consent events.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Facebook Ads API | HTTPS/REST | Create custom audiences; upload/delete user lists (email, IDFA); read audience statistics | yes | `facebookAds` |
| Google Ads API | HTTPS/gRPC | Create customer match audiences; add/remove email and device ID members | yes | `googleAds` |
| Microsoft Bing Ads | HTTPS/Bulk API | Upload customer list deltas (email add/delete) | yes | `microsoftAds` |
| TikTok Ads API | HTTPS/REST | Create audience segments; upload/delete user mappings | yes | `tiktokAds` |
| GCP Cloud Storage | GCS API | Store and retrieve temporary export artifact files during pipeline runs | no | `continuumGcpStorage` |

### Facebook Ads API Detail

- **Protocol**: HTTPS/REST
- **SDK**: `FacebookClient` (OkHttp-based); config in `FacebookClientConfig` — `customAudienceUri`, `usersUri`, `audienceStatsUri`
- **Auth**: `accessToken` (configured per ad-account in YAML)
- **Purpose**: Creates Facebook Custom Audiences; uploads hashed email and IDFA member lists in batches; deletes removed members; reads audience size statistics for monitoring
- **Failure mode**: Job sub-status updated to `FACEBOOK_EMAIL_ADD` / `FACEBOOK_EMAIL_DEL` / `FACEBOOK_IDFA_ADD` / `FACEBOOK_IDFA_DEL` error states; job retried up to `audienceJobRetryCount` times; Grafana alert fires after 25 hours of no successful run
- **Circuit breaker**: No evidence found in codebase

### Google Ads API Detail

- **Protocol**: HTTPS/gRPC
- **SDK**: `google-ads` 38.0.0 (`GoogleAdsClientWrapper`, `GoogleClient`)
- **Auth**: OAuth2 — `clientId`, `clientSecret`, `refreshToken`, `developerToken` configured in `GoogleAdsConfig`
- **Purpose**: Creates Customer Match audience lists; adds and removes hashed email and IDFA members per country-specific ad account
- **Failure mode**: Job sub-status transitions to `GOOGLE_*` error states; pipeline retries up to configured limit
- **Circuit breaker**: No evidence found in codebase

### Microsoft Bing Ads Detail

- **Protocol**: HTTPS/Bulk API (JAX-WS / SOAP-based SDK)
- **SDK**: `microsoft.bingads` 13.0.16 (`MicrosoftServiceFactory`)
- **Auth**: OAuth2 — `clientId`, `clientSecret`, `refreshToken`, `developerToken` configured in `MicrosoftClientConfig`
- **Purpose**: Uploads customer list deltas (email add/delete) to Microsoft Audience Network
- **Failure mode**: Job sub-status transitions to `MICROSOFT_EMAIL_ADD` / `MICROSOFT_EMAIL_DEL` error states
- **Circuit breaker**: No evidence found in codebase

### TikTok Ads API Detail

- **Protocol**: HTTPS/REST
- **SDK**: `TikTokClient` / `TikTokSegmentsClient` (OkHttp-based); config in `TikTokClientConfig` — `baseUri`, `apiVersion`, `advertiserId`
- **Auth**: `accessToken` + `appId` + `secret` (HMAC-signed requests)
- **Purpose**: Creates TikTok audience segments; uploads and deletes hashed email and IDFA members
- **Failure mode**: Job sub-status transitions to `TIKTOK_*` error states
- **Circuit breaker**: No evidence found in codebase

### GCP Cloud Storage Detail

- **Protocol**: GCS API (google-cloud-storage 2.52.0 SDK)
- **SDK**: `GcpHelper`; config in `GcpConfig` / `GoogleCloudConfig`
- **Auth**: GCP service account (Workload Identity or key file via `GcpConfig`)
- **Purpose**: Stores temporary export files during `GOOGLECLOUD_DATA_TRANSFER` pipeline stages for Google Cloud audience workflows
- **Failure mode**: Job sub-status transitions to `GOOGLECLOUD_TARGET_UPDATE` / `GOOGLECLOUD_DATA_TRANSFER` error states
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| CIA (Campaign Intelligence & Audiences) | HTTPS/REST | Fetches and creates scheduled/published audience schedules, criteria, and state | `continuumCIAService` |
| Cerebro / Hive Warehouse | JDBC (Hive JDBC 2.0.0 + Hadoop 3.3.0) | Reads source audience datasets (customer ID tables) for NA and EMEA exports; reads IDFA device-ID tables | `continuumCerebroWarehouse` |
| MBus (Groupon Message Bus) | MBus client | Consumes GDPR erasure and consent events | `messageBus` |

### CIA Detail

- **Protocol**: HTTPS/REST (Retrofit-based `CIAApiClient`)
- **Purpose**: When a new scheduled audience is created in AES, AES calls CIA to register or retrieve the corresponding audience schedule. CIA is the authoritative source for audience timing (cron expressions, recurrence rules) and segment definitions.
- **Failure mode**: Job creation fails with `Failed to create or update the scheduled audience in CIA` error; CIA REST call retried; Grafana alert for prolonged failures

### Cerebro / Hive Warehouse Detail

- **Protocol**: JDBC via Hive JDBC 2.0.0; connection managed through Hadoop client 3.3.0
- **Purpose**: Reads AMS Cerebro tables (`amsDatabaseNameNA`, `amsDatabaseNameEMEA`) during the `COPY_EXPORT_DATA` pipeline stage to obtain raw audience customer ID records; also used for daily IDFA import
- **Failure mode**: Query timeouts historically caused job failures — mitigated by pre-importing device IDs into the S2S database (UpdateIdfaTablesJob)

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Display Wizard UI | HTTPS/REST | Marketing team interface for creating and managing scheduled audience configurations |
| GDPR Deletion Pipeline | HTTPS/REST | Calls `DELETE /api/v1/utils/erasure/deleteCustomer/{customerId}` and `deleteCerebro/{customerId}` |
| Internal admin / automation | HTTPS/REST | Manual audience job execution, cache refresh, trigger recovery |

## Dependency Health

- **CIA**: Monitored via Grafana alerts tagged `aes-service`. ELK log queries track CIA call failures.
- **Facebook/Google/Microsoft/TikTok**: Job-level retry with up to `audienceJobRetryCount` attempts at `audienceJobRetryInterval` intervals. Grafana alerts fire when an audience has not run successfully in 25 hours.
- **Cerebro**: No circuit breaker. Timeout-prone queries mitigated by pre-importing data into S2S database.
- **MBus**: Monitored via MBus Elk dashboard and Wavefront Account Erased Topic Dashboard.
