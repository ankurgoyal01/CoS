---
service: "metro-draft-service"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers:
    - continuumMetroDraftService
    - continuumMetroDraftDb
    - continuumMetroDraftMcmPostgres
    - continuumCovidSafetyProgramPostgres
    - continuumMetroDraftRedis
    - continuumMetroDraftMessageBus
---

# Architecture Context

## System Context

Metro Draft Service sits within the **Continuum** platform as the central deal authoring and publishing orchestrator. It is called by Metro internal tooling, merchant self-service portals, and partner onboarding flows. It drives deal data into the Groupon commerce pipeline by coordinating with the Deal Management Service (DMAPI), Marketing Deal Service (MDS), and Deal Catalog. The service owns its own PostgreSQL databases (deal drafts, MCM, Covid Safety Program), a Redis cache, and an MBus message bus. It integrates with 30+ Continuum services and external SaaS platforms (Salesforce, ElasticSearch, Slack).

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| Metro Draft Service | `continuumMetroDraftService` | Backend | Java 11, Dropwizard, HK2, RxJava3 | Core application server handling REST APIs, business logic, and integration orchestration |
| Metro Draft DB | `continuumMetroDraftDb` | Database | PostgreSQL | Primary store for draft deals, merchants, audit logs, and documents |
| MCM Postgres | `continuumMetroDraftMcmPostgres` | Database | PostgreSQL | Merchandising change management schema and audit data |
| Covid Safety Program Postgres | `continuumCovidSafetyProgramPostgres` | Database | PostgreSQL | Covid safety program specific deal data and migrations |
| Metro Draft Redis | `continuumMetroDraftRedis` | Cache | Redis | Caching for permissions, feature flags, and draft deal data |
| Metro Draft Message Bus | `continuumMetroDraftMessageBus` | Messaging | MBus | Topics and subscriptions for deal events, signed deal notifications, and recommendation signals |

## Components by Container

### Metro Draft Service (`continuumMetroDraftService`)

#### API Layer

| Component | ID | Responsibility | Technology |
|-----------|-----|---------------|-----------|
| Deals Resource | `continuumMetroDraftService_dealsResource` | REST API for draft deal creation, update, cloning, and eligibility checks | JAX-RS, HK2, RxJava3 |
| Publish Resource | `continuumMetroDraftService_publishResource` | Endpoints orchestrating publishing and status transitions for deals | JAX-RS |
| MCM Resource | `continuumMetroDraftService_mcmResource` | Merchandising change management endpoints for change logs and approvals | JAX-RS |
| Merchants Resource | `continuumMetroDraftService_merchantsResource` | Merchant-centric APIs for onboarding, validation, and configuration checks | JAX-RS |
| Products Resource | `continuumMetroDraftService_productsResource` | Product and option management APIs including fine print and pricing steps | JAX-RS |
| Recommendation Resource | `continuumMetroDraftService_recommendationResource` | Endpoints exposing structure and recommendation data for deals | JAX-RS |
| Survey Resource | `continuumMetroDraftService_surveyResource` | Survey and questionnaire APIs used in drafting flows | JAX-RS |
| Code Pool Resource | `continuumMetroDraftService_codePoolResource` | APIs for redemption code pool lookups and availability checks | JAX-RS |
| File Upload Resource | `continuumMetroDraftService_fileUploadResource` | Endpoints for uploading and persisting documents and images | JAX-RS, MultiPart |
| Vetting Flow Resource | `continuumMetroDraftService_vettingFlowResource` | APIs managing vetting, validation, and checker flows for deals | JAX-RS |
| Places Resource | `continuumMetroDraftService_placesResource` | Place lookup and enrichment APIs for merchant locations | JAX-RS |
| Redemption Resource | `continuumMetroDraftService_redemptionResource` | Redemption configuration APIs for voucher delivery and redemption rules | JAX-RS |

#### Service Layer

| Component | ID | Responsibility | Technology |
|-----------|-----|---------------|-----------|
| Deal Service | `continuumMetroDraftService_dealService` | Core business logic for drafting, cloning, validating, and persisting deals | Java, RxJava3 |
| Deal Orchestration Service | `continuumMetroDraftService_dealOrchestrationService` | Coordinates publishing, workflow steps, and external service hand-offs | Java |
| Deal Status Service | `continuumMetroDraftService_dealStatusService` | Manages draft status transitions, eligibility checks, and state validations | Java |
| Merchandising Deal Service | `continuumMetroDraftService_merchandisingDealService` | Handles merchandising-specific deal creation and updates | Java |
| GLIVE Deal Service | `continuumMetroDraftService_gliveDealService` | Live deal specific flows and validations | Java |
| Dynamic PDS Service | `continuumMetroDraftService_dynamicPdsService` | Dynamic PDS defaults, fine print generation, and pricing helpers | Java |
| History Event Service | `continuumMetroDraftService_historyEventService` | Builds and publishes history/audit events for deal lifecycle | Java |
| Header Backup Service | `continuumMetroDraftService_headerBackupService` | Resolves feature country and headers used in downstream calls and audits | Java |
| MCM Service Helper | `continuumMetroDraftService_mcmServiceHelper` | Support utilities for merchandising change management flows and audit logs | Java |
| Merchants Service | `continuumMetroDraftService_merchantsService` | Merchant onboarding, permission, and metadata helpers | Java |
| Places Service | `continuumMetroDraftService_placesService` | Place enrichment and routing to place APIs | Java |
| Recommendation Service | `continuumMetroDraftService_recommendationService` | Structure recommendation orchestration and scoring | Java |
| Redemption Service | `continuumMetroDraftService_redemptionService` | Redemption rule processing and integration with inventory systems | Java |
| Deal Incentive Service | `continuumMetroDraftService_dealIncentiveService` | Clones and synchronizes deal incentive data during updates | Java |
| Permission Filter | `continuumMetroDraftService_permissionFilter` | Request filter enforcing permissions and RBAC integration | Jersey Filter |

#### Repository Layer

| Component | ID | Responsibility | Technology |
|-----------|-----|---------------|-----------|
| Deal DAO | `continuumMetroDraftService_dealDao` | JDBI mappers and queries for deals, drafts, and related entities | JDBI, SQL |
| Merchant DAO | `continuumMetroDraftService_merchantDao` | JDBI access for merchant data and associations | JDBI, SQL |
| Deal Status DAO | `continuumMetroDraftService_dealStatusDao` | Persists and queries deal statuses and workflow markers | JDBI, SQL |
| Document Data DAO | `continuumMetroDraftService_documentDataDao` | Stores and retrieves document metadata and upload references | JDBI, SQL |
| History DAO | `continuumMetroDraftService_historyDao` | Audit/history persistence and retrieval | JDBI, SQL |
| MCM Change DAO | `continuumMetroDraftService_mcmChangeDao` | Change management tables for merchandising audit and approvals | JDBI, SQL |
| PDS Config DAO | `continuumMetroDraftService_pdsConfigDao` | Persists PDS defaults and configuration metadata | JDBI, SQL |
| Metadata Store DAO | `continuumMetroDraftService_metadataStoreDao` | System configuration and metadata storage | JDBI, SQL |
| Quartz DAO | `continuumMetroDraftService_quartzDao` | Quartz scheduling metadata for jobs | JDBI, SQL |

#### Integration Layer

| Component | ID | Responsibility | Technology |
|-----------|-----|---------------|-----------|
| Deal Management Client | `continuumMetroDraftService_dmapiClient` | Retrofit client for Deal Management Service (DMAPI) | Retrofit, RxJava3 |
| Marketing Deal Client | `continuumMetroDraftService_marketingDealClient` | Retrofit client for Marketing Deal Service (MDS) | Retrofit, RxJava3 |
| Deal Catalog Client | `continuumMetroDraftService_dealCatalogClient` | Retrofit client for Deal Catalog service | Retrofit, RxJava3 |
| Place Services Client | `continuumMetroDraftService_placeServicesClient` | Retrofit clients for place-read and place-write services | Retrofit, RxJava3 |
| Inventory Clients | `continuumMetroDraftService_inventoryClients` | Retrofit clients for VIS and Redemption Code Pool services | Retrofit, RxJava3 |
| Identity Clients | `continuumMetroDraftService_identityClients` | RBAC, User Service, MAS/UMAPI client set for permissions and contacts | Retrofit, RxJava3 |
| Geo & Taxonomy Clients | `continuumMetroDraftService_geoTaxonomyClients` | Taxonomy, GeoPlaces, and GeoDetails integrations | Retrofit, RxJava3 |
| Infer PDS Client | `continuumMetroDraftService_inferPdsClient` | Pricing recommendation integration with Infer PDS | Retrofit, RxJava3 |
| Salesforce Client | `continuumMetroDraftService_salesforceClient` | Salesforce API integration for deal scores, contracts, and docs | HTTP |
| M3 Merchant Client | `continuumMetroDraftService_m3MerchantClient` | Merchant master data integration via M3 APIs | Retrofit, RxJava3 |
| Partner Services Client | `continuumMetroDraftService_partnerServicesClient` | Partner and delivery integrations including Partner Service and ePODS | Retrofit, RxJava3 |
| Search & Analytics Client | `continuumMetroDraftService_searchAnalyticsClient` | ElasticSearch and Rainbow experimentation integrations | HTTP/Retrofit |
| Messaging & Notifications Client | `continuumMetroDraftService_messagingNotificationsClient` | Slack webhook and NOTS messaging integrations | HTTP/Retrofit |
| Media Clients | `continuumMetroDraftService_mediaClients` | Image/Video services plus BIS/CFS content integrations | HTTP/Retrofit |
| Merchant Case Client | `continuumMetroDraftService_mcsClient` | Merchant Case Service integration for case workflows | Retrofit, RxJava3 |
| MLS Clients | `continuumMetroDraftService_mlsClients` | MLS Sentinel and RIN monitoring integrations | Retrofit, RxJava3 |
| AIDG Client | `continuumMetroDraftService_aidgClient` | Identity data graph integration for contact/account resolution | Retrofit, RxJava3 |
| GenAI Client | `continuumMetroDraftService_genAIClient` | GenAI service integration for assisted deal authoring | Retrofit, RxJava3 |

#### Messaging Layer

| Component | ID | Responsibility | Technology |
|-----------|-----|---------------|-----------|
| Editor Action Publisher | `continuumMetroDraftService_editorActionPublisher` | Publishes recommendation and editor actions to MBus | MBus |
| Signed Deal Producer | `continuumMetroDraftService_signedDealProducer` | Emits signed deal events to MBus for downstream processing | MBus |
| Signed Deal Listener | `continuumMetroDraftService_signedDealListener` | Consumes signed deal events from MBus to trigger workflows | MBus |

#### Batch / Scheduled Jobs

| Component | ID | Responsibility | Technology |
|-----------|-----|---------------|-----------|
| Deal Score Calculator Job | `continuumMetroDraftService_dealScoreCalculatorJob` | Quartz job calculating deal scores and persisting results | Quartz |
| Deal Score to Salesforce Job | `continuumMetroDraftService_dealScoreToSalesforceJob` | Quartz job syncing deal scores to Salesforce | Quartz |
| Stuck Deal Retry Job | `continuumMetroDraftService_stuckDealRetryJob` | Retries stalled deal workflows | Quartz |
| Pending Item Notification Job | `continuumMetroDraftService_pendingItemNotificationJob` | Sends notifications for pending items | Quartz |
| Trial Deal Reminder Job | `continuumMetroDraftService_trialDealReminderJob` | Reminder emails for trial deals and expirations | Quartz |
| Upload Documents Reminder Job | `continuumMetroDraftService_uploadDocumentsReminderJob` | Reminds merchants to upload required documents | Quartz |
| Reset Password Email Job | `continuumMetroDraftService_resetPasswordEmailJob` | Sends reset password emails for draft users | Quartz |
| Covid19 Deal Banner Job | `continuumMetroDraftService_covid19DealBannerJob` | Applies covid safety banners on eligible deals | Quartz |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMetroDraftService` | `continuumMetroDraftDb` | Persists draft deals, merchants, audit logs, and documents | JDBI/PostgreSQL |
| `continuumMetroDraftService` | `continuumMetroDraftMcmPostgres` | Stores merchandising change management data | JDBI/PostgreSQL |
| `continuumMetroDraftService` | `continuumCovidSafetyProgramPostgres` | Stores covid safety program deal data | JDBI/PostgreSQL |
| `continuumMetroDraftService` | `continuumMetroDraftRedis` | Caches permissions and draft artifacts | Jedis/Redis |
| `continuumMetroDraftService` | `continuumMetroDraftMessageBus` | Publishes and consumes deal lifecycle events | MBus |
| `continuumMetroDraftService` | `continuumDealManagementService` | Creates and updates deals in pipeline workflow | HTTP/Retrofit |
| `continuumMetroDraftService` | `continuumMarketingDealService` | Syncs merchandising deals and pricing | HTTP/Retrofit |
| `continuumMetroDraftService` | `continuumDealCatalogService` | Validates and publishes deals to catalog | HTTP/Retrofit |
| `continuumMetroDraftService` | `continuumRbacService` | Performs role and permission checks | HTTP/Retrofit |
| `continuumMetroDraftService` | `continuumInferPdsService` | Requests pricing recommendations | HTTP/Retrofit |
| `continuumMetroDraftService` | `salesForce` | Syncs scores, contracts, and documents | HTTP |
| `continuumMetroDraftService` | `elasticSearch` | Indexes and queries for search | HTTP |
| `continuumMetroDraftService` | `slack` | Sends operational notifications | HTTP |

## Architecture Diagram References

- Container: `containers-continuum-metro-draft-service`
- Component: `components-continuum-metro-draft-service`
- Dynamic — Deal Creation and Publish: `dynamic-continuum-metro-draft-continuumMetroDraftService_dealService-deal-creation`
- Dynamic — Deal Scoring and Salesforce Sync: `dynamic-continuum-metro-draft-continuumMetroDraftService_dealService-deal-scoring`
