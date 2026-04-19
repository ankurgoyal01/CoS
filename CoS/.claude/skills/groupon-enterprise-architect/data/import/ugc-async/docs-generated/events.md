---
service: "ugc-async"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

ugc-async is a primarily event-driven service. It consumes a large set of MBus topics via the JTIER MessageBus client. Each listener is individually feature-flag-gated through boolean fields in `MessageConsumerConfig`. The service does not expose a Kafka or RabbitMQ interface; all messaging is routed through Groupon's internal MBus platform (`mbusPlatform_9b1a`). Published events (outbound) are limited to survey-state changes and acknowledgement messages that downstream consumers may observe.

## Published Events

> No evidence of explicit outbound MBus event publication was found beyond rating aggregation updates written directly to the database. Survey dispatch results are persisted to PostgreSQL rather than published back onto the bus.

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| No direct MBus publish confirmed | - | - | - |

## Consumed Events

Each listener below maps to a `boolean` flag in `MessageConsumerConfig` that enables or disables the consumer at startup.

| Topic / Queue | Config Flag | Handler | Side Effects |
|---------------|-------------|---------|-------------|
| GDPR erasure request topic | `erasureRequestListener` | GDPR Erasure Processor | Anonymises user data across surveys, answers, images in UGC Postgres |
| URL cache expiry topic | `urlCacheExpiryListener` | Cache Sync Processor | Invalidates cached URLs in Redis |
| External content topic | `externalContentListener` | Cache Sync Processor | Processes external content sync events |
| Deal catalog deal-updates topic | `dealCatalogDealUpdatesListener` | Survey Creation Processor | Re-evaluates surveys against updated deal metadata |
| Deal catalog deal-published topic | `dealCatalogDealPublishedListener` | Survey Creation Processor | Triggers survey eligibility checks on deal publish |
| Rating aggregator topic | `ratingAggregatorListener` | Ratings Aggregator | Updates aggregated rating records in UGC Postgres |
| Local survey creator topic | `localSurveyCreator` | Survey Creation Processor (Local) | Creates local deal surveys on order event |
| Local survey creator V2 topic | `localSurveyCreatorV2` | Survey Creation Processor (Local V2) | Creates local deal surveys (V2 event schema) |
| Third-party survey creator topic | `thirdPartySurveyCreator` | Survey Creation Processor (Third Party) | Creates third-party deal surveys |
| Goods survey creator topic | `goodsSurveyCreator` | Survey Creation Processor (Goods) | Creates goods deal surveys from MBus order events |
| Review update topic | `reviewUpdateListener` | Review update handler | Updates review records in UGC Postgres |
| Merchant places change topic | `merchantPlacesChangeListener` | Merchant place data sync handler | Refreshes merchant/place associations |
| Essence NLP topic | `essenceListener` | Essence Listener Service | Updates place aspect summaries and aggregated ratings from NLP output |
| Aspects topic | `aspectsListener` | Essence Listener Service (aspects sub-topic) | Updates adjective aspect scores on aggregated rating records |
| Video update topic | `videoUpdateListener` | Video update handler | Processes video transcoding completion events |
| Answer create topic | `answerCreateListener` | Rating Aggregation Processor | Triggers ratings aggregation on new survey answers |
| Post-purchase VIS topic | `postPurchaseVISListener` | Survey Creation Processor | Triggers survey creation from voucher inventory events |

### Erasure Request Detail

- **Topic**: GDPR erasure request MBus topic (exact topic name managed by MBus platform configuration)
- **Handler**: GDPR Erasure Processor
- **Idempotency**: Erasure operations are applied to immutable records; re-processing is safe if the erasure has already been applied
- **Error handling**: Failures logged and monitored via Wavefront; no DLQ configuration observed in source
- **Processing order**: Unordered

### Rating Aggregation Detail

- **Topic**: Rating aggregator MBus topic
- **Handler**: Ratings Aggregator component
- **Side effects**: Writes aggregated rating rows to `continuumUgcPostgresDb`; triggers place and merchant aspect rollup
- **Idempotency**: Aggregation overwrites existing rating records by context key
- **Processing order**: Unordered

### Essence / Aspects Detail

- **Topic**: Essence NLP output topic (consumed via `essenceListener` and `aspectsListener` flags)
- **Handler**: `EssenceListenerService` — transforms `PlaceAspectMessage` payloads into `PlaceAspectsSummary` lists, merges category-based and non-category-based aspects (cap: 20 per place, 20 per merchant), and updates `AggregatedRating` records
- **Idempotency**: Aspect update is a replace operation keyed by `placeId` and `treatmentId`
- **Processing order**: Unordered

## Dead Letter Queues

> No evidence of explicit DLQ configuration found in source. Error handling relies on exception logging and Wavefront alerting.
