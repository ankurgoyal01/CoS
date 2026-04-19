---
service: "mbus-client"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 2
---

# Integrations

## Overview

The MBus Java Client Library has one primary external dependency — the MBus broker cluster — accessed over STOMP. It also integrates with two internal Groupon platform services: the metrics stack (via `metricslib`) and the logging stack (via SLF4J). Upstream consumers of this library are any Groupon Java services that embed it as a Maven dependency.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| MBus Broker Cluster | STOMP (TCP) | Deliver and receive asynchronous messages via queues and topics | yes | `messageBus` |
| MBus VIP / Concierge HTTP endpoint | HTTP | Fetch active broker host list for dynamic server discovery | yes | `messageBus` |

### MBus Broker Cluster Detail

- **Protocol**: STOMP 1.0 over TCP (port 61613)
- **Base URL / SDK**: VIP endpoints by colo and environment — e.g., `mbus-vip.snc1:61613` (NA prod), `mbus-vip.sac1:61613` (NA prod secondary), `mbus-vip.dub1:61613` (EMEA prod), `mbus-staging-vip.snc1:61613` (staging), `mbus-uat-vip.snc1:61613` (UAT)
- **Auth**: Username/password sent in STOMP `CONNECT` frame; default credentials `rocketman`/`rocketman`
- **Purpose**: The broker cluster stores, routes, and delivers messages between producers and consumers. Supports JMS-style queue and topic semantics with durable subscriptions.
- **Failure mode**: On TCP disconnection, `StompServerFetcher` attempts up to 3 reconnect retries (60-second sleep on exhaustion). `ProducerImpl` retries sends up to `publishMaxRetryAttempts` times. If broker is unreachable after all retries, `TooManyConnectionRetryAttemptsException` is thrown to the caller.
- **Circuit breaker**: No circuit breaker pattern; retry with sleep (`FAILURE_RETRY_INTERVAL = 60000 ms`) on exhaustion.

### MBus VIP Concierge Endpoint Detail

- **Protocol**: HTTP GET
- **Base URL**: `http://{vip-host}:{port}` — constructed from `HostParams` VIP address. Connect timeout: 1000 ms; read timeout: 5000 ms.
- **Auth**: None (internal network endpoint)
- **Purpose**: Returns a comma-separated list of active broker hosts in the MBus cluster (e.g., `mbus01.snc1:61613,mbus02.snc1:61613`). The consumer uses this to open individual STOMP connections to each active broker for parallel prefetching.
- **Failure mode**: If the endpoint is unreachable, server discovery fails and consumers cannot resolve broker hosts. Set `useDynamicServerList=false` to bypass for local testing.
- **Circuit breaker**: No circuit breaker; `DynamicServerListGetter` throws `IOException` on failure, which propagates to `ConsumerImpl` startup.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Metrics Stack (`metricslib`) | In-process JVM | Emit client-side publish metrics (publish count, latency) under configurable app name (`metricAppName`, default: `mbus`) | `metricsStack` |
| Logging Stack (SLF4J) | In-process JVM | Emit structured client and transport logs at DEBUG/INFO/WARN/ERROR levels via SLF4J facade | `loggingStack` |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

The library is consumed by any Groupon Java service that declares `com.groupon.messagebus:mbus-client` as a Maven dependency. Known consumer patterns include services in the order processing, notifications, and analytics domains on the Continuum platform.

## Dependency Health

- **MBus broker**: Health dashboards at `https://mbus-dashboard.groupondev.com/`, `https://groupon.wavefront.com/dashboard/mbus`, and CheckMK (`checkmk-lvl3.groupondev.com`). PagerDuty service: `https://groupon.pagerduty.com/services/PGG3KB5`.
- **Retry behavior**: `StompServerFetcher` retries connection up to `MAX_RETRY_COUNT` (3) times with `REST_INTERVAL` (1000 ms) between attempts. On exhaustion, sleeps `FAILURE_RETRY_INTERVAL` (60000 ms) before retrying.
- **Keepalive**: Both producer and consumer send STOMP keepalive frames at configurable `keepAlivePeriodSeconds` interval (default: 1 minute, from `StompConnection.KEEP_ALIVE_PERIOD`) to prevent broker from dropping idle connections.
- **Connection refresh**: `ProducerImpl` reconnects every `connectionLifetime` milliseconds (default: 300000 ms / 5 minutes) to rebalance load in clustered environments. `ConsumerImpl` also refreshes broker host list on the same interval.
