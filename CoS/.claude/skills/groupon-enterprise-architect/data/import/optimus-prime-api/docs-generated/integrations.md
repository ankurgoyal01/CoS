---
service: "optimus-prime-api"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 7
internal_count: 3
---

# Integrations

## Overview

Optimus Prime API has the broadest integration footprint of any Continuum ETL service: seven external dependencies and three owned data stores. All interactions are synchronous. Resilience4j provides circuit breaker and retry protection for critical outbound calls. The NiFi integration is the most critical dependency — without it, job execution cannot proceed.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| NiFi (`continuumOptimusPrimeNifi`) | REST / HTTP | Executes ETL process groups; manages NiFi flow lifecycle | yes | `continuumOptimusPrimeNifi` (stub) |
| Active Directory / LDAP | LDAP | User authentication, group resolution, disabled user detection | yes | `activeDirectory` (stub) |
| SMTP Relay | SMTP | Email notification delivery for job alerts and reports | no | `smtpRelay` (stub) |
| Google Sheets API | REST / HTTPS | Reads analytics metadata from spreadsheets | no | `googleSheetsApi` (stub) |
| SFTP (`cloudPlatform`) | SFTP | File transfer to/from configured remote SFTP endpoints | no | `cloudPlatform` (stub) |
| Hive Warehouse | JDBC / Hive | Coordinates Hive data movement steps | no | `hiveWarehouse` (stub) |
| BigQuery Warehouse | BigQuery API | Coordinates BigQuery data movement steps | no | `bigQueryWarehouse` (stub) |

### NiFi Detail

- **Protocol**: REST / HTTP
- **Base URL / SDK**: NiFi Client 1.16.3; base URL configured via JTier application config
- **Auth**: No evidence found in codebase; NiFi API auth expected (token or certificate)
- **Purpose**: The `nifiIntegration` component creates, updates, and monitors NiFi process groups that physically execute ETL data flows on behalf of Optimus Prime jobs
- **Failure mode**: Job runs cannot start or be monitored; Resilience4j circuit breaker opens; run status is set to failed; operator notification sent via SMTP
- **Circuit breaker**: Yes — Resilience4j 1.7.1

### Active Directory / LDAP Detail

- **Protocol**: LDAP
- **Base URL / SDK**: SSHJ 0.31.0 or standard JNDI LDAP; connection details in application config
- **Auth**: LDAP bind credentials injected at deploy time
- **Purpose**: `authDirectoryAdapter` resolves user identities for all API calls and the `DisabledUsersJob` queries LDAP to detect disabled accounts for automated job cleanup
- **Failure mode**: API authentication fails for affected users; `DisabledUsersJob` skips LDAP query cycle; no jobs are disabled during outage
- **Circuit breaker**: Yes — Resilience4j 1.7.1

### SMTP Relay Detail

- **Protocol**: SMTP
- **Base URL / SDK**: Simple Java Mail 6.0.5
- **Auth**: SMTP credentials injected at deploy time
- **Purpose**: `notificationAdapter` sends job run result emails and operational alerts (e.g., NiFi health degradation)
- **Failure mode**: Email notifications are dropped; job execution is not affected
- **Circuit breaker**: No evidence found in codebase

### Google Sheets API Detail

- **Protocol**: REST / HTTPS
- **Base URL / SDK**: Google Sheets API (via `metadataAdapter`)
- **Auth**: Google service account credentials injected at deploy time
- **Purpose**: Reads spreadsheet metadata (e.g., schema definitions or mapping tables) for certain ETL pipeline configurations
- **Failure mode**: Metadata reads fail; affected jobs that depend on sheet metadata cannot proceed
- **Circuit breaker**: No evidence found in codebase

### SFTP Detail

- **Protocol**: SFTP
- **Base URL / SDK**: SSHJ 0.31.0 via `storageAdapter`
- **Auth**: SSH key or password per connection, stored encrypted in `continuumOptimusPrimeApiDb`
- **Purpose**: Transfers files to/from remote SFTP servers as configured in connection definitions
- **Failure mode**: File transfer step fails; job run recorded as failed; alert sent
- **Circuit breaker**: No evidence found in codebase

### Hive Warehouse Detail

- **Protocol**: JDBC / Hive
- **Base URL / SDK**: Connection details stored in `connections` table
- **Auth**: Credentials stored encrypted in `continuumOptimusPrimeApiDb`
- **Purpose**: Coordinates Hive data movement steps within ETL pipelines
- **Failure mode**: Hive-dependent job steps fail; run recorded as failed
- **Circuit breaker**: No evidence found in codebase

### BigQuery Warehouse Detail

- **Protocol**: BigQuery API
- **Base URL / SDK**: Google Cloud SDK (BigQuery client); referenced in dynamic view `dynamic-job-run-orchestration`
- **Auth**: Google service account credentials injected at deploy time
- **Purpose**: `nifiIntegration` component coordinates BigQuery-related ETL flow steps
- **Failure mode**: BigQuery-dependent job steps fail; run recorded as failed
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Optimus Prime Postgres DB | JDBC/SQL | All application state persistence | `continuumOptimusPrimeApiDb` |
| Optimus Prime GCS Bucket | GCS SDK | File ingress/egress for ETL workflows | `continuumOptimusPrimeGcsBucket` |
| Optimus Prime S3 Storage | AWS SDK | File storage for ETL job steps | `continuumOptimusPrimeS3Storage` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Data engineers and analysts | REST / HTTP | Create, manage, and monitor ETL jobs via API |
| Internal tooling / Optimus Prime UI | REST / HTTP | Job management and run status visualization |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

The `NiFiHealthcheckMetricsJob` is a scheduled Quartz job that periodically polls NiFi health and reports metrics. Resilience4j wraps the NiFi and LDAP calls. SMTP and storage failures are non-critical and are logged but do not prevent job execution. No dedicated health check endpoint for external dependencies (beyond NiFi) is defined in the architecture model.
