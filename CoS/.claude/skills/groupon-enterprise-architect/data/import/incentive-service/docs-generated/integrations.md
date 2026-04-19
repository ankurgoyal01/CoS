---
service: "incentive-service"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 6
internal_count: 6
---

# Integrations

## Overview

The Incentive Service integrates with 6 internal Continuum platform services and 6 external or stub-only dependencies. Internal integrations use REST/HTTP via typed Play WS clients managed by the `incentiveExternalClients` component. Messaging integrations (Kafka and MBus) are managed by the `incentiveMessaging` component. Six additional dependencies are modelled as stubs in the architecture because they are not yet part of the federated model.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google Cloud Bigtable | SDK | High-throughput audience data reads during qualification sweeps | yes | `extBigtableInstance_0f21` (stub) |
| Realtime Audience Service (RTAMS) | REST | Realtime audience qualification (feature-flagged) | no | `extRealtimeAudienceService_6bf1` (stub) |
| RAAS | Kafka | Campaign state change signals from upstream campaign platform | no | `extRaas_276f` (stub) |
| Email Campaign Management | REST | Email automation coordination for campaign activation | no | `extEmailCampaignManagement_8a72` (stub) |
| Rocketman Commercial EDS | REST | Destination and campaign metadata | no | `extRocketmanCommercialEds_3de0` (stub) |
| DAAS Postgres | JDBC/PostgreSQL | Shared reporting dataset | no | `extDaasPostgres_bf75` (stub) |

### Google Cloud Bigtable Detail

- **Protocol**: Google Cloud Bigtable Java SDK
- **Base URL / SDK**: `google-cloud-bigtable` 2.x; project and instance configured via `BIGTABLE_PROJECT_ID` and `BIGTABLE_INSTANCE_ID`
- **Auth**: Application Default Credentials / service account
- **Purpose**: Provides high-throughput reads of user audience membership data consumed during batch audience qualification sweeps
- **Failure mode**: Qualification sweeps degrade; falls back to MBus user population events where available
- **Circuit breaker**: > No evidence found in codebase.

### Realtime Audience Service Detail

- **Protocol**: REST
- **Base URL / SDK**: > No evidence found in codebase.
- **Auth**: > No evidence found in codebase.
- **Purpose**: Provides realtime audience qualification results; enabled by feature flag `incentive.realtimeAudience`
- **Failure mode**: Falls back to batch qualification; feature flag disables integration on failure
- **Circuit breaker**: > No evidence found in codebase.

### RAAS Detail

- **Protocol**: Kafka
- **Base URL / SDK**: Consumed via `continuumKafkaBroker`
- **Auth**: Kafka broker credentials
- **Purpose**: Delivers `campaign.state_change` events to trigger incentive state synchronisation with the upstream campaign platform
- **Failure mode**: Incentive state may lag behind campaign state; no immediate checkout impact
- **Circuit breaker**: > No evidence found in codebase.

### Email Campaign Management Detail

- **Protocol**: REST
- **Base URL / SDK**: > No evidence found in codebase.
- **Auth**: > No evidence found in codebase.
- **Purpose**: Coordinates email automation activation when campaigns transition to active state
- **Failure mode**: Email campaigns may not activate; does not affect incentive validation or redemption
- **Circuit breaker**: > No evidence found in codebase.

### Rocketman Commercial EDS Detail

- **Protocol**: REST
- **Base URL / SDK**: > No evidence found in codebase.
- **Auth**: > No evidence found in codebase.
- **Purpose**: Provides destination and campaign metadata for incentive targeting and filtering
- **Failure mode**: Degraded targeting accuracy; does not affect core validation flow
- **Circuit breaker**: > No evidence found in codebase.

### DAAS Postgres Detail

- **Protocol**: JDBC/PostgreSQL
- **Base URL / SDK**: > No evidence found in codebase.
- **Auth**: Database credentials
- **Purpose**: Shared reporting dataset; incentive and redemption data exported for analytics
- **Failure mode**: Reporting data becomes stale; no impact on operational flows
- **Circuit breaker**: Not applicable (batch/export context only)

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Audience Management Service | REST | Audience management APIs for qualification configuration | `continuumAudienceManagementService` |
| Taxonomy Service | REST | Taxonomy data for campaign targeting and product filtering | `continuumTaxonomyService` |
| Pricing Service | REST | Pricing context for incentive eligibility validation | `continuumPricingService` |
| Deal Catalog Service | REST | Deal and product details for incentive scope resolution | `continuumDealCatalogService` |
| Marketing Deal Service | REST | MDS deal and product set loading for audience and campaign rules | `continuumMarketingDealService` |
| Messaging Service | REST | Creates and updates messaging campaigns on approval and qualification | `continuumMessagingService` |
| Kafka Broker | Kafka | Event stream backbone for `incentive.redeemed` and `audience.qualified` | `continuumKafkaBroker` |
| Message Bus | MBus/STOMP | Order confirmation and user population update events | `messageBus` |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Known consumers based on API surface:
- Checkout systems — call `GET /incentives/validate` and `POST /incentives/redeem` during purchase flow
- Campaign management tools / admin users — access admin UI endpoints
- Bulk data consumers — call `POST /bulk-export/start` for reporting exports

## Dependency Health

> No evidence found in codebase for specific circuit breaker or health check implementations per dependency. The service exposes `GET /health` for its own readiness and liveness probe, which Kubernetes uses to gate traffic. Individual dependency failures are expected to degrade specific flows (e.g., pricing service unavailability blocks validation eligibility checks) rather than cause full service outage.
