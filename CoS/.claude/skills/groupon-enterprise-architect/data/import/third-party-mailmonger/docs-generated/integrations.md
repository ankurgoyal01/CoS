---
service: "third-party-mailmonger"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 3
---

# Integrations

## Overview

Third Party Mailmonger has two external third-party integrations (SparkPost and MTA) and three internal Groupon platform dependencies (users-service, PostgreSQL via DaaS, and MessageBus). SparkPost is the critical path for both inbound email relay and outbound delivery. The MTA is a configurable fallback carrier. Users-service provides consumer and partner metadata required for address resolution and filtering.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| SparkPost | HTTPS / Webhook | Receives inbound relay emails; sends outbound emails to real addresses | yes | `sparkpost` |
| MTA (Mail Transfer Agent) | SMTP (Jakarta Mail) | Fallback email delivery channel; alternative to SparkPost for outbound sends | no | `mta` |

### SparkPost Detail

- **Protocol**: HTTPS (outbound API calls via SparkPost SDK); inbound relay webhook over HTTPS POST to `/mailmonger/v1/sparkpost-callback`
- **Base URL / SDK**: SparkPost SDK `sparkpost-lib:0.21`; base URL configured via `sparkpostClient.baseUrl` in JTier YAML config
- **Auth**: API key configured via `sparkpostClient.apiKey` in JTier YAML config (secret — value not stored in code)
- **Purpose**: SparkPost acts as the email relay gateway. Partners send SMTP to a SparkPost-managed domain; SparkPost forwards the relay message as an HTTP webhook POST to Mailmonger. Mailmonger then uses SparkPost's sending API to deliver the re-addressed email to the real recipient. SparkPost is the primary outbound carrier (`EmailClientType.SPARKPOST`).
- **Failure mode**: SparkPost failures result in `SparkpostFailure` email status. The message bus retry mechanism retries up to `MAX_SEND_LIMIT` (3) times. After exhaustion, the email is marked terminal.
- **Circuit breaker**: No evidence of a dedicated circuit breaker; retry logic is bounded by `MAX_SEND_LIMIT`.

### MTA (Mail Transfer Agent) Detail

- **Protocol**: SMTP via Jakarta Mail API (`jakarta.mail-api:2.1.2`)
- **Base URL / SDK**: Host(s) and port configured via `mtaClient.host` (list) and `mtaClient.port` in JTier YAML config
- **Auth**: No evidence of MTA auth in code; likely network-level trust
- **Purpose**: Direct SMTP delivery when `emailCarrierConfiguration.emailClientType` is set to MTA. Custom headers `X-RM-EmailName`, `X-RM-Clr`, `X-RM-SendID`, `X-RM-JobId`, `x-virtual-mta: mailmonger` are injected for routing and tracking. Consumer emails use header `X-RM-EmailName: mailmonger-customer`; partner emails use `mailmonger-merchant`.
- **Failure mode**: MTA failures result in `MtaFailure` email status, subject to retry logic.
- **Circuit breaker**: No evidence found in codebase.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| users-service | HTTP (Retrofit) | Fetches real consumer email addresses and partner metadata by UUID for address resolution during email relay | `continuumUsersService` |
| PostgreSQL (DaaS) | JDBC | Persistent storage for all email state, masked addresses, partner data, and Quartz scheduler state | `daasPostgres` |
| MessageBus (ActiveMQ Artemis) | Mbus (STOMP) | Async queue for inbound email processing; decouples SparkPost webhook receipt from filter and send pipeline | `messageBus` |

### users-service Detail

- **Protocol**: HTTP via Retrofit (`jtier-retrofit`)
- **Base URL**: Configured via `userServiceClient` Retrofit configuration in JTier YAML
- **Auth**: Internal service-to-service (network trust)
- **Purpose**: Resolves real consumer email addresses from consumer UUIDs so that outbound relay emails can be addressed correctly. Also used by `UsersServicePollingTask` for periodic data refresh. SLA agreement: TP99 60ms, 10 rps, 99.9% uptime (as documented in `sla.yml`).
- **Failure mode**: If users-service is unavailable, email address resolution fails and the email cannot be sent; email is retried via message bus up to MAX_SEND_LIMIT.
- **Circuit breaker**: Managed by Retrofit / JTier HTTP client configuration.

### MessageBus (ActiveMQ Artemis) Detail

- **Protocol**: Mbus STOMP via `jtier-messagebus-client`
- **Queue**: `jms.queue.3pip.mailmonger`
- **Purpose**: Provides durable async processing for email pipeline; enables retry without blocking the SparkPost webhook response
- **Failure mode**: If MessageBus is unavailable at webhook receipt time, inbound emails may not be queued for processing

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| TPIS / Spaceman (Third-Party Inventory Service) | REST | Calls `GET /v1/masked/consumer/{consumerId}/{partnerId}` during deal reservation to obtain masked email for checkout fields |
| SparkPost (relay webhook) | HTTPS Webhook | Calls `POST /mailmonger/v1/sparkpost-callback` for every inbound email on the configured relay domain |
| Customer Support tooling | REST | Calls `GET /v1/emails` and `GET /v1/emails/{id}` to inspect email history |

> Upstream consumers beyond those listed are tracked in the central Groupon architecture model.

## Dependency Health

- **users-service**: Monitored via Wavefront dashboards; SLA agreement requires TP99 60ms and 99.9% uptime
- **MessageBus**: Monitored via mbus graphs at `https://mbus-dashboard.groupondev.com/`; PagerDuty alert fires when queue depth or response time exceeds thresholds
- **SparkPost**: External status at `http://status.sparkpost.com/`; webhook failures monitored via `sourcetype=mailmonger` in Splunk/Kibana
- **PostgreSQL**: Monitored via DaaS dashboards and Wavefront metrics
