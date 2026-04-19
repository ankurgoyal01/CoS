---
service: "darwin-indexer"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumDealIndexerService, continuumHotelOfferIndexerService]
---

# Architecture Context

## System Context

darwin-indexer is a pair of background indexing containers within the `continuumSystem` (Continuum Platform). The service does not serve external HTTP traffic; instead it runs scheduled jobs that pull data from Continuum's catalog and enrichment services, then write fully-denormalized documents into Elasticsearch for use by search and ranking consumers. It additionally publishes item feature events to the Holmes platform (Kafka) for ML pipeline consumption. It sits squarely within Continuum's search and relevance sub-domain.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Deal Indexer Service | `continuumDealIndexerService` | Backend | Java / Dropwizard | 1.3.25 | Schedules and executes deal indexing pipelines; aggregates data from catalog/enrichment services and writes to Elasticsearch; publishes feature events to Kafka |
| Hotel Offer Indexer Service | `continuumHotelOfferIndexerService` | Backend | Java / Dropwizard | 1.3.25 | Schedules and executes hotel offer indexing pipelines; aggregates hotel offer and taxonomy data and writes to Elasticsearch |

## Components by Container

### Deal Indexer Service (`continuumDealIndexerService`)

> No components defined yet in the DSL model. Component-level decomposition to be added by the service owner.

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Index Job Scheduler | Triggers full and incremental index runs on a cron schedule | Quartz |
| Deal Data Aggregator | Fetches and merges deal data from Deal Catalog, Taxonomy, Geo, Merchant API, Inventory, Badges, UGC Review, and Merchant Place | RxJava / Retrofit2 |
| Elasticsearch Writer | Batches enriched deal documents and writes them to the Elasticsearch index | Elasticsearch 5.6.16 client |
| Alias Switcher | Performs blue/green alias switchover after a successful full index build | Elasticsearch 5.6.16 client |
| Feature Event Publisher | Publishes `ItemIntrinsicFeatureEvent` to Kafka for Holmes platform | Kafka client |
| Admin / Metrics Server | Exposes health checks and Dropwizard metrics on port 9001 | Dropwizard Metrics 4.1.8 |

### Hotel Offer Indexer Service (`continuumHotelOfferIndexerService`)

> No components defined yet in the DSL model. Component-level decomposition to be added by the service owner.

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Hotel Index Job Scheduler | Triggers hotel offer indexing runs on a cron schedule | Quartz |
| Hotel Offer Aggregator | Fetches hotel offers from Hotel Offer Catalog and taxonomy data from Taxonomy Service | RxJava / Retrofit2 |
| Elasticsearch Writer | Batches enriched hotel offer documents and writes them to the Elasticsearch hotel index | Elasticsearch 5.6.16 client |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumDealIndexerService` | `continuumDealCatalogService` | Fetches deal data | REST |
| `continuumDealIndexerService` | `continuumTaxonomyService` | Fetches taxonomy data | REST |
| `continuumDealIndexerService` | `continuumGeoService` | Fetches geo taxonomy data | REST |
| `continuumDealIndexerService` | `continuumMerchantApi` | Fetches merchant data | REST |
| `continuumDealIndexerService` | `continuumInventoryService` | Fetches inventory data | REST |
| `continuumDealIndexerService` | `continuumBadgesService` | Fetches badges | REST |
| `continuumDealIndexerService` | `ugcReviewService` | Fetches review data | REST (stub only) |
| `continuumDealIndexerService` | `merchantPlaceReadService` | Fetches merchant place data | REST (stub only) |
| `continuumDealIndexerService` | `continuumRedisCache` | Reads feature/sponsored data | Redis protocol |
| `continuumDealIndexerService` | `elasticsearchCluster` | Indexes deals | Elasticsearch transport/HTTP |
| `continuumDealIndexerService` | `kafkaCluster` | Publishes feature events | Kafka |
| `continuumDealIndexerService` | `holmesPlatform` | Publishes item intrinsic data | Kafka |
| `continuumDealIndexerService` | `watsonItemFeatureBucket` | Reads/writes item features | S3 |
| `continuumHotelOfferIndexerService` | `elasticsearchCluster` | Indexes hotel offers | Elasticsearch transport/HTTP |
| `continuumHotelOfferIndexerService` | `hotelOfferCatalogService` | Fetches hotel offers | REST (stub only) |
| `continuumHotelOfferIndexerService` | `continuumTaxonomyService` | Fetches taxonomy data | REST |

> Relationships marked "stub only" exist in the architecture model as stubs; the target containers are not yet present in the federated central model.

## Architecture Diagram References

- Container (deal indexer): `containers-deal-indexer-containers`
- Container (hotel offer indexer): `containers-hotel-offer-indexer-containers`
- Component: `components-darwin-indexer` (not yet defined)
