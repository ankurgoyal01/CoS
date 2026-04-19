---
service: "clo-service"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 4
internal_count: 7
---

# Integrations

## Overview

CLO Service has 4 external dependencies (Visa, Mastercard, Amex card networks and Rewards Network) and 7 internal Continuum service dependencies. External card network integrations use a combination of REST, SOAP/XML, and file-based (SFTP) protocols depending on the network. Internal service calls use REST over Faraday HTTP clients. Salesforce is accessed via the Restforce REST client for CRM and onboarding context. All outbound calls from the API layer are made through the `cloApiPartnerClients` component; network-specific batch and file processing is handled by `cloWorkerPartnerProcessors` in the worker.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Visa | REST / file-based | Card enrollment, transaction callbacks, batch settlement | yes | (external — not in federated model) |
| Mastercard | REST / file-based | Card enrollment, transaction callbacks, file-based settlement | yes | (external — not in federated model) |
| Amex | REST / SOAP | Card enrollment, network identifier workflows | yes | (external — not in federated model) |
| Rewards Network | REST | Offer activation and rewards balance reads | yes | (external — not in federated model) |
| Salesforce | REST | Merchant onboarding and CRM context | no | `salesForce` |

### Visa Detail

- **Protocol**: REST (Faraday) and file-based (SFTP/batch)
- **Base URL / SDK**: Visa CLO API; credentials managed via secrets
- **Auth**: Mutual TLS / API credentials
- **Purpose**: Enrolls consumer cards into CLO offers on the Visa network; receives qualifying transaction notifications; processes batch settlement files
- **Failure mode**: Enrollment failures prevent card activation; transaction callback failures may cause delayed claim processing; batch job retries handle file delivery failures
- **Circuit breaker**: No evidence found

### Mastercard Detail

- **Protocol**: REST (Faraday) and file-based (SFTP/batch)
- **Base URL / SDK**: Mastercard CLO API; credentials managed via secrets
- **Auth**: API key / certificate
- **Purpose**: Enrolls consumer cards on the Mastercard network; processes file-based statement credits; receives transaction callbacks
- **Failure mode**: Enrollment failures prevent card activation; file transfer failures trigger retry via FileTransfer event; statement credit delays possible
- **Circuit breaker**: No evidence found

### Amex Detail

- **Protocol**: SOAP / REST (Savon + Faraday)
- **Base URL / SDK**: Amex SOAP and REST APIs; credentials managed via secrets
- **Auth**: API key / WS-Security
- **Purpose**: Enrolls cards on the Amex network; processes network identifier workflows; handles offer activation
- **Failure mode**: Enrollment and identifier workflow failures may block offer activation for Amex cardholders
- **Circuit breaker**: No evidence found

### Rewards Network Detail

- **Protocol**: REST (Faraday)
- **Base URL / SDK**: Rewards Network REST API; credentials managed via secrets
- **Auth**: API key
- **Purpose**: Activates CLO offers on the Rewards Network; reads rewards balances for users
- **Failure mode**: Rewards balance unavailable; offer activation delayed
- **Circuit breaker**: No evidence found

### Salesforce Detail

- **Protocol**: REST (Restforce ~3.1.0)
- **Base URL / SDK**: Salesforce REST API via Restforce gem
- **Auth**: OAuth2 (Salesforce connected app)
- **Purpose**: Reads merchant onboarding records and CRM context to support offer ingestion and merchant resolution
- **Failure mode**: Merchant data unavailable; offer ingestion may degrade gracefully
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Orders Service | REST | Reads order and billing data for claim matching and statement credit processing | `continuumOrdersService` |
| Users Service | REST | Reads user account state and eligibility for enrollment and claim operations | `continuumUsersService` |
| Deal Catalog Service | REST / Message Bus | Reads and validates deal records; consumes deal distribution updates | `continuumDealCatalogService` |
| M3 Merchant Service | REST | Resolves merchant records for offer ingestion and claim matching | `continuumM3MerchantService` |
| Merchant Advisor | REST | Fetches merchant metrics for reporting and offer management | `merchantAdvisorService` |
| CLO Inventory Service | REST | Resolves CLO inventory resources for offer lifecycle management | `continuumCloInventoryService` |
| Third-Party Inventory Service | REST | Coordinates inventory sync for third-party offer sources | `continuumThirdPartyInventoryService` |
| Message Bus | Message Bus (messagebus 0.5.3) | Publishes and consumes all async domain events | `messageBus` |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Known inbound traffic sources based on API surface:
- Card networks (Visa, Mastercard) deliver transaction callbacks to `/clo/api/v1/visa` and `/clo/api/v1/mastercard`
- Internal Continuum services read user claims and enrollment state via `/clo/api/v2/users/{id}/...`
- Internal services publish events consumed by CLO Worker via Message Bus

## Dependency Health

> Operational procedures to be defined by service owner. No circuit breaker or explicit health check configuration is evidenced in the architecture inventory. Faraday timeout and retry configuration is expected but not enumerated in the inventory.
