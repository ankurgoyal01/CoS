---
service: "expy-service"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 5
internal_count: 1
---

# Integrations

## Overview

Expy Service has five external dependencies (all in the Optimizely ecosystem or AWS infrastructure) and one internal Groupon dependency (Birdcage). All external calls are made via the `expyService_externalClients` component using Retrofit/OkHttp HTTP clients or the AWS S3 SDK. There is no message-bus-based integration — all external communication is synchronous REST or SDK calls, with the exception of scheduled Quartz jobs that batch-refresh data.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Optimizely API | REST/HTTPS | Manage projects and experiments in Optimizely | yes | `optimizelyApiSystem_6c1a` |
| Optimizely CDN | HTTPS | Fetch current Optimizely datafiles | yes | `optimizelyCdnSystem_9d42` |
| Optimizely Data Listener | REST/HTTPS | Fetch event datafiles for experiment tracking | yes | `optimizelyDataListenerSystem_5b7f` |
| Optimizely S3 Bucket | AWS S3 SDK | Read Optimizely-managed datafiles for backup | yes | `optimizelyS3Bucket_84a1` |
| Groupon S3 Bucket | AWS S3 SDK | Write daily datafile backup copies | yes | `grouponS3Bucket_7c3d` |
| Canary API | REST/HTTPS | Traffic management integration | no | `canaryApiSystem_2e31` |

### Optimizely API (`optimizelyApiSystem_6c1a`) Detail

- **Protocol**: REST/HTTPS
- **Base URL / SDK**: Optimizely REST API — configured via environment/config (specific URL not in architecture model)
- **Auth**: API key or OAuth2 — confirm with service owner
- **Purpose**: Project creation, experiment management, and audience management operations that must be reflected in the Optimizely platform
- **Failure mode**: Feature and experiment CRUD operations will fail; bucketing from cached datafiles can continue in degraded mode
- **Circuit breaker**: Not defined in architecture model

### Optimizely CDN (`optimizelyCdnSystem_9d42`) Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: Optimizely CDN — `https://cdn.optimizely.com` (standard Optimizely CDN)
- **Auth**: SDK key in URL path
- **Purpose**: Primary source for fetching up-to-date Optimizely datafiles on the scheduled refresh cycle
- **Failure mode**: Scheduled datafile refresh fails; service continues serving the last cached datafile from MySQL
- **Circuit breaker**: Not defined in architecture model

### Optimizely Data Listener (`optimizelyDataListenerSystem_5b7f`) Detail

- **Protocol**: REST/HTTPS
- **Base URL / SDK**: Optimizely Data Listener endpoint — confirm with service owner
- **Auth**: Configured credential — confirm with service owner
- **Purpose**: Fetches event-specific datafiles for experiment tracking and audience evaluation
- **Failure mode**: Event datafile refresh fails; last cached version remains active
- **Circuit breaker**: Not defined in architecture model

### Optimizely S3 Bucket (`optimizelyS3Bucket_84a1`) Detail

- **Protocol**: AWS S3 SDK (aws-sdk-s3 BOM 2.16.39)
- **Base URL / SDK**: AWS S3 — bucket name configured via environment variable
- **Auth**: AWS IAM credentials (AWS SDK credential chain)
- **Purpose**: Source bucket for reading Optimizely-managed datafiles as part of the daily S3 backup flow
- **Failure mode**: Daily S3 backup copy job fails; operational impact is limited to backup availability
- **Circuit breaker**: Not defined in architecture model

### Groupon S3 Bucket (`grouponS3Bucket_7c3d`) Detail

- **Protocol**: AWS S3 SDK (aws-sdk-s3 BOM 2.16.39)
- **Base URL / SDK**: AWS S3 — Groupon-owned bucket, name configured via environment variable
- **Auth**: AWS IAM credentials (AWS SDK credential chain)
- **Purpose**: Destination bucket for daily datafile backup copies — ensures Groupon retains its own copy independent of Optimizely
- **Failure mode**: Backup copy not stored; primary service operation unaffected
- **Circuit breaker**: Not defined in architecture model

### Canary API (`canaryApiSystem_2e31`) Detail

- **Protocol**: REST/HTTPS
- **Base URL / SDK**: Internal Canary API — confirm URL with service owner
- **Auth**: Internal service-to-service auth — confirm with service owner
- **Purpose**: Traffic management integration — used in conjunction with experiment bucketing to coordinate canary releases
- **Failure mode**: Canary traffic management unavailable; bucketing decisions may fall back to standard allocation
- **Circuit breaker**: Not defined in architecture model

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Birdcage | REST/HTTPS | Internal feature flag system — Expy proxies Birdcage data via `/birdcage/*` endpoints | Internal Groupon service |

## Consumed By

> Upstream consumers are tracked in the central architecture model. Expy Service is consumed by any Groupon internal service requiring experiment bucketing decisions or feature-flag evaluation.

## Dependency Health

- The `expyService_cacheLayer` (in-memory) buffers calls to MySQL and external Optimizely endpoints, reducing the blast radius of transient failures.
- Quartz job failures (datafile refresh, S3 copy) are recorded as parse errors in MySQL; the last successfully loaded datafile continues to be served.
- No explicit circuit breaker configuration is defined in the current architecture model. Confirm retry and timeout policies with the Optimize team.
