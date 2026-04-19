---
service: "metro-draft-service"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 3
internal_count: 27
---

# Integrations

## Overview

Metro Draft Service integrates with 30+ services. The majority are internal Continuum services called via HTTP/Retrofit with RxJava3 for async execution. Three external SaaS integrations exist: Salesforce (deal scores and contracts), ElasticSearch (search indexing), and Slack (operational notifications). All integration clients are grouped into cohesive client components within `continuumMetroDraftService`.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | HTTP (SOAP client) | Syncs deal scores, contracts, and documents | yes | `salesForce` |
| ElasticSearch | HTTP | Indexes deals for search and querying | yes | `elasticSearch` |
| Slack | HTTP (webhook) | Sends operational notifications to Metro team channels | no | `slack` |

### Salesforce Detail

- **Protocol**: HTTP via Salesforce SOAP client
- **Base URL / SDK**: Salesforce SOAP client library (inventory: Salesforce SOAP client)
- **Auth**: Salesforce API credentials (managed as secrets)
- **Purpose**: Deal Score to Salesforce Job writes computed deal scores; Deal Service syncs contracts and documents
- **Failure mode**: Scoring sync failures do not block deal publishing; document sync errors may require retry
- **Circuit breaker**: No evidence found

### ElasticSearch Detail

- **Protocol**: HTTP
- **Base URL / SDK**: Search & Analytics Client (`continuumMetroDraftService_searchAnalyticsClient`)
- **Auth**: No evidence of explicit auth mechanism in architecture model
- **Purpose**: Deal Score Calculator Job and Deal Service push scoring and search signals; enables deal search within Metro tooling
- **Failure mode**: Search indexing failures are non-blocking for deal publishing flow
- **Circuit breaker**: No evidence found

### Slack Detail

- **Protocol**: HTTP webhook
- **Base URL / SDK**: Messaging & Notifications Client (`continuumMetroDraftService_messagingNotificationsClient`)
- **Auth**: Webhook URL (managed as secret)
- **Purpose**: Sends operational notifications for pending items, stuck deals, and status events to Metro team
- **Failure mode**: Non-critical; notification failures do not affect deal lifecycle
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Management Service (DMAPI) | HTTP/Retrofit | Creates and updates deals in pipeline workflow | `continuumDealManagementService` |
| Marketing Deal Service (MDS) | HTTP/Retrofit | Syncs merchandising deals and pricing | `continuumMarketingDealService` |
| Deal Catalog Service | HTTP/Retrofit | Validates and publishes deals to catalog | `continuumDealCatalogService` |
| Place Read Service | HTTP/Retrofit | Reads merchant place data | `continuumPlaceReadService` |
| Place Write Service | HTTP/Retrofit | Writes merchant place updates | `continuumPlaceWriteService` |
| Voucher Inventory Service (VIS) | HTTP/Retrofit | Manages voucher inventory and reservations | `continuumVoucherInventoryService` |
| Redemption Code Pool Service | HTTP/Retrofit | Allocates redemption code pools | `continuumRedemptionCodePoolService` |
| RBAC Service | HTTP/Retrofit | Performs role and permission checks | `continuumRbacService` |
| M3 Merchant Service | HTTP/Retrofit | Reads merchant master data | `continuumM3MerchantService` |
| Users Service | HTTP/Retrofit | Resolves user accounts | `continuumUsersService` |
| Taxonomy Service | HTTP/Retrofit | Retrieves taxonomy metadata | `continuumTaxonomyService` |
| GeoPlaces Service | HTTP/Retrofit | Enriches places with geo metadata | `continuumGeoPlacesService` |
| GeoDetails Service | HTTP/Retrofit | Fetches geo details for merchants | `continuumGeoDetailsService` |
| Infer PDS Service | HTTP/Retrofit | Requests dynamic pricing recommendations | `continuumInferPdsService` |
| Rainbow Service | HTTP/Retrofit | Reads experimentation flags | `continuumRainbowService` |
| GenAI Service | HTTP/Retrofit | Generates AI-assisted deal content | `continuumGenAIService` |
| Partner Service | HTTP/Retrofit | Sends partner onboarding and workflow events | `continuumPartnerService` |
| ePODS Service | HTTP/Retrofit | Exchanges proof-of-delivery data | `continuumEpodsService` |
| GIMS | HTTP/Retrofit | Uploads images and videos via signed URLs | `gims` |
| NOTS Service | HTTP/Retrofit | Sends messaging and email notifications | `notsService` |
| MAS Service | HTTP/Retrofit | Reads merchant account contacts | `continuumMasService` |
| Image Service | HTTP/Retrofit | Uploads deal images | `continuumImageService` |
| Video Service | HTTP/Retrofit | Uploads deal videos | `continuumVideoService` |
| BIS Images Service | HTTP/Retrofit | Retrieves BIS content images | `continuumBisImagesService` |
| CFS Service | HTTP/Retrofit | Retrieves generated copy/content | `continuumCfsService` |
| Merchant Self Service | HTTP/Retrofit | Handles merchant self-service flows | `continuumMerchantSelfService` |
| Merchant Case Service | HTTP/Retrofit | Opens and updates merchant cases | `continuumMerchantCaseService` |
| Dealbook Service | HTTP/Retrofit | Reads dealbook data | `continuumDealbookService` |
| Contract Service | HTTP/Retrofit | Manages contract lifecycle | `continuumContractService` |
| AIDG Service | HTTP/Retrofit | Resolves identity graph information | `continuumAidgService` |
| UMAPI Service | HTTP/Retrofit | Reads user/merchant contacts | `continuumUmapiService` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. Metro Draft Service is consumed by Metro internal tooling, merchant self-service portals, and partner onboarding orchestration layers calling via HTTP REST.

## Dependency Health

- All HTTP/Retrofit integrations use RxJava3 for async, non-blocking calls.
- No explicit circuit breaker configuration is evidenced in the architecture model.
- Observability integrations are present: `loggingStack` (structured logs), `metricsStack` (service metrics), `tracingStack` (distributed traces via OTel) — these enable dependency health monitoring.
- Confirm retry and timeout policies with the Metro Team (metro-dev-blr@groupon.com).
