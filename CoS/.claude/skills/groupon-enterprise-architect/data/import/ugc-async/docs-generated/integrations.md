---
service: "ugc-async"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 14
---

# Integrations

## Overview

ugc-async has a broad integration footprint: it calls 14 internal Continuum platform services via REST (Retrofit HTTP client) and connects to 3 external systems (Teradata, AWS S3, and the MBus platform). All HTTP client connections are configured through `RetrofitConfiguration` blocks in the application YAML. The service is a pure consumer of downstream services; no inbound REST calls from other services are expected.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| MBus Platform | mbus | Consumes all event-driven triggers; the primary inbound interface | yes | `mbusPlatform_9b1a` |
| Teradata Warehouse | JDBC (Teradata) | Read-only source for Goods redemption data used in batch survey creation | yes | `ugcTeradataWarehouse_6b9d` |
| AWS S3 | AWS SDK | Staging bucket for customer images and videos before Image Service ingestion | yes | Not in federated model |

### MBus Platform Detail

- **Protocol**: Internal Groupon MBus (jtier-messagebus-client)
- **Config key**: `messageBus` (MbusConfiguration)
- **Auth**: Internal service authentication via JTIER platform
- **Purpose**: Receives all event-driven work — erasure requests, deal updates, order events, rating events, NLP aspect events, video events
- **Failure mode**: Consumers stop receiving events; Quartz-scheduled jobs continue operating independently
- **Circuit breaker**: No evidence found in source

### Teradata Warehouse Detail

- **Protocol**: JDBC / Teradata driver
- **Config key**: `teraDataConfig` (host, user, password fields in `TeraDataConfig`)
- **Auth**: Username/password (credentials injected via secret service)
- **Purpose**: Batch read of Goods redemption records to identify users eligible for Goods survey creation
- **Failure mode**: `GoodsSurveyCreationJob` and `GoodsInstantSurveyCreationJob` fail; surveys for Goods deals are not created until next scheduled run
- **Circuit breaker**: No evidence found in source

### AWS S3 Detail

- **Protocol**: AWS SDK (AmazonS3 client)
- **Config key**: `aws3Model` (bucket name, credentials)
- **Auth**: AWS credentials injected via `aws3Model` configuration
- **Purpose**: Lists, downloads, and deletes customer-uploaded images and videos from staging bucket during media migration jobs
- **Failure mode**: `S3ImageMoverJob` and `S3VideoMoverJob` fail; images remain in staging bucket until next scheduled run
- **Circuit breaker**: No evidence found in source

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Taxonomy Service | REST (Retrofit) | Reads taxonomy category metadata for survey classification | `continuumTaxonomyService` |
| Deal Catalog Service | REST (Retrofit) | Reads deal metadata (title, images, sub-title) for survey enrichment | `continuumDealCatalogService` |
| Voucher Inventory Service (VIS) | REST (Retrofit) | Reads voucher state to determine survey eligibility | `continuumVoucherInventoryService` |
| Goods Inventory Service (GIS) | REST (Retrofit) | Reads goods inventory state for Goods survey creation | `continuumGoodsInventoryService` |
| Users Service | REST (Retrofit) | Reads user profile data for survey personalisation | `continuumUsersService` |
| Consumer Data Service | REST (Retrofit) | Reads consumer preferences and subscription data | `continuumConsumerDataService` |
| M3 Merchant Service | REST (Retrofit) | Reads merchant data and place-to-merchant mappings for rating aggregation | `continuumM3MerchantService` |
| Booking Service | REST (Retrofit) | Reads booking data for booking-linked survey eligibility | `continuumBookingService` |
| API Gateway | REST | Calls platform deal show APIs for deal data enrichment | `continuumApiGateway` |
| Localization Service (iTier Mobile) | REST (Retrofit) | Reads locale data for survey notification personalisation | `continuumItierMobileService` |
| Rocketman Transactional | REST (Retrofit) | Sends transactional email survey notifications | `rocketmanTransactionalService_1c55` |
| Rocketman Commercial | REST (Retrofit) | Sends push notification survey messages | `rocketmanCommercialService_2d66` |
| CRM Message Service | REST (Retrofit) | Sends inbox (in-app) survey notifications | `crmMessageService_7a44` |
| Image Service (GIMS) | REST (Retrofit, multipart) | Receives images migrated from S3 and returns hosted image URLs | `gimsService_9e27` |
| Third-Party Inventory Service (TPIS) | REST (Retrofit) | Reads third-party deal inventory for TPIS survey creation | `tpisThirdPartyInventoryService_3b5e` |
| Global Subscription Service | REST (Retrofit) | Checks whether users have opted out of survey communications | `globalSubscriptionService_0b7f` |
| Secret Service V2 | REST | Fetches runtime service secrets | `secretServiceV2_1a77` |
| Essence Aspect Tagging Service | MBus (consumer) | Consumes NLP aspect tagging output to update aggregated ratings | `essenceAspectTaggingService_4a88` |
| Orders Service | REST (Retrofit) | Reads order history for survey creation eligibility | `ordersReadService_3c90` |
| M3 Place Read Service | REST (Retrofit) | Reads place data for place-level rating aggregation | `m3PlaceReadService_7d21` |
| SEO API Service | REST (Retrofit) | Reads SEO data for survey enrichment | `seoApiService_2f7b` |
| Surveys Service | REST (Retrofit) | Reads external survey configuration | `surveysService_6c2d` |
| Travel Itinerary Service | REST (Retrofit) | Reads itinerary data for travel survey creation | `travelItineraryService_3e9a` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. ugc-async is a worker service and does not expose inbound service-to-service endpoints. MBus events originate from deal catalog, order processing, voucher inventory, and essence tagging systems.

## Dependency Health

HTTP clients are configured via `RetrofitConfiguration` blocks in the application YAML, which include timeout settings inherited from the JTIER platform defaults. No explicit circuit breaker implementation (e.g., Hystrix, Resilience4j) is observed in the source. Failure modes for HTTP dependencies are handled by individual job/processor exception handling with error logging to Steno/Wavefront.
