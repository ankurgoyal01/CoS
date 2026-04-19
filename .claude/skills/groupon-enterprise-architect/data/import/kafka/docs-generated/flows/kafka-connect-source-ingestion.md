---
service: "kafka"
title: "Kafka Connect Source Ingestion"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "kafka-connect-source-ingestion"
flow_type: event-driven
trigger: "Source connector task poll interval fires, or external system pushes data to the connector"
participants:
  - "continuumKafkaConnectWorker"
  - "kafkaConnectHerder"
  - "kafkaConnectConnectorRuntime"
  - "kafkaConnectOffsetStore"
  - "continuumKafkaBroker"
  - "kafkaBrokerNetworkApi"
architecture_ref: "dynamic-kafka-kraft-cluster-control"
---

# Kafka Connect Source Ingestion

## Summary

A Kafka Connect source connector task continuously polls an external data source, converts records to Kafka's internal format, produces them to a configured topic on the broker, and then checkpoints the source offset in the `connect-offsets` topic. The Herder manages the connector and task lifecycle across worker nodes.

## Trigger

- **Type**: event
- **Source**: Source connector task poll interval (configured per connector), or external system push (webhook-style connectors)
- **Frequency**: Continuous polling loop; interval is connector-specific

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Herder | Manages connector lifecycle; distributes tasks across workers | `kafkaConnectHerder` |
| Connector Runtime | Executes the source connector task; polls external system and transforms records | `kafkaConnectConnectorRuntime` |
| Offset Store Client | Persists and reads source connector offsets in `connect-offsets` topic | `kafkaConnectOffsetStore` |
| Network API (Broker) | Accepts produce requests from the connector task and serves offset topic reads/writes | `kafkaBrokerNetworkApi` |
| Kafka Broker | Stores produced records in the target topic and the `connect-offsets` internal topic | `continuumKafkaBroker` |

## Steps

1. **Herder starts connector task**: On worker startup (or after a configuration change), `kafkaConnectHerder` assigns a source connector task to this worker and starts the `kafkaConnectConnectorRuntime`
   - From: `kafkaConnectHerder`
   - To: `kafkaConnectConnectorRuntime`
   - Protocol: direct (in-process)

2. **Reads last committed source offset**: `kafkaConnectOffsetStore` fetches the connector's last checkpointed source position from the `connect-offsets` topic on the broker; determines where to resume ingestion
   - From: `kafkaConnectOffsetStore`
   - To: `kafkaBrokerNetworkApi`
   - Protocol: Kafka Wire Protocol (TCP) — Fetch API on `connect-offsets`

3. **Polls external data source**: Connector Runtime polls the external source system (database, REST API, file system, etc.) for new records starting from the retrieved offset
   - From: `kafkaConnectConnectorRuntime`
   - To: External source system (not modeled in this module)
   - Protocol: source-specific (JDBC, REST, file, etc.)

4. **Transforms and converts records**: Connector Runtime applies configured Single Message Transforms (SMTs) to convert source records into Kafka `SourceRecord` objects with key, value, topic, and offset
   - From: `kafkaConnectConnectorRuntime` (internal)
   - To: `kafkaConnectConnectorRuntime` (internal)
   - Protocol: direct (in-process)

5. **Produces records to target topic**: Connector Runtime uses the embedded Kafka producer to send converted records to the configured target topic on `continuumKafkaBroker`
   - From: `kafkaConnectConnectorRuntime`
   - To: `kafkaBrokerNetworkApi`
   - Protocol: Kafka Wire Protocol (TCP) — Produce API

6. **Commits source offset**: After the broker acknowledges the produce, Connector Runtime instructs `kafkaConnectOffsetStore` to write the new source offset to the `connect-offsets` topic
   - From: `kafkaConnectConnectorRuntime`
   - To: `kafkaConnectOffsetStore`
   - Protocol: direct (in-process)

7. **Offset stored in broker**: `kafkaConnectOffsetStore` produces the offset record to the `connect-offsets` internal topic on `continuumKafkaBroker`
   - From: `kafkaConnectOffsetStore`
   - To: `kafkaBrokerNetworkApi`
   - Protocol: Kafka Wire Protocol (TCP) — Produce API on `connect-offsets`

8. **Loop continues**: Connector Runtime sleeps for the configured poll interval, then repeats from step 3

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| External source unavailable | Connector task retries with exponential backoff (configured via `errors.retry.timeout`) | Task enters `FAILED` state if retries exhausted; Herder can restart the task |
| Produce failure to broker | Kafka producer retries with configurable `retries` and `retry.backoff.ms` | If broker is temporarily unavailable, records are buffered in producer memory; task may pause |
| Offset commit failure | Source offset not advanced; records will be re-polled and re-produced on next poll | At-least-once delivery; downstream consumers must handle duplicates |
| Task crash | Herder detects task failure and restarts it; offset resumes from last committed position | No data loss; potential for duplicate records |
| Worker rebalance | Herder redistributes tasks across available workers; each task restarts from last committed offset | Brief interruption in ingestion; no data loss |

## Sequence Diagram

```
kafkaConnectHerder      -> kafkaConnectConnectorRuntime: Start source connector task
kafkaConnectOffsetStore -> kafkaBrokerNetworkApi:        Fetch last committed source offset (connect-offsets)
kafkaBrokerNetworkApi   --> kafkaConnectOffsetStore:     Last offset record
kafkaConnectOffsetStore --> kafkaConnectConnectorRuntime: Resume offset
kafkaConnectConnectorRuntime -> ExternalSource:          Poll for new records (from offset)
ExternalSource          --> kafkaConnectConnectorRuntime: Raw source records
kafkaConnectConnectorRuntime -> kafkaConnectConnectorRuntime: Apply SMT transforms
kafkaConnectConnectorRuntime -> kafkaBrokerNetworkApi:   Produce records to target topic
kafkaBrokerNetworkApi   --> kafkaConnectConnectorRuntime: Produce acknowledged
kafkaConnectConnectorRuntime -> kafkaConnectOffsetStore: Commit new source offset
kafkaConnectOffsetStore -> kafkaBrokerNetworkApi:        Produce offset to connect-offsets topic
kafkaBrokerNetworkApi   --> kafkaConnectOffsetStore:     Offset committed
```

## Related

- Architecture dynamic view: `dynamic-kafka-kraft-cluster-control`
- Related flows: [Message Produce and Replication](message-produce-and-replication.md), [Message Consumption and Offset Commit](message-consumption-and-offset-commit.md)
