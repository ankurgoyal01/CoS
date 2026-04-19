---
service: "larc"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 2
---

# Integrations

## Overview

LARC has one external integration (QL2 pricing data provider) and two primary internal Groupon service dependencies (Travel Inventory Service and Deal Catalog / Content Service). All internal communication is synchronous HTTP/JSON using Retrofit clients. The external integration uses FTP and SFTP to retrieve partner CSV files. There is a stub reference to a Rocketman notification service for unmapped rate description emails, but this is not wired into the central architecture model.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| QL2 (Third-Party Pricing Provider) | SFTP/FTP + CSV | Downloads hotel market pricing feed files for rate ingestion | yes | `thirdPartyInventory` |

### QL2 (Third-Party Pricing Provider) Detail

- **Protocol**: SFTP (JSch) and FTP (Apache Commons Net `commons-net` 3.4)
- **Base URL / SDK**: Configured via `ql2FTPConfig` — `FTPGlobalConfiguration` and `FTPCredential` list in `LarcConfiguration`
- **Auth**: Per-site FTP credentials (username/password), stored as secrets in Kubernetes secrets; SFTP uses key-based auth via JSch
- **Purpose**: QL2 is a third-party hotel rate shopping provider. LARC monitors the QL2 FTP server for new pricing CSV files (identified by MD5 checksum), downloads them to a local temp directory (default `/tmp/`), and ingests the CSV rows into the `NightlyLar` table for LAR computation
- **Failure mode**: If QL2 FTP is unavailable, the FTP monitor worker retries on its configured interval (`ftpMonitorIntervalInSec`). Files not yet downloaded are queued as ingestion jobs with appropriate status. Rate updates to Inventory Service are delayed until the next successful download cycle
- **Circuit breaker**: No evidence of explicit circuit breaker; retry is handled via scheduler polling interval

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Travel Inventory Service | HTTP/JSON (Retrofit/OkHttp) | Reads hotel/room-type/rate-plan metadata and writes computed QL2/GRPN rate updates | `continuumTravelInventoryService` |
| Deal Catalog / Content Service | HTTP/JSON (Retrofit/OkHttp) | Fetches product set and rate-plan metadata needed to scope LAR computation windows | `continuumDealCatalogService` |

### Travel Inventory Service Detail

- **Protocol**: HTTP/JSON via Retrofit client (`InventoryServiceClient`)
- **Base URL / SDK**: Configured via `inventoryServiceConfig.baseUrl` in `LarcConfiguration`
- **Auth**: `clientId` and `defaultHeaders` map (contains auth token headers); `olympiaAuthToken` in `LarcConfiguration` used for Olympia-based auth
- **Purpose**: LARC reads rate-plan and product-set status from Inventory Service to determine which rate plans are active and viable for LAR computation. After computing LARs, LARC calls Inventory Service to push updated `ql2Prices` per hotel/room-type/rate-plan
- **Failure mode**: `LarcException` is thrown on HTTP errors. Socket timeout and connect exception are specifically caught and logged as `UPDATE_LAR_TIMED_OUT` events. The current rate plan's update is skipped, but others in the batch may still succeed

### Deal Catalog / Content Service Detail

- **Protocol**: HTTP/JSON via Retrofit client (`ContentServiceClient`)
- **Base URL / SDK**: Configured via `contentServiceConfig.baseUrl` in `LarcConfiguration`
- **Auth**: `clientId` and `defaultHeaders` map
- **Purpose**: Provides product set metadata (`ContentServiceProductSetResponse`) and rate plan definitions (`ContentServiceRatePlansForProductSetResponse`) used during ingestion to associate QL2 data with Groupon deal structures
- **Failure mode**: Ingestion job fails if the content service is unavailable; the job is retried on the next scheduler cycle

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| eTorch (deal management extranet) | HTTP/REST | Manages hotel-to-QL2 mappings, rate descriptions, and triggers on-demand LAR sends |
| Getaways Extranet App | HTTP/REST | Manages approved discount percentages and hotel configurations |

> Upstream consumers are tracked in the central architecture model. Consumer identity confirmed via `.service.yml` description of the `larc::app` subservice.

## Dependency Health

- **Inventory Service**: Retry is implicit through the live pricing worker scheduler re-running on its configured interval. Socket timeouts are logged as `UPDATE_LAR_TIMED_OUT` events visible in Wavefront dashboards
- **Content Service**: No explicit health check or circuit breaker; failures bubble up as `LarcException` and are logged
- **QL2 FTP**: The `FTPMonitorWorkerManager` polls on a configurable interval; connectivity failures result in no new files being discovered until the next poll cycle
- **MySQL (LARC Database)**: JTier DaaS MySQL provides connection pooling; connection failures result in `SQLException` logged as `DB_ERROR` events
