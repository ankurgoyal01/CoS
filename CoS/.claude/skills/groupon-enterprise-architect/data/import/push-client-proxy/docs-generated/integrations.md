---
service: "push-client-proxy"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 3
---

# Integrations

## Overview

push-client-proxy has three external dependencies (Bloomreach as a caller, an SMTP relay for delivery, and InfluxDB for metrics) and three internal Groupon dependencies (the Kafka broker, the Audience Management Service as a caller, and the Redis/PostgreSQL infrastructure it owns). Bloomreach and the Audience Management Service are upstream callers; the SMTP relay and InfluxDB are downstream write targets.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Bloomreach | HTTPS (REST) | Calls the email send and verify APIs to route outbound emails | yes | `bloomreach` |
| SMTP Relay | SMTP | Receives injected email messages for delivery | yes | `smtpRelay` |
| InfluxDB | HTTP | Receives operational metrics published via Groupon SMA metrics library | no | `influxDb` |

### Bloomreach Detail

- **Protocol**: HTTPS REST (inbound calls to this service)
- **Base URL / SDK**: Bloomreach calls `POST /email/send-email` and `GET /email/verify` on push-client-proxy
- **Auth**: `Chan-Example-Token` request header (validation is currently permissive in production)
- **Purpose**: External email marketing platform that delegates outbound email injection and credential verification to push-client-proxy
- **Failure mode**: Bloomreach receives an HTTP error response; no internal retry is triggered from this service's side for inbound API failures
- **Circuit breaker**: No

### SMTP Relay Detail

- **Protocol**: SMTP
- **Base URL / SDK**: Configured via `email.injector.injector.defaultHostname` and `email.injector.injector.defaultPort` properties; SMTP connection pool managed by `DefaultMailSender`
- **Auth**: SMTP session credentials managed via `EmailConfiguration`; retry-on-connect-error configured via `email.injector.injector.retriesOnConnectErrors`
- **Purpose**: Receives MimeMessage objects from `EmailInjectorService` for outbound email delivery
- **Failure mode**: SMTP send failure is caught; if retry budget remains the message is republished to `email-send-topic`; otherwise it is dropped
- **Circuit breaker**: No — retry logic is handled via Kafka republish

### InfluxDB Detail

- **Protocol**: HTTP
- **Base URL / SDK**: Configured via `metrics.url` and `metrics.dbname` properties using Groupon `metrics-sma-influxdb` library
- **Auth**: `metrics.username` / `metrics.password` credentials (externalized)
- **Purpose**: Receives counters and timers under the `custom.cdp.*` namespace for email and audience endpoint monitoring
- **Failure mode**: Metrics are batched and flushed every 1000 ms (configurable via `metrics.flush-duration-millis`); metrics loss on InfluxDB unavailability
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Kafka Broker | Kafka (SSL/TLS) | Delivers `msys_delivery` and `email-send-topic` events for consumption; receives published retry messages | `continuumKafkaBroker` |
| Primary Redis Cluster | Redis | Email metadata cache, audience keys, rate-limit token buckets | `continuumPushClientProxyRedisPrimary` |
| Incentive Redis Cluster | Redis | Audience incentive treatment keys | `continuumPushClientProxyRedisIncentive` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Bloomreach | HTTPS | Sends email messages and verifies credentials |
| `continuumAudienceManagementService` | HTTPS | Patches and queries audience membership |

> Upstream consumers are also tracked in the central architecture model (`architecture/models/relations.dsl`).

## Dependency Health

- **Kafka**: Consumer session timeout is 30 seconds with a 10-second heartbeat interval. Reconnect backoff starts at 1 second and caps at 10 seconds. On processing errors, acknowledgment is withheld so Kafka retries automatically.
- **Redis**: Lettuce connection pool configured with `redis.maxConnections` (default 10) and `redis.commandTimeOutMs` (default 1000 ms). The rate limiter Redis client uses a 500 ms connection timeout.
- **PostgreSQL / MySQL**: JPA connection pools managed by Spring Boot defaults; no circuit breaker configured.
- **SMTP**: Retry-on-connect-error attempts controlled by `email.injector.injector.retriesOnConnectErrors` with `email.injector.injector.millisecondDelayBetweenConnectionRetries` delay between attempts.
