---
service: "gpn-data-api"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 0
---

# Integrations

## Overview

GPN Data API has two downstream dependencies: Google BigQuery (external, cloud analytics platform) and MySQL (owned relational database). There are no internal Groupon service-to-service calls made by this service. Upstream consumers reach it over HTTP; the primary known consumer is `sem-ui` (Attribution Lens).

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google BigQuery (`prj-grp-dataview-prod-1ff9`) | BigQuery API (Google Cloud SDK) | Source of all marketing attribution and unit economics data | yes | `bigQuery_unk_a1b2` |
| MySQL | JDBC | Tracks daily query counts and stores the max queries per day configuration | yes | `continuumGpnDataApiMySql` |

### Google BigQuery Detail

- **Protocol**: Google Cloud BigQuery Java SDK (`google-cloud-bigquery` 2.40.2)
- **Base URL / SDK**: `com.google.cloud:google-cloud-bigquery:2.40.2`; project `prj-grp-dataview-prod-1ff9`
- **Auth**: Google Cloud service account credentials; key material supplied via `bigQuery.key` configuration property
- **Purpose**: Executes parameterized SQL queries against `marketing.order_attribution_part`, `finance_unit_economics.unit_economics`, and `marketing.parent_orders` to retrieve order attribution records
- **Failure mode**: If BigQuery is unavailable or the query is interrupted, the service throws `AttributionServiceException` and returns HTTP 500 to the caller. For paginated queries, a missing job ID results in an explicit error.
- **Circuit breaker**: No evidence of a circuit breaker implementation; failures propagate directly to the HTTP response.

### MySQL Detail

- **Protocol**: JDBC (via JTier DaaS MySQL and JDBI 3)
- **Base URL / SDK**: `com.groupon.jtier:jtier-daas-mysql`; JDBI 3 SQL Object interface `AttributionQueryCountDao`
- **Auth**: Username/password configured in the service YAML (`mysql` block); credentials injected at runtime via environment-specific config
- **Purpose**: Reads the daily query cap from `attribution_properties` and maintains the rolling daily query count in `attribution_query_count`
- **Failure mode**: A MySQL outage would prevent any attribution query from executing, since the limit check is mandatory on every request
- **Circuit breaker**: No evidence found.

## Internal Dependencies

> No evidence found in codebase. GPN Data API makes no synchronous calls to other internal Groupon microservices.

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| `sem-ui` (Attribution Lens) | HTTPS/JSON | Displays order attribution details to affiliate managers via the Attribution Lens UI |

> Upstream consumers beyond `sem-ui` are tracked in the central architecture model. The `stubs.dsl` records an unresolved external client reference (`attributionApiClients_unk_2f3c`).

## Dependency Health

- **BigQuery**: No dedicated health check beyond the service-level `GpnDataApiHealthCheck` (arithmetic stub). BigQuery connectivity is validated only when a query is first executed.
- **MySQL**: JTier DaaS MySQL provides connection pool management. Loss of MySQL prevents all requests from succeeding since limit checks are mandatory.
- No explicit retry logic or timeouts are configured in the codebase for either dependency; the Google Cloud SDK and JDBI apply their own default behaviours.
