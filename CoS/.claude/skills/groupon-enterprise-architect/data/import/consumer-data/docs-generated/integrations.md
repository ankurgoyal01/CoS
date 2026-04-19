---
service: "consumer-data"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 2
internal_count: 3
---

# Integrations

## Overview

Consumer Data Service has two external HTTP dependencies (bhoomi for geo enrichment and bhuvan for external data) and three internal platform integrations (MessageBus for async events, Users Service via events, and pwa for legacy data). All outbound HTTP calls use typhoeus with service_discovery_client for endpoint resolution.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| bhoomi | rest | Fetches GeoDetails for location enrichment | no | `bhoomi` (stub) |
| bhuvan | rest | Reads external consumer data | no | `bhuvan` (stub) |

### bhoomi Detail

- **Protocol**: HTTP REST
- **Base URL / SDK**: Resolved via service_discovery_client; typhoeus used for requests
- **Auth**: No evidence found in codebase for specific auth mechanism
- **Purpose**: Enriches consumer location records with geographic details (city, region, timezone, etc.)
- **Failure mode**: Location enrichment degrades gracefully; core profile data unaffected
- **Circuit breaker**: No evidence found in codebase

### bhuvan Detail

- **Protocol**: HTTP REST
- **Base URL / SDK**: Resolved via service_discovery_client; typhoeus used for requests
- **Auth**: No evidence found in codebase for specific auth mechanism
- **Purpose**: Reads supplementary external consumer data to augment profile records
- **Failure mode**: No evidence found in codebase for explicit fallback behaviour
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| MessageBus | message-bus | Publishes consumer/location change events; consumes GDPR and account-creation events | `mbus` (stub) |
| Users Service | event (mbus) | Receives `jms.topic.users.account.v1.created` to provision new consumer records | No architecture ref in federated model |
| pwa | rest | Reads legacy consumer data for backward-compatible views | `pwa` (stub) |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

- Outbound HTTP calls to bhoomi and bhuvan use typhoeus, which supports configurable timeouts and retries.
- MessageBus client (messagebus 0.3.7) manages connection and retry behaviour for event publishing and consumption.
- service_discovery_client (2.2.3) resolves service endpoints dynamically; failure to resolve will prevent outbound calls.
- No evidence found in codebase for explicit circuit breaker or bulkhead patterns.
