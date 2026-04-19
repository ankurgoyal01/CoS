---
service: "voucher-archive-backend"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 1
internal_count: 7
---

# Integrations

## Overview

The voucher-archive-backend integrates with eight services. One is an external API (MX Merchant API for merchant auth). Seven are internal Continuum platform services covering authentication, messaging, image retrieval, deal catalog, city data, and GDPR erasure. All integrations use REST or the JMS message bus.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| MX Merchant API | rest | Validates merchant authentication tokens | yes | > No Structurizr ID found |

### MX Merchant API Detail

- **Protocol**: REST
- **Base URL / SDK**: Configured via environment variable; accessed via rest-client
- **Auth**: API key or merchant credentials (No evidence found in codebase for exact method)
- **Purpose**: Validates that a merchant caller holds a valid session before permitting redemption or bulk-redeem operations
- **Failure mode**: Merchant API calls will fail authentication; redemption requests are rejected
- **Circuit breaker**: No evidence found in codebase.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Users Service | rest | Validates consumer bearer tokens for API authentication | `continuumUsersService` |
| CS Token Service | rest | Validates CSR session tokens for API authentication | `continuumCsTokenService` |
| Message Bus | jms | Publishes GDPR erasure completion events; consumes GDPR erasure requests | `messageBus` |
| Retcon Service | rest | Executes PII erasure for GDPR right-to-be-forgotten requests | `continuumRetconService` |
| Image Service | rest | Retrieves images associated with deal records | `continuumImageService` |
| Deal Catalog Service | rest | Retrieves supplementary deal metadata | `continuumDealCatalogService` |
| City Service | rest | Retrieves city/location data associated with deals | `continuumCityService` |

### Users Service Detail

- **Protocol**: REST
- **Base URL / SDK**: Configured via environment variable; accessed via rest-client
- **Auth**: Service-to-service credentials
- **Purpose**: Validates consumer bearer tokens on every authenticated consumer API call
- **Failure mode**: Consumer requests fail authentication; 401 returned to caller
- **Circuit breaker**: No evidence found in codebase.

### CS Token Service Detail

- **Protocol**: REST
- **Base URL / SDK**: Configured via environment variable; accessed via rest-client
- **Auth**: Service-to-service credentials
- **Purpose**: Validates CSR session tokens on every authenticated CSR API call
- **Failure mode**: CSR requests fail authentication; 401 returned to caller
- **Circuit breaker**: No evidence found in codebase.

### Message Bus Detail

- **Protocol**: JMS
- **Base URL / SDK**: messagebus gem
- **Auth**: Configured via environment variable
- **Purpose**: Bidirectional GDPR compliance event channel — consumes `jms.topic.gdpr.account.v1.erased`, publishes `jms.queue.gdpr.account.v1.erased.complete`
- **Failure mode**: GDPR erasure processing stalls; events remain unconsumed
- **Circuit breaker**: No evidence found in codebase.

### Retcon Service Detail

- **Protocol**: REST
- **Base URL / SDK**: Configured via environment variable; accessed via rest-client
- **Auth**: Service-to-service credentials
- **Purpose**: Executes the actual PII data erasure for GDPR right-to-be-forgotten; called by `RightToBeForgottenWorker` after receiving an erasure event
- **Failure mode**: GDPR erasure incomplete; worker retries or enters error state
- **Circuit breaker**: No evidence found in codebase.

## Consumed By

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

> No evidence found in codebase. Health checks for downstream dependencies are likely performed via Rails initializers or Resque worker startup checks.
