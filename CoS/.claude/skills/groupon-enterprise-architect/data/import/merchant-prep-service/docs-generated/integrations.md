---
service: "merchant-prep-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 6
---

# Integrations

## Overview

The Merchant Preparation Service integrates with three external systems (Salesforce, Adobe Sign, and Fonoa) and six internal Continuum services. All outbound HTTP calls use Retrofit 2 clients generated from OpenAPI specs and wrapped with RxJava 3 reactive types. Client configurations (base URLs, timeouts) are injected via the JTier YAML configuration file per environment. The service also reads from a TinCheck SOAP endpoint for legacy TIN validation. Upstream callers reach this service through UMAPI.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce (Force.com) | REST (OAuth2) | Account, opportunity, and contact CRUD; field reads for tax, payment, billing | yes | `salesForce` |
| Adobe Sign API | REST (OAuth2) | Fetches agreement URLs and manages document signing workflows | no | stub: `unknown_adobesignapi_2bbbc5fb` |
| Fonoa | REST | TIN/VAT number validation for EU merchants | no | stub: `unknown_fonoaapi_0a4d7d68` |
| TinCheck | SOAP | Legacy US TIN validation via `/v0/validations/tin_validation` | no | stub: `unknown_tincheckservice_6ebd1f52` |

### Salesforce Detail

- **Protocol**: REST (OAuth2 password grant)
- **Base URL / SDK**: Configured via `salesforceClient` and `salesforceAuthClient` in JTier YAML; client generated from `src/main/resources/swagger/client/force.yaml`
- **Auth**: OAuth2 username/password grant; credentials in `salesforceAuthConfig` (`username`, `password`, `client_id`, `client_secret`, `grant_type`)
- **Purpose**: Primary system of record for merchant accounts, opportunities, and contacts. The service reads and writes account data, tax status, payment hold fields, billing address, opportunity stage, and task records.
- **Failure mode**: If Salesforce is unavailable, API endpoints that depend on SF data return errors. No fallback cache is used for write paths.
- **Circuit breaker**: Not explicitly configured in source; RxJava 3 reactive error propagation handles timeouts.

### Adobe Sign Detail

- **Protocol**: REST (OAuth2 refresh token)
- **Base URL / SDK**: Configured via `adobesignClient` and `adobesignAuthClient`; generated from `src/main/resources/swagger/client/adobeClient.yaml`
- **Auth**: OAuth2 refresh-token grant; credentials in `adobeSignAuthConfig` (`client_id`, `client_secret`, `grant_type`, `refresh_token`)
- **Purpose**: Initiates and retrieves document signing agreements for merchant contract acceptance flows.
- **Failure mode**: Document upload and contract signing endpoints degrade; non-signing prep steps remain functional.
- **Circuit breaker**: Not explicitly configured.

### Fonoa Detail

- **Protocol**: REST
- **Base URL / SDK**: Configured via `fonoaClient`; generated from `src/main/resources/swagger/client/fonoa.yaml`
- **Auth**: Configured via the client configuration block.
- **Purpose**: Validates EU merchant TIN and VAT numbers during tax info submission.
- **Failure mode**: TIN validation step degrades; merchants may not be blocked if Fonoa is unavailable (depends on business logic).
- **Circuit breaker**: Not explicitly configured.

### TinCheck Detail

- **Protocol**: SOAP (via `jackson-dataformat-xml`)
- **Base URL / SDK**: Configured via `tinCheck` block (`url`, `userLogin`, `userPassword`) in JTier YAML
- **Auth**: Username/password in config
- **Purpose**: Legacy US TIN name-matching validation; exposed via `GET /v0/validations/tin_validation`.
- **Failure mode**: Legacy TIN validation endpoint returns an error; newer Fonoa path is unaffected.
- **Circuit breaker**: Not explicitly configured.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| M3 Merchant Service | REST | Retrieves merchant profile and account data | `continuumM3MerchantService` |
| NOTS Notification Service | REST | Sends merchant notifications (email, SMS) | `notsService` |
| Accounting Service | REST | Checks accounting data and payment hold status | `continuumAccountingService` |
| Contract Service | REST | Reads contract details for contract display | `continuumContractService` |
| MLS RIN Service | REST | Reads RIN-related account data | `continuumMlsRinService` |
| Reading Rainbow Cache | REST | Reads Salesforce-cached data | stub: `unknown_readingrainbowcache_b6b8ebd5` |
| Message Bus (MBUS) | JMS topic | Publishes merchant setting update events | `messageBus` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. The service exposes two subservice endpoints:
> - `mx-merchant-preparation::app_sox_c2` — SOX-scoped read/write access for internal services
> - `mx-merchant-preparation::app_c2` — read-only access for non-SOX services
> - `mx-merchant-preparation::app` — staging instances

## Dependency Health

- All Retrofit clients are configured with JTier `RxRetrofitConfiguration` which supports connection/read timeout settings per client.
- RxJava 3 error propagation surfaces upstream failures as HTTP 5xx responses to callers.
- No circuit breaker pattern (Hystrix, Resilience4j) is explicitly wired in source.
- Wavefront outgoing-request error-rate alerts fire if any downstream call error rate exceeds 2% (see [Runbook](runbook.md)).
