---
service: "gazebo"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 2
internal_count: 5
---

# Integrations

## Overview

Gazebo integrates with two external third-party systems (Salesforce CRM and Bynder) and five internal Groupon platform services or stubs (Users Service, Deal Catalog Service, DMAPI, GPAPI, and the Message Bus). External integrations use dedicated SDK clients (Restforce for Salesforce, Typhoeus-based REST for Bynder). Internal service calls use REST over HTTP. Message Bus integration uses the Messagebus gem for both publish and consume.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce CRM | sdk (Restforce) | Read and update CRM opportunity and deal data for editorial context | yes | `salesForce` |
| Bynder | rest | Manage and sync media assets (images, brand assets) for deal copy | no | `continuumBynderIntegrationService` |

### Salesforce CRM Detail

- **Protocol**: Restforce SDK (Ruby gem, pinned version)
- **Base URL / SDK**: Restforce gem — connects via configured Salesforce OAuth credentials
- **Auth**: OAuth 2.0 client credentials via `SALESFORCE_CLIENT_ID` and `SALESFORCE_CLIENT_SECRET`
- **Purpose**: Reads CRM opportunity and deal data to provide editorial context; updates CRM records when editorial actions are taken; a scheduled cron job performs bulk sync of CRM data into MySQL
- **Failure mode**: Scheduled sync fails silently until next run; real-time reads may degrade editorial context views if Salesforce is unavailable
- **Circuit breaker**: No evidence found

### Bynder Detail

- **Protocol**: REST over HTTP via Typhoeus gem
- **Base URL / SDK**: Bynder integration service endpoint (via `continuumBynderIntegrationService` stub)
- **Auth**: No evidence found in inventory
- **Purpose**: Manages media asset selection and assignment for deal copy; syncs asset metadata into Gazebo's local data context
- **Failure mode**: Media asset lookups degrade gracefully; deal copy can be saved without media assets
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Users Service | rest | Fetch editorial staff user profiles and role information | `continuumUsersService` |
| Deal Catalog Service | rest | Fetch deal metadata and catalog data for editorial context | `continuumDealCatalogService` |
| Message Bus | mbus (Messagebus 0.2.8) | Publish copy change events; consume deal, task, and notification events | `mbusSystem_18ea34` |
| DMAPI | rest | Deal management API calls (exact usage is a stub; details managed in central model) | `dmapiSystem_44f3e5` |
| GPAPI | rest | Platform API calls (exact usage is a stub; details managed in central model) | `gpapiSystem_547253` |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

> No evidence found in codebase. No circuit breaker, retry policy, or health check configuration for external dependencies was discoverable from the inventory. Typhoeus (v0.6.5) supports configurable timeouts and retries at the call site; whether these are configured for Gazebo's integrations is not confirmed.
