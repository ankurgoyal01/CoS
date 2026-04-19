---
service: "deal_wizard"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 1
internal_count: 2
---

# Integrations

## Overview

Deal Wizard has one critical external dependency (Salesforce) and two active internal Continuum dependencies (Deal Management API and Voucher Inventory Service). Two additional internal services (Deal Book Service and Deal Guide Service) are referenced in the architecture model as stubs, indicating planned or partially implemented integrations. All integrations are synchronous REST calls — no async messaging.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | REST / OAuth 2.0 / APEX | User authentication (OAuth) and system of record for Opportunities and Accounts | yes | `salesForce` |

### Salesforce Detail

- **Protocol**: REST (APEX API), OAuth 2.0
- **Base URL / SDK**: `omniauth-salesforce` 1.0.5 for OAuth; `databasedotcom` 1.3.2.gpn2 and `salesforce-buffet` 0.0.5 for API access
- **Auth**: OAuth 2.0 — sales users authenticate via Salesforce identity provider; API calls use the resulting access token
- **Purpose**: Salesforce is the deal wizard's primary source of truth for merchant Opportunities and Accounts. The wizard reads Opportunity data to pre-populate deal forms, and writes completed deal data back to Salesforce upon submission via `POST /api/v1/create_salesforce_deal`
- **Failure mode**: If Salesforce is unavailable, users cannot authenticate (OAuth blocked) and deal creation is fully blocked. Salesforce write failures are captured as error records visible in `/admin/salesforce_errors` and may be retried via `delayed_job`
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Management API | REST | Fetches deal UUIDs and looks up inventory products | `continuumDealManagementApi` |
| Voucher Inventory Service | REST | Updates inventory products and sets redemption windows | `continuumVoucherInventoryService` |
| Deal Book Service | REST (stub only) | Fetches Deal Book structures for pricing calculators | `dealBookService_7f1b` |
| Deal Guide Service | REST (stub only) | Fetches Deal Guide structures and wizard question templates | `dealGuideService_24d9` |

### Deal Management API Detail

- **Protocol**: REST via `service_discovery_client` 0.1.13
- **Base URL / SDK**: Resolved at runtime via Groupon service discovery
- **Auth**: Internal service-to-service (no evidence of specific auth mechanism)
- **Purpose**: The `dealManagementClient` component calls this API to resolve deal UUIDs used throughout the wizard flow and to retrieve current inventory product definitions for option configuration
- **Failure mode**: Missing deal UUIDs or inventory data will stall wizard progression; errors surface in UI
- **Circuit breaker**: No evidence found

### Voucher Inventory Service Detail

- **Protocol**: REST via `service_discovery_client` 0.1.13
- **Base URL / SDK**: Resolved at runtime via Groupon service discovery
- **Auth**: Internal service-to-service
- **Purpose**: Called during the deal inventory allocation step to update voucher inventory products and configure redemption windows for a deal
- **Failure mode**: Inventory allocation failures prevent deal completion; errors surfaced in wizard UI
- **Circuit breaker**: No evidence found

### Deal Book Service Detail

- **Protocol**: REST (stub only — target not in federated model)
- **Purpose**: Intended to provide Deal Book structures used by the pricing calculator wizard step; the `dealBookClient` component is defined but the downstream service is not currently available in the federated architecture model
- **Failure mode**: No evidence found

### Deal Guide Service Detail

- **Protocol**: REST (stub only — target not in federated model)
- **Purpose**: Intended to provide Deal Guide structures and wizard question templates via the `dealGuideClient` component; the downstream service is not currently available in the federated architecture model
- **Failure mode**: No evidence found

## Consumed By

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

Deal Wizard uses `newrelic_rpm` 3.7.1 for APM monitoring of dependency calls. The `/admin/salesforce_errors` endpoint provides operational visibility into Salesforce integration failures. No evidence found for explicit circuit breakers or retry policies beyond `delayed_job` background retries for failed Salesforce write operations.
