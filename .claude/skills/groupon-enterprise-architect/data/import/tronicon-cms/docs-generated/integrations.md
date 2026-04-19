---
service: "tronicon-cms"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 0
---

# Integrations

## Overview

Tronicon CMS has a minimal integration footprint. Its only runtime data dependency is its own MySQL database managed by Groupon's DaaS team. The service does not call other internal Groupon microservices at runtime. Observability integrations (Elastic APM and ELK log shipping via Filebeat) are injected transparently by the JTier platform and Kubernetes sidecar infrastructure.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| MySQL DaaS | JDBI/MySQL | Primary content storage and retrieval | yes | `continuumTroniconCmsDatabase` |
| Elastic APM | HTTP (Java agent) | Application performance monitoring and distributed tracing | no | — |
| ELK Stack (Filebeat/Kibana) | Log shipping | Centralized log aggregation for operational visibility | no | — |

### MySQL DaaS Detail

- **Protocol**: JDBI3 over MySQL wire protocol
- **Base URL / SDK**: Provided via `jtier-daas-mysql` and `jtier-jdbi3` libraries
- **Auth**: Database credentials managed in the `tronicon-cms-secrets` repository and injected at runtime via Kubernetes secrets
- **Purpose**: Stores and retrieves all CMS content, audit logs, and usability statistics
- **Failure mode**: Service returns HTTP `500` errors on database connectivity failure; no local fallback or in-memory cache is present
- **Circuit breaker**: No evidence of circuit breaker configuration in codebase

### Elastic APM Detail

- **Protocol**: HTTP (Elastic APM Java agent sidecar)
- **Base URL / SDK**: Per-environment cluster-local endpoint, e.g., `https://elastic-apm-http.logging-platform-elastic-stack-production.svc.cluster.local:8200`
- **Auth**: Internal cluster endpoint; no external credentials required
- **Purpose**: Collects distributed traces and transaction performance metrics; enabled in staging and production environments
- **Failure mode**: APM agent is non-blocking; the service continues operating if the APM endpoint is unavailable
- **Circuit breaker**: Not applicable

### ELK Stack (Filebeat) Detail

- **Protocol**: Filebeat log shipping from pod filesystem volume
- **Purpose**: Centralizes JTier application logs to Kibana for operational troubleshooting and alerting
- **Filebeat volume type**: `medium` (common/staging), `high` (production) — configured in `.meta/deployment/cloud/components/app/`
- **Failure mode**: Log shipping is asynchronous; the service continues if ELK is unavailable
- **Circuit breaker**: Not applicable

## Internal Dependencies

> No evidence found in codebase. Tronicon CMS does not call other internal Groupon microservices at runtime.

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known consumers include Groupon frontend services that render legal pages at paths such as `/legal/*` (e.g., `https://www.groupon.com/legal/paintball-usa-tickets-16`).

## Dependency Health

- MySQL health is monitored via Grafana dashboards (Tronicon CMS dashboard) and Kibana log-based alerts
- Database issues should be escalated to the GDS team via Slack `#gds-daas`
- Pod liveness and readiness are managed by Kubernetes; the standard status endpoint (`/grpn/status` on port `8080`) is declared but disabled per `.service.yml`
- APM endpoint health does not block service operation
