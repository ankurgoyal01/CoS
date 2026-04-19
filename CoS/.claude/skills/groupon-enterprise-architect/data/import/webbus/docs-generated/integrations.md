---
service: "webbus"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 1
---

# Integrations

## Overview

Webbus has two runtime dependencies: one external system (Salesforce) that acts as the sole API caller, and one internal platform (the Groupon Message Bus) that receives the published messages. There are no other runtime integrations. The service has no database, cache, or third-party service dependencies beyond these two.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | REST (HTTP POST) | Sole authorised caller; sends batches of CRM change events for publication to the Message Bus | yes | `salesForce` |

### Salesforce Detail

- **Protocol**: REST over HTTPS
- **Base URL / SDK**: `webbus.groupon.com` (external VIP, IP-whitelisted to Salesforce source addresses)
- **Auth**: Salesforce authenticates itself using a known `client_id` value from `config/clients.yml` (e.g., `salesforce-aGVsbG9fY2hyaXNfYmxhbmQ=` in staging/production)
- **Purpose**: Salesforce creates messages on CRM object changes, batches them, and POSTs them to `/v2/messages/`. Webbus validates and forwards these messages to the Message Bus. Any failures are synchronously returned to Salesforce for redelivery.
- **Failure mode**: If Webbus is unavailable, Salesforce retains the pending messages and retries. If a hung or failed response is returned, Salesforce redelivers all messages in the batch.
- **Circuit breaker**: No evidence found in codebase. No circuit breaker is implemented for inbound requests.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Message Bus | STOMP over TCP (port 61613) | Receives all validated messages published by Webbus | `messageBus` |

### Message Bus Detail

- **Protocol**: STOMP (Simple Text Oriented Message Protocol) over TCP port 61613
- **Client library**: `messagebus` gem version `0.2.10`
- **Production endpoint**: `mbus-prod-na.us-central1.mbus.prod.gcp.groupondev.com:61613`
- **Staging endpoint**: `mbus-stg-na.us-central1.mbus.stable.gcp.groupondev.com:61613`
- **Auth**: Username/password credentials supplied via `WEBBUS_MESSAGEBUS_USER` and `WEBBUS_MESSAGEBUS_PASSWORD` environment variables
- **Purpose**: All validated messages are published to JMS topics on the Message Bus. This is the primary and only data output of the service.
- **Failure mode**: Publication failures are caught per-message via `rescue StandardError`; failed messages are collected and returned to the caller as a `400` response, signalling Salesforce to redeliver them. The service does not retry internally.
- **Circuit breaker**: No evidence found in codebase.

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Salesforce | REST (HTTP POST) | Publishes CRM change events to the Message Bus via Webbus |

> Upstream consumers beyond Salesforce are not tracked in this repository. Downstream subscribers to the `jms.topic.salesforce.*` topics are tracked in the central architecture model.

## Dependency Health

- **Message Bus connection**: The `Messagebus::Client` is initialised lazily on first use (`Webbus.messagebus`) and held as a module-level singleton. `enable_auto_init_connections: true` is set in `config/messagebus.yml`, which allows the client to re-establish dropped connections.
- **Receipt wait timeout**: Production is configured with a `receipt_wait_timeout_ms` of `6000` ms; staging uses `3000` ms.
- **Connection lifetime**: Both environments use a `conn_lifetime_sec` of `300` seconds.
- **Health endpoint**: `GET /grpn/healthcheck` confirms the Rack application is alive; it does not probe Message Bus connectivity.
