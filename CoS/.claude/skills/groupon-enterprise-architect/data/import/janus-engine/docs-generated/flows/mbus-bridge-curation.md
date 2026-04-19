---
service: "janus-engine"
title: "MBus Bridge Curation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "mbus-bridge-curation"
flow_type: event-driven
trigger: "Raw domain event published to MBus by an upstream Continuum service"
participants:
  - "continuumOrdersService"
  - "continuumUsersService"
  - "continuumDealCatalogService"
  - "continuumInventoryService"
  - "continuumRegulatoryConsentLogApi"
  - "continuumPricingService"
  - "messageBus"
  - "continuumJanusEngine"
  - "mbusIngestionAdapter"
  - "curationProcessor"
  - "janusMetadataClientComponent"
  - "janusEngine_kafkaPublisher"
architecture_ref: "dynamic-mbusToKafkaFlow"
---

# MBus Bridge Curation

## Summary

In `MBUS` mode, Janus Engine bridges raw domain events from MBus topic subscriptions to canonical Janus Kafka topics. Upstream Continuum services (Orders, Users, Deal Catalog, Inventory, Regulatory Consent Log, Pricing) publish raw events to MBus. The `mbusIngestionAdapter` (built on RxJava and MBus client 1.5.2) subscribes to those topics, invokes the `curationProcessor` to normalize each event using mapper metadata from the Janus metadata service, and publishes the canonical result to the correct Janus Kafka sink topic via `janusEngine_kafkaPublisher`. This is the primary ingest mode for Continuum-to-Janus event bridging.

## Trigger

- **Type**: event
- **Source**: Upstream Continuum service publishes a raw domain event to a configured MBus topic
- **Frequency**: Continuous (per-message; high-volume across all upstream producer services)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Orders Service | Publishes OrderSnapshots, OrderProcessingActivities to MBus | `continuumOrdersService` |
| Users Service | Publishes user account and identity lifecycle events to MBus | `continuumUsersService` |
| Deal Catalog Service | Publishes deal snapshot events to MBus | `continuumDealCatalogService` |
| Inventory Service | Publishes inventory product/unit snapshot events to MBus | `continuumInventoryService` |
| Regulatory Consent Log API | Publishes regulatory consent log events to MBus | `continuumRegulatoryConsentLogApi` |
| Pricing Service | Publishes dynamic pricing events to MBus | `continuumPricingService` |
| Message Bus | Delivers source MBus topic payload to Janus Engine | `messageBus` |
| Janus Engine (MBus mode) | Hosts the MBus bridge runtime | `continuumJanusEngine` |
| MBus Engine Adapter | Subscribes to MBus topics; drives RxJava ingestion pipeline | `mbusIngestionAdapter` |
| Curator Processor | Normalizes and transforms source payload into canonical Janus event | `curationProcessor` |
| Janus Metadata Client | Supplies mapper definitions and routing rules | `janusMetadataClientComponent` |
| Kafka Publisher | Publishes canonical event envelope to the correct Janus sink topic | `janusEngine_kafkaPublisher` |

## Steps

1. **Upstream service publishes raw event**: An upstream Continuum service (e.g., Orders) publishes a raw domain event to its MBus topic.
   - From: upstream service (e.g., `continuumOrdersService`)
   - To: `messageBus`
   - Protocol: MBus

2. **MBus delivers to Janus Engine**: MBus delivers the source topic payload to `continuumJanusEngine`.
   - From: `messageBus`
   - To: `mbusIngestionAdapter`
   - Protocol: MBus (mbus-client 1.5.2)

3. **Adapter receives and buffers event**: `mbusIngestionAdapter` receives the event via its RxJava subscription and passes it to the curation pipeline.
   - From: `messageBus`
   - To: `mbusIngestionAdapter`
   - Protocol: MBus / RxJava (rxjava 2.2.21)

4. **Fetch mapper metadata**: `curationProcessor` looks up the mapper definition and routing rules for the event's source topic and event type.
   - From: `curationProcessor`
   - To: `janusMetadataClientComponent`
   - Protocol: direct (in-process cache; HTTP fallback via curator-api 0.0.41)

5. **Apply curation and transform**: `curationProcessor` normalizes the raw payload against the mapper definition, extracts fields using json-path, resolves the canonical schema, and determines the target sink topic.
   - From: `mbusIngestionAdapter`
   - To: `curationProcessor`
   - Protocol: direct

6. **Publish canonical event**: `janusEngine_kafkaPublisher` writes the canonical event to the appropriate Janus Kafka sink topic.
   - From: `curationProcessor` → `janusEngine_kafkaPublisher`
   - To: `janus-cloud-tier1`, `janus-cloud-tier2`, `janus-cloud-tier3`, `janus-cloud-impression`, `janus-cloud-email`, or `janus-cloud-raw`
   - Protocol: Kafka (kafka-clients 2.7.0)

7. **Emit metrics**: `mbusIngestionAdapter` and `janusEngine_healthAndMetrics` emit processing metrics to `metricsStack`.
   - From: `mbusIngestionAdapter`, `janusEngine_healthAndMetrics`
   - To: `metricsStack`
   - Protocol: SMA metrics

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MBus subscription dropped | RxJava error handler; reconnect attempt | Event flow pauses until reconnect; health flag may become unhealthy |
| Mapper not found for event type | `curationProcessor` cannot transform | Event skipped or routed to MBus dead-letter queue for [DLQ Replay](dlq-replay.md) |
| Kafka publish failure | Kafka producer retries (at-least-once) | Event retried; persistent failure may cause processing halt |
| Metadata service unreachable | Cached metadata used | Processing continues with potentially stale mappers |
| Malformed source payload | json-path extraction fails | Event logged and skipped or routed to DLQ |

## Sequence Diagram

```
continuumOrdersService -> messageBus          : Publishes raw order event (OrderSnapshot)
messageBus             -> mbusIngestionAdapter : Delivers source MBus topic payload
mbusIngestionAdapter   -> curationProcessor   : Passes raw payload for curation
curationProcessor      -> janusMetadataClientComponent : Requests mapper/rules for (topic, event type)
janusMetadataClientComponent --> curationProcessor : Returns mapper definition and routing tier
curationProcessor      -> janusEngine_kafkaPublisher   : Passes canonical event + target topic
janusEngine_kafkaPublisher -> janus-cloud-tier* : Publishes canonical Janus event
mbusIngestionAdapter   -> janusEngine_healthAndMetrics : Emits MBus processing metrics
```

## Related

- Architecture dynamic view: `dynamic-mbusToKafkaFlow`
- Related flows: [Kafka Stream Curation](kafka-stream-curation.md), [DLQ Replay](dlq-replay.md), [Curator Metadata Refresh](curator-metadata-refresh.md)
