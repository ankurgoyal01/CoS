---
service: "etorch"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 7
internal_count: 2
---

# Integrations

## Overview

eTorch integrates with nine downstream systems: two within the federated Continuum model and seven external services. All integrations use synchronous REST over HTTP. The `continuumEtorchApp` container handles real-time API-driven integrations; the `continuumEtorchWorker` container handles integrations needed for batch and scheduled jobs.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Getaways Inventory | REST | Reads and writes hotel inventory data; runs inventory maintenance jobs | yes | `getawaysInventoryExternal_b51b` |
| Getaways Content | REST | Reads hotel content and metadata; runs content sync jobs | yes | `getawaysContentExternal_1467` |
| LARC | REST | Reads approved rates and discounts for hotel deals | yes | `larcExternal_ce2d` |
| Channel Manager Integrator (Synxis) | REST | Syncs channel manager mappings for hotels | yes | `channelManagerIntegratorSynxisExternal_99f9` |
| MX Merchant API | REST | Reads merchant account information | yes | `mxMerchantApiExternal_b545` |
| Rocketman | REST | Sends commercial notifications to merchants | no | `rocketmanCommercialExternal_1d14` |
| Notification Service | REST | Sends notification emails to hotel operators; sends batch notifications from worker jobs | no | `notificationServiceExternal_5b7e` |

### Getaways Inventory Detail

- **Protocol**: REST (HTTP)
- **Purpose**: Primary source of truth for hotel inventory. eTorch App reads and writes availability and rate data on behalf of merchants; eTorch Worker runs periodic inventory maintenance and sync jobs.
- **Failure mode**: API calls fail; merchant-facing inventory read/write requests return errors; scheduled maintenance jobs may be delayed.
- **Circuit breaker**: > No evidence found

### Getaways Content Detail

- **Protocol**: REST (HTTP)
- **Purpose**: Provides hotel metadata, descriptions, and media assets referenced in extranet views. eTorch Worker syncs content on a scheduled basis.
- **Failure mode**: Stale or missing content in extranet responses; content sync jobs fail.
- **Circuit breaker**: > No evidence found

### LARC Detail

- **Protocol**: REST (HTTP)
- **Purpose**: Supplies approved rates and discount rules used when presenting or validating hotel deals through the extranet.
- **Failure mode**: Rate and discount data unavailable for deal operations.
- **Circuit breaker**: > No evidence found

### Channel Manager Integrator (Synxis) Detail

- **Protocol**: REST (HTTP)
- **Purpose**: Synchronizes channel manager configuration and mappings. Enables hotels using Synxis to manage their Groupon Getaways listings through the extranet.
- **Failure mode**: Channel manager mapping data may be stale; hotel operators using Synxis cannot complete sync operations.
- **Circuit breaker**: > No evidence found

### MX Merchant API Detail

- **Protocol**: REST (HTTP)
- **Purpose**: Retrieves merchant profile and account information used to populate extranet views and validate merchant identity.
- **Failure mode**: Merchant information unavailable; certain extranet views cannot be rendered.
- **Circuit breaker**: > No evidence found

### Rocketman Detail

- **Protocol**: REST (HTTP)
- **Purpose**: Delivers commercial notifications (e.g., deal status updates) to merchants.
- **Failure mode**: Notifications are not sent; non-critical to core extranet operations.
- **Circuit breaker**: > No evidence found

### Notification Service Detail

- **Protocol**: REST (HTTP)
- **Purpose**: Sends transactional email notifications to hotel operators triggered by API actions and batch worker jobs.
- **Failure mode**: Notification emails are not delivered; non-critical to core extranet operations.
- **Circuit breaker**: > No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Management API | REST | Receives deal data updates triggered by the eTorch App | `continuumDealManagementApi` |
| Accounting Service | REST | Provides accounting statement and payment data (read by eTorch App); accepts accounting report generation requests (from eTorch Worker) | `continuumAccountingService` |

### Deal Management API Detail

- **Protocol**: REST (HTTP)
- **Purpose**: eTorch App pushes deal update payloads to the Deal Management API when merchants submit changes through the extranet or when a deal update batch job is triggered via `POST /v1/getaways/extranet/jobs/deal_update`.
- **Failure mode**: Deal updates fail; merchants receive errors on deal submission.
- **Circuit breaker**: > No evidence found

### Accounting Service Detail

- **Protocol**: REST (HTTP)
- **Purpose**: eTorch App queries this service to retrieve hotel accounting statements and payments surfaced via the `/getaways/v2/extranet/hotels/{uuid}/accounting` endpoints. eTorch Worker calls this service to generate periodic accounting reports.
- **Failure mode**: Accounting data unavailable; `GET /accounting/statements` and `GET /accounting/payments` return errors; scheduled accounting report jobs fail.
- **Circuit breaker**: > No evidence found

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Hotel operators and channel management systems access eTorch via the Getaways Extranet portal. The `/v1/getaways/extranet/jobs/deal_update` endpoint is consumed by internal orchestration processes.

## Dependency Health

> No evidence found for circuit breaker, retry, or formal health check patterns in the architecture model. Operational procedures to be defined by service owner.
