---
service: "partner-service"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 3
internal_count: 5
---

# Integrations

## Overview

Partner Service integrates with 3 external systems (Salesforce, AWS S3, Google Sheets) and 5 internal Continuum services. All outbound HTTP calls use Retrofit clients managed by `jtier-retrofit`. Asynchronous integration events flow through MBus. Two additional external integrations (Jira Cloud, PagerDuty) are noted in the DSL comments as not yet federated into the model.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | HTTPS/REST | Synchronizes partner account and opportunity events | yes | `salesForce` |
| AWS S3 | HTTPS/SDK | Uploads partner documentation and universal partner artifacts | no | — |
| Google Sheets | HTTPS/REST | Partner data import/export for onboarding operations | no | — |

### Salesforce Detail

- **Protocol**: HTTPS/REST
- **Base URL / SDK**: Salesforce REST API; client managed by `partnerSvc_integrationClients`
- **Auth**: Salesforce OAuth / API credentials (managed via secrets)
- **Purpose**: Synchronizes partner account records and opportunity lifecycle events between Groupon and Salesforce CRM during onboarding and ongoing management
- **Failure mode**: Onboarding workflows that depend on Salesforce state will fail or degrade; retries are expected via MBus-driven workflow retry logic
- **Circuit breaker**: No evidence found

### AWS S3 Detail

- **Protocol**: HTTPS via AWS SDK 1.12.259
- **Base URL / SDK**: AWS SDK v1; two bucket targets noted in DSL comments (document bucket, universal artifact bucket)
- **Auth**: AWS IAM credentials (managed via secrets)
- **Purpose**: Uploads partner documentation and universal partner artifacts as part of onboarding and operational workflows
- **Failure mode**: Document upload steps fail; non-blocking for core mapping operations
- **Circuit breaker**: No evidence found

### Google Sheets Detail

- **Protocol**: HTTPS/REST (Google Sheets API)
- **Base URL / SDK**: Google Sheets API; client managed by `partnerSvc_integrationClients`
- **Auth**: Google service account credentials (managed via secrets)
- **Purpose**: Reads partner data from operator-maintained Google Sheets during onboarding ingestion
- **Failure mode**: Ingestion steps sourcing data from Sheets will fail; fallback to direct API input
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Catalog Service | HTTP/JSON | Reads and updates deal catalog entities during mapping and reconciliation | `continuumDealCatalogService` |
| Deal Management API | HTTP/JSON | Manages merchant and deal lifecycle operations during onboarding | `continuumDealManagementApi` |
| ePOS Service (ePods) | HTTP/JSON | Synchronizes partner merchant and inventory data | `continuumEpodsService` |
| Geo Places Service | HTTP/JSON | Retrieves geographic division and place metadata for product-place mapping | `continuumGeoPlacesService` |
| Users Service | HTTP/JSON | Retrieves user and contact information for partner records | `continuumUsersService` |
| MBus | JMS/STOMP | Publishes and consumes partner workflow events | `messageBus` |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

- All outbound HTTP clients use `jtier-retrofit`, which provides JTier-standard connection pooling and timeout configuration
- No explicit circuit-breaker or bulkhead configuration was identified in the inventory
- MBus connectivity is managed by `jtier-messagebus-client` with JTier-standard reconnect behavior
- Failure modes for critical dependencies (Salesforce, Deal Catalog, Deal Management API) will surface as workflow errors visible in the audit log
