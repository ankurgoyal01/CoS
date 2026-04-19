---
service: "sem-gcp-pipelines"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 7
internal_count: 7
---

# Integrations

## Overview

sem-gcp-pipelines integrates with 7 external ad-platform systems and 7 internal Groupon services. All outbound calls use either Groupon's internal mTLS HTTP client (`hburllib`) for internal services, standard `requests` with HMAC signing for Databreakers, or SFTP/platform-native APIs for external ad systems. There are no inbound integrations — the service is always the caller, never the callee.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google Ads | Spark / API | Syncs SEM keyword and campaign feeds | yes | `googleAds` |
| Facebook Ads | Spark / API | Syncs Facebook Location and Display feeds per country | yes | `facebookAds` |
| Google Places | Spark / API | Syncs Groupon merchant data to Google Places | yes | `googlePlaces` |
| Google Things To Do | SFTP | Delivers Things To Do product feed via MDS dispatcher | yes | `googleThingsToDo_b74080` |
| Google Appointment Services | Spark / API | Delivers appointment entity and action feeds | yes | `googleAppointment_ffa189` |
| CSS Affiliates | Spark / API | Delivers CSS product feeds for EU markets | yes | `cssAffiliates_59280e` |
| Search Ads 360 (SA360) | Spark / API | Syncs SA360 feed and campaign data | yes | `searchAds360_9fc4fa` |

### Google Ads Detail

- **Protocol**: Spark job (Java, `com.groupon.transam.CommonJob`) + Google Ads API
- **Base URL / SDK**: Managed inside `sem-common-jobs` JAR (`gs://grpn-dnd-prod-analytics-grp-sem-group/user/grp_gdoop_sem_group/jars/sem-common-jobs-2.132.jar`)
- **Auth**: Credentials loaded from GCP Secret Manager (`sem_common_jobs` secret)
- **Purpose**: Generates and uploads SEM feed data (keywords, bids, campaign structures) to Google Ads for SEM program management
- **Failure mode**: Spark job fails; Airflow DAG marks task failed; PagerDuty alert triggered via `trigger_event` callback
- **Circuit breaker**: No — relies on Airflow retry logic (0-1 retries depending on DAG)

### Facebook Ads Detail

- **Protocol**: Spark job (Java, `com.groupon.transam.spark.facebook.location.FaceBookLocationProcessor` and `FacebookDisplayProcessor`)
- **Base URL / SDK**: Managed inside `sem-common-jobs` JAR
- **Auth**: Credentials loaded from GCP Secret Manager (`sem_common_jobs` secret)
- **Purpose**: Generates Facebook Location feeds (US, DE, AU, PL, ES — 4x daily) and Facebook Display feeds (13 countries — 3x daily)
- **Failure mode**: Spark job fails; Airflow task retries 0 times; PagerDuty alert
- **Circuit breaker**: No

### Google Places Detail

- **Protocol**: Spark job (Java, `com.groupon.transam.spark.googleplaces.GooglePlacesProcessor`)
- **Base URL / SDK**: Managed inside `sem-common-jobs` JAR; Python client reads place data via `googlePlaces` API
- **Auth**: Credentials via GCP Secret Manager
- **Purpose**: Fetches and syncs Groupon merchant location data to Google Places for 13 countries (daily at 04:00 UTC)
- **Failure mode**: Spark job fails; Airflow task retries 1 time
- **Circuit breaker**: No

### Google Things To Do Detail

- **Protocol**: PySpark + SFTP upload via MDS dispatcher
- **Base URL / SDK**: `MDS_FEED_HOST: mds-feed.production.service` — `/dispatcher/feed/{uuid}` and `/dispatcher/batch/{uuid}`; SFTP user `feeds-zk06ag`
- **Auth**: MDS via internal mTLS (`hburllib`); SFTP credentials from GCP Secret Manager
- **Purpose**: Splits and delivers Google Things To Do (GTTD) product feed files (5,000 rows per file), dispatched twice daily (08:00 and 18:00 UTC)
- **Failure mode**: PySpark job fails; DAG retries 1 time
- **Circuit breaker**: No

### Google Appointment Services Detail

- **Protocol**: Spark job (Java, `com.groupon.transam.spark.gas.GoogleAppoitnmentProcessor` and `GoogleAppointmentUploadProcessor`)
- **Base URL / SDK**: Managed inside `sem-common-jobs` JAR
- **Auth**: Credentials via GCP Secret Manager
- **Purpose**: Generates Google Appointment entity feeds and action feeds for global markets (daily at 06:00 UTC for feed generation; 08:15 UTC for upload)
- **Failure mode**: Spark job fails; 0 retries
- **Circuit breaker**: No

### CSS Affiliates Detail

- **Protocol**: Spark job (Java, `com.groupon.transam.spark.css.CssProcessor`)
- **Base URL / SDK**: Managed inside `sem-common-jobs` JAR
- **Auth**: Credentials via GCP Secret Manager
- **Purpose**: Generates CSS (Comparison Shopping Service) affiliate product feeds for 9 EU markets (DE, IT, IE, BE, NL, FR, ES, UK, PL — daily at 10:00 UTC)
- **Failure mode**: Spark job fails; 0 retries
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Catalog Service | REST / mTLS | Fetches deal metadata via `GET /deal_catalog/v2/deals/{uuid}?clientId={id}` | `continuumDealCatalogService` |
| Marketing Deal Service (MDS) | REST / mTLS | Dispatches feeds (`GET /dispatcher/feed/{uuid}`), fetches batches (`GET /batches/feed/{uuid}`), uploads reports (`POST uploads/rich_relevance`) | `continuumMarketingDealService` |
| GAPI Service | REST / mTLS | Fetches deal details for US/CA via `GET /api/mobile/{country}/deals/{uuid}` (NA URL) and EMEA countries | `gapiService_76fbb4` |
| Databreakers Service | REST / HTTPS (HMAC) | Fetches deal info (`GET /v1/{account}/items/{uuid}`) and search recommendations via individualizer API | `databreakersService_eb0ade` |
| Denylisting Service | REST / mTLS | Loads recently denylisted SEM keyword terms via `GET /denylist/{country}/sem-keywords/?start_at=&end_at=` | `denylistingService_5997c8` |
| Keyword Service | REST / mTLS | Deletes keywords via `DELETE deals/keywords` | `keywordService_a38496` |
| Message Bus | STOMP | Publishes keyword submission messages (deal_id, keywords, country, user) | `messageBus` |

### Deal Catalog Service Detail

- **Protocol**: REST over mTLS via `hburllib`
- **Base URL / SDK**: `hburllib` NA URL — `/deal_catalog/v2/deals/{deal_uuid}?clientId={client_id}`
- **Auth**: mTLS via `tls--transam-sem-gcp-pipelines` service identity
- **Purpose**: Retrieves deal metadata (title, status, pricing) needed for feed generation
- **Failure mode**: Returns `None`; calling job handles gracefully and logs error
- **Circuit breaker**: No — 3 retries implemented for GAPI; Deal Catalog has no retry logic beyond the single request

### Marketing Deal Service (MDS) Detail

- **Protocol**: REST over mTLS via `hburllib`
- **Base URL / SDK**: NA URL — `/dispatcher/feed/{uuid}`, `/dispatcher/batch/{uuid}`, `/batches/feed/{uuid}`, `/upload-batches/feed-batch/{uuid}`, `uploads/rich_relevance`
- **Auth**: mTLS via `tls--transam-sem-gcp-pipelines` service identity
- **Purpose**: Coordinates feed dispatch, batch tracking, and conversion report uploads for Google Things To Do and reports-uploader workflows
- **Failure mode**: Raises `ResponseError`; job fails and Airflow handles retry
- **Circuit breaker**: No

### Databreakers Service Detail

- **Protocol**: REST / HTTPS with HMAC-SHA1 signing
- **Base URL / SDK**: Configured via `databreakers['NA_URL']` / `databreakers['INTL_URL']` and `databreakers['NA_INDIVIDUALIZER_URL']` / `databreakers['INTL_INDIVIDUALIZER_URL']`
- **Auth**: Per-country HMAC-SHA1 signature using account credentials from GCP Secret Manager (`key_name` per country)
- **Purpose**: Retrieves deal item details and search recommendation data for SEM feed enrichment
- **Failure mode**: Returns `None`; calling job handles gracefully
- **Circuit breaker**: No

## Consumed By

> Upstream consumers are tracked in the central architecture model.

This service does not expose an inbound API. External ad platforms (Google Ads, Facebook Ads, CSS Affiliates, etc.) receive feed data pushed by this service's Spark jobs.

## Dependency Health

- All internal service calls use `hburllib` which enforces mTLS. Non-200 responses raise `ResponseError` or return `None`.
- GAPI calls implement a 3-attempt retry with 1-second delay between attempts.
- Dataproc job failures are surfaced by Airflow task status; PagerDuty alerts are triggered via the `on_failure_callback: trigger_event` hook on all DAGs.
- GCS operations use `gsutil` CLI; partition existence is checked before Spark reads to avoid failures on missing data.
