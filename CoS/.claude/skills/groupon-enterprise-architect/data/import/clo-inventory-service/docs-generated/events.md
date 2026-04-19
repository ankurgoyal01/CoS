---
service: "clo-inventory-service"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

Based on the architecture DSL model, CLO Inventory Service is primarily a synchronous REST-based service. The architecture model does not define any explicit message bus, Kafka, or pub/sub integrations. All inter-service communication is conducted via HTTP/JSON REST calls to downstream services (`continuumCloCoreService`, `continuumCloCardInteractionService`, `continuumDealCatalogService`, `continuumM3MerchantService`, `continuumM3PlacesService`).

This service does not publish or consume async events based on the current architecture model.

## Published Events

No async events published. All state changes are communicated via synchronous HTTP calls to `continuumCloCoreService` (for offer/claim/enrollment updates) and through database writes to `continuumCloInventoryDb`.

## Consumed Events

No async events consumed. All data ingestion occurs via synchronous HTTP calls from upstream consumers hitting the REST API surface.

## Notes

- If the service does participate in async messaging (e.g., via JTIER Message Bus or Kafka), this should be documented by the service owner once confirmed
- Card enrollment state changes are communicated synchronously to `continuumCloCoreService` via the Consent Domain & Services component
- Product and inventory state changes are persisted directly to PostgreSQL and cached in Redis

> This service does not publish or consume async events based on the current architecture model. Service owners should update this section if async messaging is introduced.
