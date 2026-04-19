---
service: "merchant-preview"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 5
internal_count: 1
---

# Integrations

## Overview

Merchant Preview integrates with five external systems and one internal Continuum service. The most critical integrations are Salesforce (for deal approval state and task tracking) and the Deal Catalog Service (for deal creative content). Email notifications are delivered via an SMTP relay. Observability is covered by dedicated logging, metrics, and tracing stacks.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | HTTPS (databasedotcom) | Read/write Opportunity and Task records for deal approval workflow | yes | `salesForce` |
| SMTP Relay | SMTP | Send transactional preview notification emails to merchants and account managers | yes | `smtpRelay` |
| Akamai CDN | HTTP (edge routing) | Fronts public merchant preview URLs and routes traffic to the service | yes | `akamai` |
| Logging Stack | — | Receive structured application and cron task logs | no | `loggingStack` |
| Metrics Stack | — | Receive application and request metrics | no | `metricsStack` |
| Tracing Stack | — | Receive distributed traces and timing spans | no | `tracingStack` |

### Salesforce Detail

- **Protocol**: HTTPS via databasedotcom Ruby gem
- **Base URL / SDK**: databasedotcom gem (Salesforce REST API)
- **Auth**: > No evidence found in codebase for specific auth credential type; typically OAuth or username/password flow via databasedotcom
- **Purpose**: The `mpSalesforceApiClient` component reads Opportunity and Task data to hydrate preview context and writes back approval/rejection state and comments. The `mpSfCaseCronJob` periodically synchronizes unresolved comments and task records.
- **Failure mode**: Preview pages can still render (deal content from Deal Catalog); comment sync and approval state updates will be delayed or unavailable.
- **Circuit breaker**: > No evidence found in codebase.

### SMTP Relay Detail

- **Protocol**: SMTP
- **Base URL / SDK**: ActionMailer delivery (configured SMTP relay endpoint)
- **Auth**: > No evidence found in codebase for specific SMTP auth configuration.
- **Purpose**: Delivers transactional emails when merchants receive new preview links, when comments are posted, and when approval decisions are made.
- **Failure mode**: Email notifications silently fail or queue; core preview and comment functionality remains available.
- **Circuit breaker**: > No evidence found in codebase.

### Akamai CDN Detail

- **Protocol**: HTTP (edge routing / reverse proxy)
- **Base URL / SDK**: Akamai edge configuration (external)
- **Auth**: Token or signed URL for merchant access
- **Purpose**: Routes public merchant preview traffic to the service backend. Internal account manager access uses a separate gateway path.
- **Failure mode**: Public merchant access is unavailable; internal account manager access may remain functional via direct internal gateway.
- **Circuit breaker**: > Not applicable at application level; handled at edge.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Catalog Service | HTTP | Retrieves deal IDs and creative content for preview rendering | `continuumDealCatalogService` |

### Deal Catalog Service Detail

- **Protocol**: HTTP
- **Purpose**: The `mpDealAggregationClient` component calls the Deal Catalog Service to retrieve deal creative details and aggregates them with Deal Estate data into rendered preview models.
- **Failure mode**: Preview pages cannot render deal creative content; preview functionality is effectively unavailable.
- **Circuit breaker**: > No evidence found in codebase.

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Known access paths from the architecture model:
- Merchants access the service via Akamai CDN public preview URLs.
- Sales reps / account managers access the service via an internal gateway (stub: `unknown_gwall_59e47646`).

## Dependency Health

> Operational procedures to be defined by service owner. No health check or circuit breaker patterns are described in the architecture model.
