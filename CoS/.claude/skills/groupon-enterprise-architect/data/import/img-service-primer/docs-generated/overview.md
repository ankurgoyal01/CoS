---
service: "img-service-primer"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Image / Media"
platform: "Continuum"
team: "Global Image Service"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard / JTier"
  framework_version: "5.14.0"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Global Image Service Primer Overview

## Purpose

Image Service Primer (service ID: `gims-primer`) is a scheduled utility service that proactively warms the image caches of Groupon's Global Image Service (GIMS) and the Akamai CDN edge network before deals go live. It queries deal-catalog for deals scheduled to launch within the next 24-hour distribution window, extracts their images, generates all known transformed variants, and fires pre-fetch requests against GIMS and Akamai. This prevents the cold-start latency spikes (10–20 seconds) that occur when large volumes of new deal traffic hit GIMS simultaneously, particularly during high-deal-volume periods like holiday season.

## Scope

### In scope

- Querying deal-catalog for deals entering their distribution window within the next 24 hours
- Deduplicating deal images and expanding each into a full set of transformed image URL variants
- Pre-fetching original and transformed images from GIMS to warm its internal caches
- Requesting the same image URLs from Akamai to warm the CDN edge cache
- Accepting manual trigger API calls to prime images for specific deals, countries, or individual images on demand
- Deleting images from S3, GIMS nginx caches, and Akamai storage via the image delete endpoint
- Consuming video transformation update events from the message bus and transforming source media via ffmpeg
- Uploading transformed video payloads to S3

### Out of scope

- Serving image requests to end users (handled by `gims`)
- Storing or owning source images (owned by GIMS / S3)
- Applying image transformations in real time (handled by GIMS)
- Managing deal state or distribution window scheduling (owned by deal-catalog)

## Domain Context

- **Business domain**: Image / Media
- **Platform**: Continuum
- **Upstream consumers**: No programmatic upstream callers; the scheduled Quartz job is self-triggering. Manual trigger endpoints are called by operators.
- **Downstream dependencies**: `continuumDealCatalogService` (deal metadata via HTTP/JSON), `gims` (image pre-fetch via HTTP), `akamai` (CDN cache warming and purge via HTTPS), `continuumImageServicePrimerDb` (MySQL — video metadata and transformation state), AWS S3 (video upload), GCS (source media download)

## Stakeholders

| Role | Description |
|------|-------------|
| Owner | Global Image Service team — imageservice@groupon.com |
| On-call | PagerDuty service PWFOW4O, Slack #CFJ5NRS68 (image-service-ist) |
| Criticality | Tier 5 (Non-Core, no SLAs on the API surface itself) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` — `project.build.targetJdk=11` |
| Framework | Dropwizard / JTier | 5.14.0 (jtier-service-pom) | `pom.xml` — parent `jtier-service-pom:5.14.0` |
| Runtime | JVM | 11 | `.ci/Dockerfile` — `dev-java11-maven` base image |
| Build tool | Maven | — | `pom.xml`, `mvnvm.properties` |
| Container runtime | Docker | — | `src/main/docker/Dockerfile`, `.ci/Dockerfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-quartz-bundle` | via jtier BOM | scheduling | Quartz-backed daily scheduled job for deal priming |
| `jtier-retrofit` | via jtier BOM | http-framework | Retrofit-based HTTP clients for GIMS, deal-catalog, and Akamai |
| `jtier-rxjava3-extras` | via jtier BOM | state-management | RxJava3 reactive data flow, concurrency limits, backpressure |
| `hk2-di-core` | via jtier-ext 5.13.3.1 | http-framework | HK2 dependency injection container |
| `jsonholder-bundle` | 1.6.5 | serialization | JSON request/response handling |
| `edgegrid-signer-google-http-client` | 2.1.1 | auth | Akamai EdgeGrid request signing for purge/fetch calls |
| `jsch` | 0.1.55 | http-framework | SSH execution support (SshExecutionService) |
| `google-cloud-storage` | via GCP BOM 26.44.0 | db-client | GCS client for downloading source media objects |
| `software.amazon.awssdk:s3` | 2.26.25 | db-client | AWS S3 client for uploading transformed video payloads |
| `javacv` / `opencv` / `ffmpeg` | 1.5.11 / 4.10.0 / 7.1 | media | Video frame extraction and transformation via ffmpeg and OpenCV |
| `jtier-messagebus-client` | via jtier BOM | message-client | Groupon internal message bus client for consuming video transformation events |
| `jtier-daas-mysql` / `jtier-jdbi3` | via jtier BOM | orm | JDBI3 MySQL data access for video transformation state |
| `lombok` | 1.18.34 | validation | Compile-time boilerplate reduction |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
