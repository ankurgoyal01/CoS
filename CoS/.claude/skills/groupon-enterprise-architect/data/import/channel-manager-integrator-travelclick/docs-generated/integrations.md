---
service: "channel-manager-integrator-travelclick"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 4
---

# Integrations

## Overview

The service has one critical external dependency (TravelClick) and four internal Groupon platform dependencies (MBus, Kafka, Getaways Inventory service, and MySQL via DaaS). TravelClick is both a caller (pushes ARI data) and a callee (receives reservation/cancellation OTA XML). All outbound HTTP calls use JTier OkHttp.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| TravelClick | HTTPS / OTA XML | Receives OTA reservation and cancellation XML; pushes ARI data to REST endpoints | yes | `travelclickPlatform` |

### TravelClick Detail

- **Protocol**: HTTPS with OTA XML payload (OpenTravel Alliance 2003/05 namespace)
- **Base URL / SDK**: Not hardcoded in committed files; configured via JTier run config YAML (`JTIER_RUN_CONFIG` env var per environment)
- **Auth**: HTTP Basic Authentication (as defined in `doc/schema.yml` and `doc/swagger/config.yml`)
- **Purpose**: TravelClick is the channel manager partner. The service sends OTA-formatted reservation and cancellation requests to TravelClick when Groupon customers book or cancel hotel stays. TravelClick also calls this service's REST endpoints to push hotel availability, inventory, and rate updates.
- **Failure mode**: If TravelClick is unreachable, OTA calls from the MBus consumer will fail; messages may be sent to the MBus DLQ for retry. ARI push messages from TravelClick would not be received during downtime.
- **Circuit breaker**: No explicit circuit breaker visible in the available inventory; JTier OkHttp may provide timeout configuration.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| MBus | MBus | Consumes reservation and cancellation messages; publishes processing response messages | `messageBus` |
| Kafka | Kafka | Publishes ARI events after processing TravelClick push notifications | `kafkaCluster` |
| Getaways Inventory | HTTP/REST | Fetches hotel hierarchy and hotel product data required to build TravelClick requests | `getawaysInventoryService` |
| MySQL (DaaS) | JDBC | Persists reservation records, TravelClick request/response audit logs, and ARI data | `continuumChannelManagerIntegratorTravelclickMySql` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. TravelClick is the direct caller of this service's REST endpoints (`/getaways/v2/partner/travelclick/...`).

## Dependency Health

- **MBus**: DLQ-backed; failed message consumption results in messages being routed to the dead letter queue for retry. Monitored via PagerDuty `PEAIXM8`.
- **Kafka**: Producer with `kafka-clients` 0.10.2.1; no explicit circuit breaker configured in available inventory.
- **Getaways Inventory**: HTTP calls via JTier OkHttp; failure would block ARI controller processing. No explicit fallback or circuit breaker visible.
- **MySQL (DaaS)**: Managed by the JTier DaaS layer (`jtier-daas-mysql`); connection pooling and health checks are provided by the framework.
- **TravelClick**: No circuit breaker visible; timeouts managed by OkHttp configuration. Contact procedures documented in the original runbook (moved to Confluence).
