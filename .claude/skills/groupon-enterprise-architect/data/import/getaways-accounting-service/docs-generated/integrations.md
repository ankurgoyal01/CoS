---
service: "getaways-accounting-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 2
---

# Integrations

## Overview

The Getaways Accounting Service has three downstream dependencies: it reads reservation data from the TIS PostgreSQL database (shared internal data store), fetches hotel metadata from the Content Service API over HTTPS, and delivers generated CSV files to an SFTP accounting server. All integrations are synchronous. The service is consumed by EDW and Finance Engineering teams via its two REST API endpoints.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Accounting SFTP Server | SFTP | Receives daily accounting CSV and MD5 checksum files | yes | `accountingSftpServer_14db43` |

### Accounting SFTP Server Detail

- **Protocol**: SFTP (via JSch 0.1.54)
- **Production host**: `transfer.groupondev.com`
- **Production remote path**: `/groupon-transfer-prod-getaways-report/groupon/getaways/gas_daily_reports`
- **Staging host**: `s-bf7136d54cfa4597b.server.transfer.us-west-2.amazonaws.com`
- **Staging remote path**: `/groupon-transfer-sandbox-getaways-report-staging/groupon/getaways/gas_daily_reports`
- **Auth**: SSH key pair — `SFTP_PRIVATE_KEY`, `SFTP_PUBLIC_KEY`, `SFTP_PASS_PHRASE` (injected via secrets), username via `SFTP_CLOUD_USERNAME`
- **Purpose**: Deliver daily accounting CSV reports (summary and detail) and their MD5 checksums to the finance SFTP server for downstream EDW consumption.
- **Failure mode**: CSV generation task fails with an exception; alert fires via PagerDuty. Files remain locally staged for manual re-upload.
- **Circuit breaker**: No evidence found of a circuit breaker on SFTP uploads.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Content Service | HTTPS (Retrofit) | Fetches hotel name and address metadata for summary CSV lines | `contentServiceApi_abaf55` |
| Travel Itinerary Service (TIS) PostgreSQL | PostgreSQL (JDBI) | Primary source of all reservation and transaction data | `tisPostgres_bf2737` |

### Content Service Detail

- **Protocol**: HTTPS via Retrofit HTTP client (`jtier-retrofit`)
- **Production base URL**: `http://getaways-content.production.service`
- **Staging base URL**: `http://getaways-content.staging.service`
- **Development URL**: `http://getaways-travel-content-uat-vip.snc1`
- **Auth**: Query parameter `client_id`, header `Olympia-Admin`, header `Olympia-Auth-Token` (values injected via `CONTENTSERVICE_AUTH_*` env vars)
- **Purpose**: Provides hotel name, address, location metadata to enrich summary CSV report lines.
- **Failure mode**: `HotelNotFound` exception thrown if hotel metadata cannot be retrieved; individual CSV summary lines may be skipped or the task may fail.
- **Circuit breaker**: No evidence found of a circuit breaker; standard Retrofit connection/read timeout applies.

### Travel Itinerary Service (TIS) PostgreSQL Detail

- **Protocol**: PostgreSQL via JDBI (`jtier-jdbi`, `jtier-daas-postgres`)
- **Purpose**: All reservation, booking, commit, and cancellation records are stored in this database. GAS is a read-only consumer.
- **Failure mode**: If the database is unavailable, both API endpoints and CSV generation fail immediately. Health checks monitor pool connectivity.
- **Circuit breaker**: Managed via jtier DaaS connection pooling and health checks.

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Enterprise Data Warehouse (EDW) | REST (HTTP) | Retrieves reservation finance data via `GET /v1/finance` for financial reconciliation |
| Finance Engineering (FED) | REST (HTTP) | Searches reservations via `GET /v1/reservations/search` for audit and reporting |
| Accounting SFTP Server (EDW downstream) | SFTP (push) | Receives daily summary and detail CSVs for financial reporting pipelines |

> Upstream consumers are tracked in the central architecture model. Internal Groupon teams (EDW, FED) are the primary API consumers per `.service.yml`.

## Dependency Health

- The TIS PostgreSQL database connection pool is health-checked by the Dropwizard health check registry at startup.
- The SFTP server connection is verified by the CSV Validator component, which re-downloads uploaded files and compares checksums after each upload.
- The Content Service is called synchronously during CSV summary generation; no dedicated health check endpoint is registered.
- APM tracing is enabled (Elastic APM) in both staging and production to observe cross-service call latency and errors.
