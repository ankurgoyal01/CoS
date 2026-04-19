---
service: "janus-web-cloud"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 7
internal_count: 0
---

# Integrations

## Overview

Janus Web Cloud has seven external system integrations and no inter-service REST dependencies within the Continuum platform. All external integrations are accessed through the `jwc_integrationAdapters` component. Four are read-only data sources (BigQuery, Bigtable/HBase, Elasticsearch, and the logging/metrics/tracing stacks); one is a write-only notification sink (SMTP relay); and one resource-manager integration (GDOOP) is referenced but currently stubbed out in the central architecture model.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Janus Metadata MySQL | JDBC / MySQL | Primary datastore for all Janus metadata, schema registry, replay, alert, and Quartz state | yes | `continuumJanusMetadataMySql` |
| Bigtable / HBase | HBase API | Read GDPR-relevant event records for report generation | yes | `bigtableRealtimeStore` |
| Elasticsearch | Elasticsearch REST SDK | Query metrics and alert evaluation indices | yes | `elasticSearch` |
| BigQuery | BigQuery SDK | Query analytical datasets for metrics and reporting | no | `bigQuery` |
| SMTP Relay | SMTP | Send alert notification emails via simple-java-mail | yes | `smtpRelay` |
| Logging Stack | Internal | Emit service logs | no | `loggingStack` |
| Metrics Stack | Internal | Emit and consume operational metrics | no | `metricsStack` |
| Tracing Stack | Internal | Emit distributed traces | no | `tracingStack` |

### Janus Metadata MySQL Detail

- **Protocol**: JDBC
- **Base URL / SDK**: `mysql-connector 8.0.27`; JDBI DAO layer
- **Auth**: Database credentials (managed externally)
- **Purpose**: All persistent state — metadata mappings, schema registry versions, replay job state, alert definitions, and Quartz scheduler tables
- **Failure mode**: Service cannot serve metadata reads or writes; replay and alert scheduling halts
- **Circuit breaker**: No evidence found

### Bigtable / HBase Detail

- **Protocol**: HBase API (native)
- **Base URL / SDK**: `hbase-client 2.2.3` + `bigtable-hbase 1.26.3`
- **Auth**: GCP service account credentials
- **Purpose**: Read GDPR event data for the GDPR report generation flow
- **Failure mode**: GDPR report generation requests fail; all other API groups unaffected
- **Circuit breaker**: No evidence found

### Elasticsearch Detail

- **Protocol**: Elasticsearch REST / Java SDK
- **Base URL / SDK**: `elasticsearch 5.6.16`
- **Auth**: Cluster authentication (managed externally)
- **Purpose**: Evaluate alert threshold expressions and serve `/metrics/*` API responses
- **Failure mode**: Alert threshold evaluation skipped or errors; `/metrics/*` endpoints return errors
- **Circuit breaker**: No evidence found

### BigQuery Detail

- **Protocol**: BigQuery SDK
- **Base URL / SDK**: GCP BigQuery Java SDK
- **Auth**: GCP service account credentials
- **Purpose**: Query analytical datasets for reporting and metrics flows
- **Failure mode**: Analytical reporting calls fail; operational metadata unaffected
- **Circuit breaker**: No evidence found

### SMTP Relay Detail

- **Protocol**: SMTP
- **Base URL / SDK**: `simple-java-mail 4.1.1`; email templates rendered via `thymeleaf 3.0.14`
- **Auth**: SMTP credentials (managed externally)
- **Purpose**: Deliver alert notification emails to configured recipients after threshold evaluation
- **Failure mode**: Alert emails not sent; alert outcome still written to MySQL
- **Circuit breaker**: No evidence found

### Logging / Metrics / Tracing Stacks Detail

- **Protocol**: Internal platform instrumentation
- **Purpose**: Operational observability — logs, metrics emission and consumption, and distributed tracing
- **Failure mode**: Observability data lost; service continues to function
- **Circuit breaker**: Not applicable

### GDOOP Resource Manager (Stubbed)

> The relationship `continuumJanusWebCloudService -> unknown_gdoopresourcemanager_4d62d4f7` (coordinates replay job execution and cluster status checks) is referenced in the architecture model but is currently stubbed out and not resolved in the central model. Integration details are not available.

## Internal Dependencies

> Not applicable. Janus Web Cloud does not have REST or gRPC dependencies on other named Continuum platform services.

## Consumed By

> Upstream consumers are tracked in the central architecture model. The service is consumed by operator tooling and internal Continuum services that manage Janus metadata via REST.

## Dependency Health

No explicit circuit breaker, retry, or health-check patterns are documented in the architecture model. Dependency health checks should follow JTier/Dropwizard platform conventions. See [Runbook](runbook.md) for dependency health guidance.
