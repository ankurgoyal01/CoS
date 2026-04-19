---
service: "ugc-async"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumUgcAsyncService"
  containers: [continuumUgcAsyncService, continuumUgcPostgresDb, continuumUgcRedisCache]
---

# Architecture Context

## System Context

ugc-async is a worker service within the Continuum platform's User Generated Content domain. It sits behind the MBus message bus — consuming events published by deal catalog, order, and essence tagging services — and drives all UGC background processing. It does not expose public APIs; its only inbound interface is the MBus queue and the Quartz scheduler timer. All consumer-facing UGC reads and writes are handled by separate services (ugc-api / ugc-all). The service reads from and writes to the shared UGC PostgreSQL database and Redis cache, and fans out to a large set of downstream Continuum platform services to enrich survey payloads and dispatch notifications.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| UGC Async Service | `continuumUgcAsyncService` | Service | Java, Dropwizard | 0.2.x | Service for user-generated content background jobs, message bus processing, and survey creation/sending |
| UGC Postgres | `continuumUgcPostgresDb` | Database | PostgreSQL | - | Stores surveys, answers, dispatch records, and Quartz metadata |
| UGC Redis Cache | `continuumUgcRedisCache` | Cache | Redis | 3.0.1 (Jedis) | Coordination, job state tracking, and caching |

## Components by Container

### UGC Async Service (`continuumUgcAsyncService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Message Bus Consumers | Consumes MBus topics/queues and dispatches to handlers | JTIER MessageBus |
| Survey Creation Processor | Creates surveys from inventory and orders data triggered by MBus events | Java |
| Survey Sending Processor | Sends email, push, and inbox survey notifications via downstream notification services | Java |
| Eligibility Framework | Evaluates eligibility rules for survey creation and sending (opted-out users, blacklisted merchants, wait times, duplicate checks) | Java |
| Ratings Aggregator | Aggregates ratings from answer events received on MBus | Java |
| GDPR Erasure Processor | Handles erasure requests and anonymises user data in response to MBus erasure events | Java |
| Cache Sync Processor | Processes cache sync and URL expiry events from MBus | Java |
| Quartz Job Scheduler | Runs scheduled survey creation, survey sending, email reminder, media migration, and cleanup jobs | Quartz |
| UGC Repository | JDBI DAOs for surveys, answers, dispatch records, images, reviews, and aggregated ratings | JDBI |
| Redis Cache Client | Reads/writes Redis for job coordination, deduplication keys, and caching | Jedis / Redisson |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumUgcAsyncService` | `continuumUgcPostgresDb` | Reads/writes UGC data (surveys, answers, dispatch records) | JDBI / SQL |
| `continuumUgcAsyncService` | `continuumUgcRedisCache` | Reads/writes cache for coordination and job state | Redis |
| `continuumUgcAsyncService` | `continuumApiGateway` | Calls platform APIs for deal data | REST |
| `continuumUgcAsyncService` | `continuumTaxonomyService` | Reads taxonomy metadata | REST (Retrofit) |
| `continuumUgcAsyncService` | `continuumDealCatalogService` | Reads deal catalog data | REST (Retrofit) |
| `continuumUgcAsyncService` | `continuumVoucherInventoryService` | Reads voucher inventory | REST (Retrofit) |
| `continuumUgcAsyncService` | `continuumGoodsInventoryService` | Reads goods inventory | REST (Retrofit) |
| `continuumUgcAsyncService` | `continuumUsersService` | Reads user profiles | REST (Retrofit) |
| `continuumUgcAsyncService` | `continuumConsumerDataService` | Reads consumer data | REST (Retrofit) |
| `continuumUgcAsyncService` | `continuumM3MerchantService` | Reads merchant data | REST (Retrofit) |
| `continuumUgcAsyncService` | `continuumBookingService` | Reads booking data | REST (Retrofit) |
| `continuumUgcAsyncService` | `continuumItierMobileService` | Reads localization data | REST (Retrofit) |
| `continuumUgcAsyncService` | `mbusPlatform_9b1a` | Consumes and publishes events | MBus |
| `continuumUgcAsyncService` | `rocketmanTransactionalService_1c55` | Sends email notifications | REST |
| `continuumUgcAsyncService` | `rocketmanCommercialService_2d66` | Sends push notifications | REST |
| `continuumUgcAsyncService` | `crmMessageService_7a44` | Sends inbox notifications | REST |
| `continuumUgcAsyncService` | `ugcTeradataWarehouse_6b9d` | Reads Goods survey creation data | JDBC/Teradata |
| `continuumUgcAsyncService` | `essenceAspectTaggingService_4a88` | Consumes essence tagging output | MBus |
| `continuumUgcAsyncService` | `gimsService_9e27` | Reads image metadata | REST |
| `continuumUgcAsyncService` | `secretServiceV2_1a77` | Fetches service secrets | REST |

## Architecture Diagram References

- Container: `containers-ugc-async`
- Component: `components-ugc-async-service-components`
