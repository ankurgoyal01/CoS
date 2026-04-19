---
service: "getaways-partner-integrator"
title: "Kafka Partner Inbound Stream"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "kafka-partner-inbound-stream"
flow_type: event-driven
trigger: "Partner message published to a Kafka topic on grouponKafkaCluster_2c7f"
participants:
  - "grouponKafkaCluster_2c7f"
  - "continuumGetawaysPartnerIntegrator"
  - "getawaysPartnerIntegrator_kafkaConsumer"
  - "getawaysPartnerIntegrator_mappingService"
  - "getawaysPartnerIntegrator_inventoryClient"
  - "getawaysPartnerIntegrator_persistenceLayer"
  - "continuumGetawaysPartnerIntegratorDb"
  - "getawaysInventoryService_5e8a"
architecture_ref: "components-getawaysPartnerIntegratorComponents"
---

# Kafka Partner Inbound Stream

## Summary

Partner systems publish messages to Kafka topics on the Groupon Kafka cluster (`grouponKafkaCluster_2c7f`). The Kafka Consumer component (`getawaysPartnerIntegrator_kafkaConsumer`) polls these topics and delegates each message to the Mapping Service for ARI processing and MySQL persistence. This flow handles the asynchronous, high-throughput path for partner data ingestion as an alternative to the synchronous SOAP inbound path.

## Trigger

- **Type**: event (Kafka message)
- **Source**: Partner system or internal Groupon producer publishes a message to a partner inbound Kafka topic
- **Frequency**: Continuous — consumer polls the Kafka topic at configured intervals; message rate driven by partner activity

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Groupon Kafka Cluster | Brokers partner inbound messages | `grouponKafkaCluster_2c7f` |
| Kafka Consumer | Polls Kafka topic and receives partner messages | `getawaysPartnerIntegrator_kafkaConsumer` |
| Mapping Service | Processes the partner message; validates and updates mappings | `getawaysPartnerIntegrator_mappingService` |
| Inventory Service Client | Fetches inventory hierarchy when needed for mapping resolution | `getawaysPartnerIntegrator_inventoryClient` |
| Getaways Inventory Service | Returns hotel/room/rate plan hierarchy | `getawaysInventoryService_5e8a` |
| Persistence Layer | Reads and writes mapping records to MySQL | `getawaysPartnerIntegrator_persistenceLayer` |
| Getaways Partner Integrator DB | Stores updated hotel/room/rate plan mapping state | `continuumGetawaysPartnerIntegratorDb` |

## Steps

1. **Polls Kafka topic**: Kafka Consumer polls the partner inbound topic on `grouponKafkaCluster_2c7f` using kafka-clients 0.10.2.1.
   - From: `getawaysPartnerIntegrator_kafkaConsumer`
   - To: `grouponKafkaCluster_2c7f`
   - Protocol: Kafka (TCP)

2. **Receives partner message**: Kafka Consumer reads and deserializes a partner inbound message from the topic.
   - From: `grouponKafkaCluster_2c7f`
   - To: `getawaysPartnerIntegrator_kafkaConsumer`
   - Protocol: Kafka

3. **Delegates to Mapping Service**: Kafka Consumer passes the deserialized message payload to the Mapping Service for processing.
   - From: `getawaysPartnerIntegrator_kafkaConsumer`
   - To: `getawaysPartnerIntegrator_mappingService`
   - Protocol: Direct (in-process)

4. **Reads current mappings**: Mapping Service reads existing hotel/room/rate plan mappings from MySQL to contextualize the partner message.
   - From: `getawaysPartnerIntegrator_mappingService` → `getawaysPartnerIntegrator_persistenceLayer`
   - To: `continuumGetawaysPartnerIntegratorDb`
   - Protocol: JDBC / MySQL

5. **Fetches inventory hierarchy** (conditional): If the message references identifiers not in local mapping state, Mapping Service fetches hierarchy from the Getaways Inventory Service.
   - From: `getawaysPartnerIntegrator_mappingService` → `getawaysPartnerIntegrator_inventoryClient`
   - To: `getawaysInventoryService_5e8a`
   - Protocol: REST / HTTP

6. **Processes and validates ARI data**: Mapping Service applies business rules to the partner message payload and prepares updated mapping state.
   - From: `getawaysPartnerIntegrator_mappingService`
   - To: `getawaysPartnerIntegrator_mappingService` (internal)
   - Protocol: Direct

7. **Persists updated mappings**: Persistence Layer writes updated mapping records to MySQL.
   - From: `getawaysPartnerIntegrator_mappingService` → `getawaysPartnerIntegrator_persistenceLayer`
   - To: `continuumGetawaysPartnerIntegratorDb`
   - Protocol: JDBC / MySQL

8. **Commits Kafka offset**: Kafka Consumer commits the offset for the processed message to mark it as consumed.
   - From: `getawaysPartnerIntegrator_kafkaConsumer`
   - To: `grouponKafkaCluster_2c7f`
   - Protocol: Kafka

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Message deserialization failure | Consumer exception; offset not committed | Message redelivered on next poll; risk of poison-pill loop |
| Inventory Service unavailable | HTTP call fails; mapping validation cannot complete | Offset not committed; message reprocessed; sustained failure causes consumer lag buildup |
| MySQL write failure | JDBC exception; offset not committed | Message reprocessed; sustained failure causes consumer lag |
| Kafka broker connectivity loss | Kafka consumer reconnects per kafka-clients retry config | Consumer paused until reconnected; lag accumulates |

## Sequence Diagram

```
kafkaConsumer -> grouponKafka: Poll partner inbound topic
grouponKafka --> kafkaConsumer: Partner message(s)
kafkaConsumer -> mappingService: Process partner message
mappingService -> persistenceLayer: Read current mappings
persistenceLayer -> MySQL: SELECT
MySQL --> persistenceLayer: Mapping records
persistenceLayer --> mappingService: Current state
mappingService -> inventoryClient: Fetch inventory hierarchy (if needed)
inventoryClient -> getawaysInventoryService: GET /inventory/hierarchy
getawaysInventoryService --> inventoryClient: Hierarchy data
inventoryClient --> mappingService: Resolved hierarchy
mappingService -> persistenceLayer: Write updated mappings
persistenceLayer -> MySQL: INSERT/UPDATE
MySQL --> persistenceLayer: OK
mappingService --> kafkaConsumer: Processing complete
kafkaConsumer -> grouponKafka: Commit offset
```

## Related

- Architecture dynamic view: `components-getawaysPartnerIntegratorComponents`
- Related flows: [Partner Availability Inbound](partner-availability-inbound.md), [MBus Inventory Worker Outbound](mbus-inventory-worker-outbound.md), [Inventory Mapping REST API](inventory-mapping-rest-api.md)
