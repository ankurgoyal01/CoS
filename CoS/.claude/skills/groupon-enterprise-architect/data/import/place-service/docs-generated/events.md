---
service: "place-service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

The M3 Place Service includes the Groupon internal message bus client (`mbus-client` 1.5.2) as a dependency, indicating integration with the Groupon message bus (mbus) for async event processing. The service also hosts two worker sidecar deployments — `sf-m3-synchronizer-worker` (Salesforce-to-M3 synchronization) and `m3-reverser-negotiator-worker` (reverse negotiator processing) — which operate as separate Kubernetes deployments within the same service boundary and are likely event-driven consumers. Specific topic names and event schemas for the worker sidecars are owned by their respective image repositories (`docker-conveyor.groupondev.com/m3/sf-m3-synchronizer` and `docker-conveyor.groupondev.com/com.groupon.m3/reverse-negotiator`) and are not defined in this repository's source code.

## Published Events

> No evidence found in codebase for events published directly by the `placereadservice` application. Place write operations trigger synchronous responses and internal Voltron workflow calls rather than async event publication.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| Salesforce sync topic (via mbus) | Salesforce place record update | `sf-m3-synchronizer-worker` sidecar | Creates or updates M3 place records sourced from Salesforce |
| Reverse negotiator topic (via mbus) | Place negotiation event | `m3-reverser-negotiator-worker` sidecar | Processes reverse negotiation workflows for place data reconciliation |

### Salesforce Synchronizer Worker Detail

- **Topic**: Salesforce-to-M3 sync topic (managed by `sf-m3-synchronizer` image)
- **Handler**: `sf-m3-synchronizer-worker` Kubernetes deployment (image: `docker-conveyor.groupondev.com/m3/sf-m3-synchronizer`, version: `1.0.2025.08.25_12.51_58fc1c5`)
- **Idempotency**: Not determinable from this repository
- **Error handling**: Not determinable from this repository
- **Processing order**: Not determinable from this repository
- **Source names processed**: Includes salesforce, salesforce_account, salesforce_lead, salesforce_performer, salesforce_account_international, plus many third-party aggregators (Yelp, Foursquare, Google Places, TripAdvisor, etc.) — configured via `SOURCE_NAMES` environment variable

### Reverse Negotiator Worker Detail

- **Topic**: Reverse negotiation topic (managed by `reverse-negotiator` image)
- **Handler**: `m3-reverser-negotiator-worker` Kubernetes deployment (image: `docker-conveyor.groupondev.com/com.groupon.m3/reverse-negotiator`, version: `1.0.2024.11.21_08.16_6dc3f23`)
- **Idempotency**: Not determinable from this repository
- **Error handling**: Not determinable from this repository
- **Processing order**: Not determinable from this repository

## Dead Letter Queues

> No evidence found in codebase for explicitly configured dead letter queues. Error handling for worker sidecars is managed within the respective worker images.
