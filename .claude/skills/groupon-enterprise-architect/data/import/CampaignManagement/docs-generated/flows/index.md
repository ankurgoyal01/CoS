---
service: "email_campaign_management"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for CampaignManagement.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Campaign Creation and Publish](campaign-creation-publish.md) | synchronous | API call — `POST /campaigns` | Creates a new campaign, persists it to PostgreSQL, registers an Expy experiment if applicable, and prepares the campaign for send scheduling |
| [Audience Targeting and Deal Query](audience-targeting-deal-query.md) | synchronous | API call — `POST /dealqueries` or `PUT /dealqueries/:id` | Creates or updates deal query targeting rules, resolves division metadata from GeoPlaces, and caches resolved metadata in Redis |
| [Campaign Send Execution](campaign-send-execution.md) | synchronous | API call — `POST /campaignsends` | Executes a campaign send: validates via preflight, downloads deal assignment files from GCS, resolves audience via RTAMS, retrieves device tokens, and records the send |
| [Campaign Update and Treatment Rollout](campaign-update-rollout.md) | synchronous | API call — `PUT /campaigns/:id` or `POST /campaigns/:id/rolloutTemplateTreatment` | Updates campaign metadata or rolls out an A/B treatment variant by updating the campaign template and registering the variant in Expy |
| [Campaign Archival and Audit](campaign-archival-audit.md) | synchronous | API call — `DELETE /campaigns/:id` or `DELETE /programs/:id` | Archives a campaign or program, updates status in PostgreSQL, and archives the associated Expy experiment |
| [Program Management](program-management.md) | synchronous | API call — `POST /programs`, `PUT /programs/:id` | Creates or updates a program, manages priority ordering, resolves GConfig runtime configuration, and persists program state |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 6 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All flows in CampaignManagement are synchronous REST flows. The following flows span multiple services and reference external architecture containers:

- **Campaign Send Execution** spans `continuumCampaignManagementService`, `rocketmanMessagingService`, `rtamsAudienceService`, `tokenService`, `googleCloudStorage`, and `continuumCampaignManagementPostgres`. See [Campaign Send Execution](campaign-send-execution.md).
- **Campaign Creation and Publish** spans `continuumCampaignManagementService`, `expyExperimentationService`, and `continuumCampaignManagementPostgres`. See [Campaign Creation and Publish](campaign-creation-publish.md).
- **Audience Targeting and Deal Query** spans `continuumCampaignManagementService`, `continuumGeoPlacesService`, and `continuumCampaignManagementRedis`. See [Audience Targeting and Deal Query](audience-targeting-deal-query.md).

> Dynamic view `CampaignSendResolutionFlow` was omitted from the architecture DSL because most participants (RTAMS, Token Service, Campaign API Clients) are stub-only and do not resolve in the federated workspace.
