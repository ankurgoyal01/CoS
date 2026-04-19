---
service: "s2s"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumS2sService"
    - "continuumS2sPostgres"
    - "continuumS2sTeradata"
    - "continuumS2sCerebroDb"
    - "continuumS2sKafka"
    - "continuumS2sMBus"
    - "continuumS2sBigQuery"
---

# Architecture Context

## System Context

S2S resides within the `continuumSystem` (Continuum Platform — Groupon's core commerce engine). It occupies the boundary between Groupon's internal event infrastructure and external ad partner APIs. Janus Kafka delivers raw purchase and engagement events; S2S applies consent rules, enriches data with PII and order context, and dispatches conversion signals to four ad networks. It also ingests MBus booster deal updates to drive DataBreaker campaign automation. No external system calls S2S directly in production — all inbound traffic arrives via Kafka or MBus topics, with HTTP endpoints used for internal operational triggers.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| S2S Service | `continuumS2sService` | Backend service | Java 17, Dropwizard, Kafka | JTier 5.14.1 | Core event processor: consent filtering, enrichment, partner dispatch, booster management |
| S2S Postgres | `continuumS2sPostgres` | Database | PostgreSQL | — | Operational store: consent cache, partner click IDs, debug events, grouped purchases, retries, delayed event tracking |
| Teradata EDW | `continuumS2sTeradata` | Database | Teradata | — | Enterprise data warehouse for customer info backfill and AES retry data |
| Cerebro DB | `continuumS2sCerebroDb` | Database | PostgreSQL | — | Reference data: country codes and GP ratios for IV calculations |
| Janus Kafka | `continuumS2sKafka` | Message broker | Kafka | 2.8.1 | Carries Janus Tier events inbound and S2S consent-filtered topics outbound |
| MBus | `continuumS2sMBus` | Message bus | Message Bus | — | Delivers booster deal updates across NA/EMEA regions |
| BigQuery Financial Tables | `continuumS2sBigQuery` | Analytical store | BigQuery | — | Analytical tables for booster ROI, financial metrics, and BI extracts |

## Components by Container

### S2S Service (`continuumS2sService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| S2S Resource (`continuumS2sService_apiResource`) | JAX-RS endpoints for manual deal updates, log level controls, and booster status checks | Java, Dropwizard |
| Job Resource (`continuumS2sService_jobResource`) | JAX-RS endpoints to trigger Quartz jobs for EDW sync, AES retries, and financial data pipelines | Java, Dropwizard |
| Kafka Consumer Manager (`continuumS2sService_kafkaManager`) | Sets up Kafka consumers and polling lifecycle for consent, partner, and DataBreaker pipelines | Java, Kafka |
| Quartz Scheduler (`continuumS2sService_quartzScheduler`) | Configures schedulers and scheduler contexts for batch jobs and booster workflows | Java, Quartz |
| Retrofit Client Registry (`continuumS2sService_retrofitClients`) | Initializes Retrofit HTTP clients for Consent, MDS, Orders, Pricing, DataBreaker, and partner APIs | Java, Retrofit |
| DAO Factory (`continuumS2sService_daoFactory`) | Creates DAOs backed by Postgres, Teradata, and Cerebro for customer info, retries, grouped purchases, and booster history | Java, JDBI |
| Service Factory (`continuumS2sService_serviceFactory`) | Creates domain services for consent, customer info, IV calculation, partner events, caches, and booster workflows | Java |
| Processor Factory (`continuumS2sService_processorFactory`) | Builds event processors for partners, consent filters, MBus ingestion, and booster batch jobs | Java |
| Consent Event Processor (`continuumS2sService_consentEventProcessor`) | Filters Janus events, performs consent checks, and publishes to outbound Kafka topics | Java, Kafka |
| Facebook Event Processor (`continuumS2sService_facebookEventProcessor`) | Transforms filtered events into Facebook CAPI payloads; handles advanced matching | Java |
| Google Event Processor (`continuumS2sService_googleEventProcessor`) | Filters events for Google Ads/Enhanced Conversions and sends partner payloads | Java |
| Reddit Event Processor (`continuumS2sService_redditEventProcessor`) | Builds Reddit Ads conversion payloads and posts to Reddit API | Java |
| TikTok Event Processor (`continuumS2sService_tiktokEventProcessor`) | Routes web, iOS, and Android events to TikTok Ads API | Java |
| DataBreaker Datapoint Processor (`continuumS2sService_dataBreakerDatapointProcessor`) | Consumes booster events; sends datapoints to DataBreaker with optional BigQuery financial enrichment | Java, Kafka |
| DataBreaker Items Processor (`continuumS2sService_dataBreakerItemsProcessor`) | Processes booster deal updates from MBus; sends items and events to DataBreaker | Java, Kafka |
| DataBreaker MBus Mapper (`continuumS2sService_databreakerMBusMapper`) | Maps MBus deal update messages into booster payloads enriched with deal catalog, pricing, and MDS data | Java |
| Consent Service Client (`continuumS2sService_consentService`) | Caches and retrieves consent decisions from the Consent Service | Java |
| Customer Info Service (`continuumS2sService_customerInfoService`) | Fetches and caches hashed customer PII from Postgres and Teradata | Java |
| IV Calculation Service (`continuumS2sService_ivCalculationService`) | Computes GP/IV values using orders data and partner click IDs for consent pipeline enrichment | Java |
| Partner Click ID Cache (`continuumS2sService_partnerClickIdCacheService`) | Stores and retrieves partner click identifiers for attribution | Java |
| Orders Service Client (`continuumS2sService_ordersService`) | Retrieves order details for IV computation and partner payloads | Java |
| MDS Client (`continuumS2sService_mdsService`) | Fetches deal metadata and activation state for booster processing | Java |
| Deal Catalog Service (`continuumS2sService_dealCatalogService`) | Queries deal catalog for booster and mapping enrichment | Java |
| Pricing Service (`continuumS2sService_pricingService`) | Retrieves pricing details for booster mappings | Java |
| DataBreaker Send Event Service (`continuumS2sService_dataBreakerSendEventService`) | Posts datapoints and events to DataBreaker APIs | Java |
| Booster Recommendation Service (`continuumS2sService_boosterRecommendationService`) | Calls DataBreaker items APIs to compute booster recommendation status per deal | Java |
| Google Ads & Sheets Service (`continuumS2sService_googleAdsSheetsService`) | Handles Google Ads automation and Google Sheets ROI export | Java |
| Email Service (`continuumS2sService_emailService`) | Sends SMTP notifications for booster and automation flows | Java |
| ROI Data Service (`continuumS2sService_roiDataService`) | Reads financial data from BigQuery for ROI and automation jobs | Java |
| Delayed Events Service (`continuumS2sService_delayedEventsService`) | Stores and replays delayed partner events from Postgres | Java |
| Grouped Purchase Events Service (`continuumS2sService_groupedPurchaseEventsService`) | Persists grouped purchases for consent filter batching | Java |
| MDS Retry Service (`continuumS2sService_mdsRetryService`) | Persists and retries failed MDS interactions for booster updates | Java |
| Reddit Client Service (`continuumS2sService_redditClientService`) | Queues and posts Reddit Ads API calls with retry and throttling | Java |
| TikTok Client Service (`continuumS2sService_tiktokClientService`) | Queues outbound TikTok Ads API payloads per platform | Java |
| Facebook CAPI Client Service (`continuumS2sService_facebookCapiService`) | Sends web and app events to Facebook CAPI with advanced matching support | Java |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumS2sService` | `continuumS2sPostgres` | Reads/writes consent cache, partner click IDs, debug events, booster history | JDBI/Postgres |
| `continuumS2sService` | `continuumS2sTeradata` | Queries customer info and AES retry data for jobs | JDBC |
| `continuumS2sService` | `continuumS2sCerebroDb` | Reads country codes and GP ratios for IV calculations | JDBI |
| `continuumS2sService` | `continuumS2sKafka` | Consumes Janus Tier topics; publishes consent-filtered events | Kafka |
| `continuumS2sService` | `continuumS2sMBus` | Consumes regional booster deal update topics | MBus |
| `continuumS2sService` | `continuumS2sBigQuery` | Reads financial tables for ROI and booster metrics | BigQuery API |
| `continuumS2sService` | `continuumOrdersService` | Retrieves orders and parent orders for IV enrichment | HTTP/JSON |
| `continuumS2sService` | `continuumDealCatalogService` | Retrieves deal catalog details for booster mapping | HTTP/JSON |
| `continuumS2sService` | `continuumConsentService` | Checks customer consent before forwarding partner events | HTTP/JSON |
| `continuumS2sService` | `continuumMdsService` | Fetches deal details and activation status | HTTP/JSON |
| `continuumS2sService` | `continuumPricingApi` | Retrieves pricing data for booster payloads | HTTP/JSON |
| `continuumS2sService` | `continuumGrouponApi` | Performs validation calls to Groupon public endpoints | HTTP/JSON |
| `continuumS2sService` | `continuumTraskService` | Sends booster/tracking updates to Trask | HTTP/JSON |
| `continuumS2sService` | `continuumUserService` | Fetches user profile data for advanced matching | HTTP/JSON |
| `continuumS2sService` | `continuumDataBreakerApi` | Posts datapoints, items, and retrieves booster recommendations | HTTP/JSON |
| `continuumS2sService` | `continuumFacebookCapi` | Sends conversion events to Facebook CAPI | HTTP/JSON |
| `continuumS2sService` | `continuumGoogleAdsApi` | Sends Google Ads/Enhanced Conversion payloads | HTTP/JSON |
| `continuumS2sService` | `continuumGoogleAppointmentsApi` | Creates appointments via Google integration | HTTP/JSON |
| `continuumS2sService` | `continuumTiktokApi` | Publishes TikTok web/app conversion events | HTTP/JSON |
| `continuumS2sService` | `continuumRedditApi` | Publishes Reddit conversion events | HTTP/JSON |

## Architecture Diagram References

- Component view: `components-continuum-s2s-continuumS2sService_consentService`
- Dynamic view: `dynamic-s2s-event-dispatch`
