---
service: "arbitration-service"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumArbitrationService]
---

# Architecture Context

## System Context

The Arbitration Service is a backend API within the Continuum platform, sitting at the decisioning layer of the Marketing Delivery pipeline. Marketing delivery clients call it synchronously during campaign send workflows to determine which campaign wins for a given user. It depends on three data stores (`absPostgres`, `absCassandra`, `absRedis`) for rule evaluation and history tracking, and integrates with `optimizelyService` for experiment-driven algorithm configuration. Administrative delivery rule changes trigger approval tickets in `continuumJiraService`. Operational alerts are dispatched via `notificationEmailService`. Metrics are published to `telegrafMetrics`.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Arbitration Service | `continuumArbitrationService` | Service, API | Go + Martini | 1.19 | Core arbitration and best-for decisioning engine; exposes HTTP REST API |

## Components by Container

### Arbitration Service (`continuumArbitrationService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `apiHandlers` | Martini HTTP handlers; routes incoming requests to logic layers | Go + Martini |
| `arbitrationLogic` | Core arbitration and ranking decision logic; enforces quota and selects winner | Go |
| `bestForLogic` | Best-for campaign filtering, de-duplication, and quota enforcement | Go |
| `deliveryRuleManager` | Delivery rule configuration CRUD, refresh, and approval workflow triggers | Go |
| `campaignMetaAccess` | Campaign metadata, send history, and audience attributes from persistent stores | Go |
| `experimentationAdapter` | Fetches and evaluates experimentation settings and algorithm flags from Optimizely | Go + Optimizely SDK |
| `notificationAdapterArbSer` | Sends operational notifications via email | Go |
| `metricsAdapter` | Publishes request counters and latency timers to StatsD/Telegraf | Go + StatsD |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `marketingDeliveryClients` | `continuumArbitrationService` | Invokes best-for, arbitrate, and revoke APIs | REST/HTTPS |
| `continuumArbitrationService` | `absPostgres` | Reads/writes campaign metadata, delivery rules, user attributes | PostgreSQL |
| `continuumArbitrationService` | `absCassandra` | Reads/writes send history and frequency caps | CQL |
| `continuumArbitrationService` | `absRedis` | Reads/writes decisioning counters and cached campaign data | Redis |
| `continuumArbitrationService` | `optimizelyService` | Fetches experiment definitions and variant context | HTTPS/SDK |
| `continuumArbitrationService` | `continuumJiraService` | Creates/updates approval workflow tickets for pending config changes | HTTPS |
| `continuumArbitrationService` | `notificationEmailService` | Sends operational notification emails | SMTP/HTTP |
| `continuumArbitrationService` | `telegrafMetrics` | Publishes request and latency metrics | StatsD/UDP |

## Architecture Diagram References

- System context: `contexts-arbitrationService`
- Container: `containers-arbitrationService`
- Component: `components-continuumArbitrationService`
