---
service: "message-service"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 4
internal_count: 7
---

# Integrations

## Overview

The CRM Message Service integrates with seven internal Continuum services and four external/platform-level systems. Internal integrations provide enrichment data (taxonomy, geo, email metadata, audience validation) and delivery infrastructure (MBus event bus, EDW analytics). External integrations cover image asset storage (GIMS), raw audience export file storage (GCP Storage/HDFS), and additional enrichment services (Incentive, Localization, Finch/Optimizely). All outbound calls are routed through the `messagingIntegrationClients` component.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GIMS (Groupon Image Management) | REST | Upload and resolve campaign image assets | yes | `gims` |
| GCP Storage / HDFS | GCP SDK / HDFS client | Download audience export files for batch audience import jobs | yes | — |
| EDW (Enterprise Data Warehouse) | MBus | Receive campaign metadata for analytics | no | `edw` |
| Finch / Optimizely | REST/SDK | Load experimentation configuration for message targeting | no | — |

### GIMS Detail

- **Protocol**: REST
- **Base URL / SDK**: GIMS service endpoint (not documented in architecture inventory)
- **Auth**: Internal service credentials
- **Purpose**: Campaign managers upload banner and notification images; the service resolves image asset URLs during campaign creation and delivery
- **Failure mode**: Campaign image assets may not resolve; creation may fail or fall back to default images
- **Circuit breaker**: No evidence found

### GCP Storage / HDFS Detail

- **Protocol**: GCP Storage SDK / HDFS client
- **Base URL / SDK**: Configured bucket/path (not documented in architecture inventory)
- **Auth**: GCP service account / Hadoop credentials
- **Purpose**: `messagingAudienceImportJobs` download audience export files produced by AMS and stored in GCP Storage or HDFS to build user-campaign assignments
- **Failure mode**: Audience assignment import fails; existing assignments remain stale until the next successful refresh
- **Circuit breaker**: No evidence found

### EDW Detail

- **Protocol**: MBus
- **Base URL / SDK**: Via `messageBus` stub
- **Auth**: Internal MBus credentials
- **Purpose**: `messagingEventPublishers` emits campaign metadata to EDW for analytics and reporting pipelines
- **Failure mode**: Analytics data may lag; no impact on real-time message delivery
- **Circuit breaker**: No evidence found

### Finch / Optimizely Detail

- **Protocol**: REST / SDK
- **Base URL / SDK**: Not documented in architecture inventory (stub comment in relations.dsl)
- **Auth**: Internal service credentials
- **Purpose**: Loads experimentation configuration used in message targeting and constraint evaluation
- **Failure mode**: Experiments may default to control group; no direct delivery failure
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| AMS (Audience Management Service) | REST | Validates audiences and fetches audience exports/attributes | `continuumAudienceManagementService` |
| Taxonomy Service | REST | Retrieves taxonomy references for targeting constraints | `continuumTaxonomyService` |
| Geo Service | REST | Retrieves geo and division metadata for location-based targeting | `continuumGeoService` |
| Email Campaign Management | REST | Retrieves email campaign and business-group metadata for email channel delivery | `continuumEmailService` |
| MBus | MBus protocol | Publishes `CampaignMetaData` events; consumes `ScheduledAudienceRefreshed` events | `messageBus` |
| Incentive Service | REST | Requests best-for incentives for message targeting (not in current federated model) | — |
| Localization Service | REST | Resolves localized content for messages (not in current federated model) | — |

### AMS (Audience Management Service) Detail

- **Protocol**: REST
- **Auth**: Internal service credentials
- **Purpose**: Campaign Orchestration calls AMS to validate that audience definitions exist and are usable; Audience Import Jobs call AMS to download audience export metadata before pulling files from storage
- **Failure mode**: Campaign creation or audience assignment may fail; degraded targeting accuracy
- **Circuit breaker**: No evidence found

### Taxonomy Service Detail

- **Protocol**: REST
- **Auth**: Internal service credentials
- **Purpose**: Provides taxonomy category references used by Campaign Orchestration to enforce targeting constraints (e.g., category-based message eligibility)
- **Failure mode**: Targeting constraint evaluation may fall back to less specific rules
- **Circuit breaker**: No evidence found

### Geo Service Detail

- **Protocol**: REST
- **Auth**: Internal service credentials
- **Purpose**: Provides geo-zone and division metadata used to scope messages to specific geographies
- **Failure mode**: Geo-targeted messages may not be delivered correctly
- **Circuit breaker**: No evidence found

### Email Campaign Management Detail

- **Protocol**: REST
- **Auth**: Internal service credentials
- **Purpose**: Supplies email campaign and business-group metadata used by the Message Delivery Engine to populate the email channel response from `/api/getemailmessages`
- **Failure mode**: Email channel responses may be incomplete or empty
- **Circuit breaker**: No evidence found

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Known consumers based on API surface:
- Web and mobile frontends consume `/api/getmessages`
- Email pipeline consumes `/api/getemailmessages`
- Campaign managers use the `/campaign/*` UI

## Dependency Health

> Operational health check and circuit breaker configurations for dependencies are not documented in the architecture inventory. Operational procedures to be defined by service owner.
