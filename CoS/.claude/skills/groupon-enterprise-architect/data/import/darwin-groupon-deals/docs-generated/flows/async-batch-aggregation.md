---
service: "darwin-groupon-deals"
title: "Async Batch Aggregation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "async-batch-aggregation"
flow_type: asynchronous
trigger: "Aggregation request event consumed from Kafka topic"
participants:
  - "messagingAdapter_DarGroDea"
  - "aggregationEngine"
  - "externalClients"
  - "cacheLayer"
  - "modelStore"
  - "kafkaClusterExt_4b2e1f"
  - "elasticsearchClusterExt_b8f21c"
  - "redisClusterExt_9d0c11"
  - "continuumDealCatalogService"
  - "continuumBadgesService"
  - "continuumUserIdentitiesService"
  - "continuumGeoPlacesService"
  - "continuumGeoDetailsService"
architecture_ref: "darwinAggregatorServiceComponents"
---

# Async Batch Aggregation

## Summary

The Async Batch Aggregation flow decouples deal aggregation from the synchronous HTTP request path. A producer (typically a batch job or offline pipeline) publishes aggregation request events to a Kafka topic; the Darwin Aggregator Service's `messagingAdapter_DarGroDea` consumes these events, runs the full aggregation and ranking pipeline, and publishes the resulting ranked deal responses back to a Kafka response topic. This flow enables high-throughput or pre-computation use cases where real-time latency is not required.

## Trigger

- **Type**: event
- **Source**: External producer publishing to the Kafka aggregation request topic (`kafkaClusterExt_4b2e1f`)
- **Frequency**: On-demand; driven by upstream batch producers (volume depends on batch job schedules)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `messagingAdapter_DarGroDea` | Consumes request events from Kafka; publishes responses back to Kafka | `continuumDarwinAggregatorService` |
| `aggregationEngine` | Executes full fan-out, aggregation, and ranking pipeline | `continuumDarwinAggregatorService` |
| `externalClients` | Issues HTTP calls to upstream data services | `continuumDarwinAggregatorService` |
| `cacheLayer` | Checks Redis for cached response; writes result on cache miss | `continuumDarwinAggregatorService` |
| `modelStore` | Supplies ML model artifacts for ranking | `continuumDarwinAggregatorService` |
| Kafka Cluster | Delivers request events and receives response events | `kafkaClusterExt_4b2e1f` |
| Elasticsearch Cluster | Supplies deal candidates via index query | `elasticsearchClusterExt_b8f21c` |
| Redis Cluster | Cache lookup and write-back | `redisClusterExt_9d0c11` |
| Deal Catalog Service | Enriches deal candidates with full details | `continuumDealCatalogService` |
| Badges Service | Supplies badge metadata | `continuumBadgesService` |
| User Identities Service | Resolves user identity for personalization | `continuumUserIdentitiesService` |
| Geo Places Service | Resolves geo place context | `continuumGeoPlacesService` |
| Geo Details Service | Supplies geo detail enrichment | `continuumGeoDetailsService` |

## Steps

1. **Consume Request Event**: `messagingAdapter_DarGroDea` polls the Kafka aggregation request topic and receives an aggregation request message.
   - From: `kafkaClusterExt_4b2e1f`
   - To: `messagingAdapter_DarGroDea`
   - Protocol: Kafka protocol

2. **Deserialize Request**: `messagingAdapter_DarGroDea` deserializes the Kafka message payload to extract query parameters, user context, and geo context.
   - From: `messagingAdapter_DarGroDea`
   - To: `aggregationEngine`
   - Protocol: In-process

3. **Cache Lookup**: `cacheLayer` checks Redis for a cached response matching the request key.
   - From: `cacheLayer`
   - To: `redisClusterExt_9d0c11`
   - Protocol: Redis protocol

4. **Cache Hit — Publish Early**: If a cached response exists, `messagingAdapter_DarGroDea` publishes it directly to the Kafka response topic. Flow ends here.
   - From: `messagingAdapter_DarGroDea`
   - To: `kafkaClusterExt_4b2e1f`
   - Protocol: Kafka protocol

5. **Cache Miss — Resolve User Identity**: `externalClients` calls User Identities Service.
   - From: `aggregationEngine`
   - To: `continuumUserIdentitiesService`
   - Protocol: REST/HTTP

6. **Resolve Geo Context**: `externalClients` calls Geo Places and Geo Details Services.
   - From: `aggregationEngine`
   - To: `continuumGeoPlacesService`, `continuumGeoDetailsService`
   - Protocol: REST/HTTP

7. **Query Elasticsearch**: `externalClients` queries the deal index.
   - From: `aggregationEngine`
   - To: `elasticsearchClusterExt_b8f21c`
   - Protocol: Elasticsearch HTTP

8. **Enrich with Deal Catalog and Badges**: `externalClients` fetches deal details and badges for deal candidates.
   - From: `aggregationEngine`
   - To: `continuumDealCatalogService`, `continuumBadgesService`
   - Protocol: REST/HTTP

9. **Load ML Model and Rank**: `modelStore` provides model artifacts; `aggregationEngine` scores and ranks results. See [Deal Ranking and Personalization](deal-ranking-personalization.md).
   - From: `aggregationEngine`
   - To: `modelStore` (in-process)
   - Protocol: In-process

10. **Write to Cache**: `cacheLayer` serializes and stores the aggregated response in Redis. See [Cache Warming](cache-warming.md).
    - From: `cacheLayer`
    - To: `redisClusterExt_9d0c11`
    - Protocol: Redis protocol

11. **Publish Response Event**: `messagingAdapter_DarGroDea` serializes and publishes the ranked aggregation response to the Kafka response topic.
    - From: `messagingAdapter_DarGroDea`
    - To: `kafkaClusterExt_4b2e1f`
    - Protocol: Kafka protocol

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Kafka consumer group lag grows | Increase consumer thread count; check broker health | Batch results delayed; upstream producers must tolerate lag |
| Upstream HTTP service failure | Hystrix circuit isolates failure; aggregation continues with partial data | Response published with partial deal data |
| Elasticsearch unavailable | Circuit opens; deal query skipped | Response published with empty or degraded deal list |
| Serialization failure | Error logged; message offset not committed | Message retried (at-least-once delivery) |
| Kafka publish failure | Retry with exponential backoff | Response delayed; DLQ strategy not confirmed — consult service owner |

## Sequence Diagram

```
ExternalProducer          -> kafkaClusterExt_4b2e1f:         Publish aggregation request event
kafkaClusterExt           -> messagingAdapter_DarGroDea:     Deliver request event
messagingAdapter          -> aggregationEngine:              Dispatch aggregation
aggregationEngine         -> cacheLayer:                     Cache lookup
cacheLayer                -> redisClusterExt_9d0c11:         GET cache key
redisClusterExt           --> cacheLayer:                    MISS
aggregationEngine         -> continuumUserIdentitiesService: Resolve user
aggregationEngine         -> continuumGeoPlacesService:      Resolve geo
aggregationEngine         -> elasticsearchClusterExt:        Query deal index
aggregationEngine         -> continuumDealCatalogService:    Enrich deals
aggregationEngine         -> continuumBadgesService:         Fetch badges
aggregationEngine         -> modelStore:                     Load model
aggregationEngine         -> aggregationEngine:              Rank results
cacheLayer                -> redisClusterExt_9d0c11:         SET response
messagingAdapter          -> kafkaClusterExt_4b2e1f:         Publish response event
```

## Related

- Architecture dynamic view: `darwinAggregatorServiceComponents`
- Related flows: [REST Deal Search](rest-deal-search.md), [Deal Ranking and Personalization](deal-ranking-personalization.md), [Cache Warming](cache-warming.md)
