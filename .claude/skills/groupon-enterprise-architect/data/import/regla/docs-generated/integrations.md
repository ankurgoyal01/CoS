---
service: "regla"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 0
internal_count: 10
---

# Integrations

## Overview

regla has a broad set of internal Continuum platform dependencies — ten in total — spanning event streaming (Kafka), async messaging (MessageBus), action delivery services (Rocketman, Email Campaign, Incentive Service), data platform services (Watson-KV, STAAS, TSD Aggregator), event routing (Event Delivery Service, Janus), and taxonomy (Taxonomy Service v2). All outbound HTTP calls use commons-httpclient 3.1.

## External Dependencies

> No evidence found in codebase for external (non-Groupon) dependencies.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Taxonomy Service v2 | rest | Resolves category hierarchy for rule condition evaluation (`/categoryInCategoryTree`) | No architecture ref in federated model |
| Deal Catalog | rest | Resolves deal metadata for rule conditions | No architecture ref in federated model |
| Email Campaign | rest | Dispatches email campaign actions triggered by rule evaluation | No architecture ref in federated model |
| Event Delivery Service | rest | Routes rule-triggered events to delivery channels | No architecture ref in federated model |
| Kafka | event-stream | Consumes deal-purchase and browse event streams; publishes `im_push_regla_delayed_instances_spark` and `janus-tier2` | No architecture ref in federated model |
| Watson-KV | rest | Key-value store integration for rule state or configuration | No architecture ref in federated model |
| Incentive Service | rest | Dispatches incentive grants triggered by rule evaluation | No architecture ref in federated model |
| Rocketman v2 | rest | Dispatches push notification actions triggered by rule evaluation | No architecture ref in federated model |
| MessageBus | message-bus | Consumes inbound Continuum MessageBus events for rule evaluation triggers | No architecture ref in federated model |
| TSD Aggregator | metrics | Receives application metrics emitted by metrics-sma-influxdb | No architecture ref in federated model |
| STAAS | rest | Storage-as-a-service integration (exact purpose not specified in inventory) | No architecture ref in federated model |

### Taxonomy Service v2 Detail

- **Protocol**: HTTP REST
- **Base URL / SDK**: Resolved via service endpoint; commons-httpclient 3.1
- **Auth**: No evidence found in codebase for specific auth mechanism
- **Purpose**: Provides category hierarchy data for `GET /categoryInCategoryTree` evaluation and rule condition matching
- **Failure mode**: Category tree resolution falls back to Redis-cached taxonomy data; if both unavailable, evaluation may be skipped
- **Circuit breaker**: No evidence found in codebase

### Rocketman v2 Detail

- **Protocol**: HTTP REST
- **Base URL / SDK**: commons-httpclient 3.1
- **Auth**: No evidence found in codebase for specific auth mechanism
- **Purpose**: Delivers push notification actions when a rule fires for a user
- **Failure mode**: Rule fires but push notification not delivered; execution record written with failed action status
- **Circuit breaker**: No evidence found in codebase

### Email Campaign Detail

- **Protocol**: HTTP REST
- **Base URL / SDK**: commons-httpclient 3.1
- **Auth**: No evidence found in codebase for specific auth mechanism
- **Purpose**: Triggers email campaign sends when a rule fires for a user
- **Failure mode**: Rule fires but email not sent; execution record written with failed action status
- **Circuit breaker**: No evidence found in codebase

### Incentive Service Detail

- **Protocol**: HTTP REST
- **Base URL / SDK**: commons-httpclient 3.1
- **Auth**: No evidence found in codebase for specific auth mechanism
- **Purpose**: Grants incentives (coupons, credits) to users when an incentive rule fires
- **Failure mode**: Incentive not granted; execution record written with failed action status
- **Circuit breaker**: No evidence found in codebase

## Consumed By

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

- All outbound HTTP calls use commons-httpclient 3.1; timeout and retry configuration not specified in inventory.
- Kafka consumer group offset management provides retry capability for stream processing failures.
- Redis cache provides fallback for Taxonomy Service unavailability.
- No evidence found in codebase for explicit circuit breaker or bulkhead patterns.
