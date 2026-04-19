---
service: "email_campaign_management"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 7
internal_count: 1
---

# Integrations

## Overview

CampaignManagement integrates with eight downstream systems: one internal Continuum service (`continuumGeoPlacesService`) and seven external or stub-mapped services (Rocketman, RTAMS, Token Service, GConfig, Expy, Google Cloud Storage, HDFS). All integrations are synchronous REST/HTTPS calls made at request time by `cmIntegrationClients`. No circuit breakers are explicitly documented in the architecture inventory; failure behavior is service-specific.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Rocketman | REST/HTTPS | Sends preflight email/push payloads for campaign send validation | yes | `rocketmanMessagingService` (stub) |
| RTAMS (Audience Service) | REST/HTTPS | Fetches audience memberships and user attributes for targeting | yes | `rtamsAudienceService` (stub) |
| Token Service | REST/HTTPS | Retrieves user device token preferences for push targeting | yes | `tokenService` (stub) |
| GConfig | REST/HTTPS | Resolves runtime campaign configuration values | yes | `gconfigService` (stub) |
| Expy (Experimentation) | REST/HTTPS + SDK | Creates, updates, and archives A/B experiments tied to campaign treatments | no | `expyExperimentationService` (stub) |
| Google Cloud Storage | GCS API | Downloads deal assignment files for audience/deal resolution | yes | `googleCloudStorage` (stub) |
| HDFS | WebHDFS REST | Archives deal assignment files from GCS to HDFS | no | — |

### Rocketman Detail

- **Protocol**: REST/HTTPS
- **Base URL / SDK**: Internal Groupon messaging delivery service
- **Auth**: Internal service auth (details managed externally)
- **Purpose**: Validates campaign send payloads via preflight dry-run before committing a campaign send; also acts as the downstream delivery executor for actual sends
- **Failure mode**: Preflight endpoint returns error; campaign send blocked from proceeding
- **Circuit breaker**: No evidence found

### RTAMS (Audience Service) Detail

- **Protocol**: REST/HTTPS
- **Base URL / SDK**: Internal Groupon audience/segmentation service
- **Auth**: Internal service auth (details managed externally)
- **Purpose**: Evaluates audience membership and returns user attributes needed to resolve who receives a given campaign send
- **Failure mode**: Audience resolution fails; campaign send cannot proceed
- **Circuit breaker**: No evidence found

### Token Service Detail

- **Protocol**: REST/HTTPS
- **Base URL / SDK**: Internal Groupon token/device preference service
- **Auth**: Internal service auth (details managed externally)
- **Purpose**: Retrieves user device token preferences to determine push notification eligibility for a campaign send
- **Failure mode**: Push targeting falls back or is skipped for affected users
- **Circuit breaker**: No evidence found

### GConfig Detail

- **Protocol**: REST/HTTPS
- **Base URL / SDK**: Internal Groupon runtime configuration service
- **Auth**: Internal service auth (details managed externally)
- **Purpose**: Resolves runtime campaign configuration values at request time (e.g., feature toggles, send limits, rate parameters)
- **Failure mode**: Defaults applied or request fails depending on criticality of config value
- **Circuit breaker**: No evidence found

### Expy (Experimentation) Detail

- **Protocol**: REST/HTTPS + `@grpn/expy.js` SDK (v1.1.2)
- **Base URL / SDK**: `@grpn/expy.js` 1.1.2
- **Auth**: SDK-managed internal auth
- **Purpose**: Creates, updates, and archives A/B experiments when campaign treatments are rolled out via `/campaigns/:id/rolloutTemplateTreatment`
- **Failure mode**: Experiment registration fails; treatment rollout may be blocked
- **Circuit breaker**: No evidence found

### Google Cloud Storage Detail

- **Protocol**: GCS API (HTTPS)
- **Base URL / SDK**: Google Cloud Storage REST API
- **Auth**: GCS service account credentials (managed externally)
- **Purpose**: Downloads deal assignment files that map deals to eligible audience segments for campaign send execution
- **Failure mode**: Deal assignment unavailable; campaign send execution blocked
- **Circuit breaker**: No evidence found

### HDFS Detail

- **Protocol**: WebHDFS REST (`webhdfs` 1.1.1)
- **Base URL / SDK**: `webhdfs` 1.1.1
- **Auth**: Hadoop cluster credentials (managed externally)
- **Purpose**: Archives deal assignment files from GCS to HDFS for durable storage and downstream data pipeline access
- **Failure mode**: Archival skipped or retried; not blocking for campaign send
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| GeoPlaces | REST/HTTPS | Loads division and geographic metadata for deal query resolution and campaign targeting | `continuumGeoPlacesService` |

### GeoPlaces Detail

- **Protocol**: REST/HTTPS
- **Architecture ref**: `continuumGeoPlacesService` (federated in workspace)
- **Purpose**: Provides division metadata (geographic market definitions) used when constructing and resolving deal queries for audience targeting
- **Failure mode**: Division metadata unavailable; deal query construction or resolution may fail
- **Circuit breaker**: No evidence found

## Consumed By

> Upstream consumers are tracked in the central architecture model. Internal campaign orchestrators and campaign API clients call this service over HTTPS/JSON. The `campaignApiClients` identifier is stub-only in the federated workspace.

## Dependency Health

The `/heartbeat` endpoint provides a liveness check for the service itself. Dependency health checks for PostgreSQL and Redis are performed at startup and likely on each request via connection pool management (`pg` 8.7.1, `redis` 2.4.2). Explicit retry and circuit breaker configuration for external HTTP dependencies (Rocketman, RTAMS, etc.) is not documented in the architecture inventory — operational procedures should be defined by the service owner.
