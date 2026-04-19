---
service: "travel-search"
title: "EAN Price Update Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "ean-price-update"
flow_type: asynchronous
trigger: "Kafka message on EAN price update stream"
participants:
  - "externalKafkaCluster_f6a7"
  - "travelSearch_kafkaConsumer"
  - "travelSearch_cacheLayer"
  - "travelSearch_persistenceLayer"
  - "continuumTravelSearchRedis"
  - "continuumTravelSearchDb"
architecture_ref: "dynamic-hotelSearchFlow"
---

# EAN Price Update Flow

## Summary

This asynchronous flow ingests real-time hotel rate and price updates sourced from the Expedia EAN system via a Kafka stream. The `travelSearch_kafkaConsumer` component consumes each price update message, propagates new prices to the Redis cache so that subsequent hotel detail requests reflect current rates, and persists the updated pricing to MySQL as a durable record. This flow decouples EAN rate ingestion from the synchronous search request path.

## Trigger

- **Type**: event
- **Source**: Kafka cluster (`externalKafkaCluster_f6a7`) — EAN price update stream topic
- **Frequency**: Continuous (stream-based; rate driven by EAN price update volume)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kafka Cluster | Produces EAN price update events | `externalKafkaCluster_f6a7` |
| Kafka Consumer | Consumes price update messages; orchestrates cache and DB writes | `travelSearch_kafkaConsumer` |
| Cache Layer | Receives updated prices for Redis write | `travelSearch_cacheLayer` |
| Travel Search Redis | Stores current hotel prices for fast read access | `continuumTravelSearchRedis` |
| Persistence Layer | Receives updated prices for MySQL write | `travelSearch_persistenceLayer` |
| Travel Search MySQL | Durable store for persisted hotel pricing | `continuumTravelSearchDb` |

## Steps

1. **Produces EAN price update event**: Expedia EAN system emits a price update message to the Kafka topic.
   - From: `externalKafkaCluster_f6a7`
   - To: `travelSearch_kafkaConsumer`
   - Protocol: Kafka (Kafka Streams)

2. **Consumes price update message**: Kafka Consumer reads the message from the EAN price update partition.
   - From: `travelSearch_kafkaConsumer` (Kafka Streams consumer loop)
   - Protocol: Kafka

3. **Validates and deserialises message**: Kafka Consumer parses the price update payload (hotel ID, rate plan, new rate, currency, effective dates).
   - From: `travelSearch_kafkaConsumer`
   - Protocol: direct (internal)

4. **Updates cached hotel prices**: Writes the new price data to the Redis cache for the affected hotel key.
   - From: `travelSearch_kafkaConsumer`
   - To: `travelSearch_cacheLayer`
   - Protocol: direct (Redis)

5. **Writes price to Redis**: Cache Layer applies the updated price to the hotel's Redis record.
   - From: `travelSearch_cacheLayer`
   - To: `continuumTravelSearchRedis`
   - Protocol: Redis protocol

6. **Persists price update to MySQL**: Kafka Consumer writes the updated price record to the persistence layer.
   - From: `travelSearch_kafkaConsumer`
   - To: `travelSearch_persistenceLayer`
   - Protocol: direct (Ebean)

7. **Writes price to MySQL**: Persistence Layer upserts the hotel pricing record in `continuumTravelSearchDb`.
   - From: `travelSearch_persistenceLayer`
   - To: `continuumTravelSearchDb`
   - Protocol: JDBC

8. **Commits Kafka offset**: After successful cache and DB writes, the consumer commits the offset to mark the message as processed.
   - From: `travelSearch_kafkaConsumer`
   - To: `externalKafkaCluster_f6a7`
   - Protocol: Kafka

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Malformed message payload | Log and skip; offset not committed | Message may be retried depending on Kafka consumer config |
| Redis write failure | Log error; proceed to MySQL write | Cache not updated; prices served from MySQL until next successful cache write |
| MySQL write failure | Log error; do not commit offset | Message retried on next consumer poll cycle |
| Consumer group lag | Kafka partition consumer catches up | Prices temporarily stale until lag resolved |
| Consumer crash | Kafka rebalance; another instance picks up from last committed offset | At-least-once delivery; duplicate writes to MySQL are idempotent by hotel/rate-plan key |

## Sequence Diagram

```
externalKafkaCluster_f6a7 -> travelSearch_kafkaConsumer : EAN price update event
travelSearch_kafkaConsumer -> travelSearch_cacheLayer    : Update cached hotel prices
travelSearch_cacheLayer    -> continuumTravelSearchRedis : Write updated price
travelSearch_kafkaConsumer -> travelSearch_persistenceLayer : Persist price update
travelSearch_persistenceLayer -> continuumTravelSearchDb : Upsert hotel pricing record
travelSearch_kafkaConsumer -> externalKafkaCluster_f6a7  : Commit offset
```

## Related

- Architecture dynamic view: `dynamic-hotelSearchFlow`
- Related flows: [Hotel Detail Retrieval Flow](hotel-detail-retrieval.md), [Background Inventory Sync Flow](background-inventory-sync.md)
