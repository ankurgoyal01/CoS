---
service: "kafka"
title: "Kafka Streams Stateful Processing"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "kafka-streams-stateful-processing"
flow_type: event-driven
trigger: "Records arrive on the input topic assigned to a Kafka Streams task"
participants:
  - "continuumKafkaBroker"
  - "kafkaBrokerNetworkApi"
  - "continuumKafkaLogStorage"
architecture_ref: "dynamic-kafka-kraft-cluster-control"
---

# Kafka Streams Stateful Processing

## Summary

A Kafka Streams application deployed within the Continuum platform consumes records from one or more input topics, applies stateful transformations (aggregations, joins, windowing) backed by a local RocksDB state store, and produces results to an output topic. The state store is durably backed by a Kafka changelog topic, enabling recovery after failure. The Streams task interacts with `continuumKafkaBroker` for all record reads and writes.

## Trigger

- **Type**: event
- **Source**: Records arrive on the Streams application's assigned input topic partition(s)
- **Frequency**: Continuous (record-by-record or micro-batch, depending on topology)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kafka Streams Task | Consumes, transforms, and produces records; owns local RocksDB state store | External (Continuum Streams application) |
| Network API (Broker) | Serves Fetch requests for input topic records; accepts Produce requests for output and changelog topics | `kafkaBrokerNetworkApi` |
| Kafka Broker | Stores input, output, and changelog topic partitions | `continuumKafkaBroker` |
| Kafka Log Storage | Persists all topic-partition segment files | `continuumKafkaLogStorage` |
| RocksDB State Store | Local embedded state store for stateful operators | Per-Streams-task local disk (not a separate container) |

## Steps

1. **Fetches input records**: Kafka Streams task issues a Fetch request to `kafkaBrokerNetworkApi` for its assigned input topic partition(s)
   - From: `Streams Task`
   - To: `kafkaBrokerNetworkApi`
   - Protocol: Kafka Wire Protocol (TCP)

2. **Broker reads from log storage**: Log Manager reads records from the input topic segment files in `continuumKafkaLogStorage` and returns a record batch
   - From: `kafkaBrokerNetworkApi`
   - To: `continuumKafkaLogStorage`
   - Protocol: Filesystem I/O

3. **Broker returns record batch**: Network API sends the Fetch response with the input record batch to the Streams task
   - From: `kafkaBrokerNetworkApi`
   - To: `Streams Task`
   - Protocol: Kafka Wire Protocol (TCP)

4. **Deserializes and processes records**: Streams task deserializes each record using the configured Serde and routes it through the topology (filter, map, branch, etc.)
   - From: `Streams Task` (internal)
   - To: `Streams Task` (internal)
   - Protocol: direct (in-process)

5. **Performs stateful operation**: For stateful operators (aggregate, join, count), the task reads and writes the local RocksDB state store; each write is synchronously forwarded to the changelog topic
   - From: `Streams Task`
   - To: `RocksDB State Store` (local)
   - Protocol: RocksDB embedded API

6. **Publishes changelog record**: Each state store write produces a changelog record to the broker to ensure state durability and recoverability
   - From: `Streams Task`
   - To: `kafkaBrokerNetworkApi`
   - Protocol: Kafka Wire Protocol (TCP) — Produce API on changelog topic

7. **Broker persists changelog**: Broker appends the changelog record to `continuumKafkaLogStorage`
   - From: `kafkaBrokerNetworkApi`
   - To: `continuumKafkaLogStorage`
   - Protocol: Filesystem I/O

8. **Produces output records**: Streams task produces result records to the configured output topic on `continuumKafkaBroker`
   - From: `Streams Task`
   - To: `kafkaBrokerNetworkApi`
   - Protocol: Kafka Wire Protocol (TCP) — Produce API

9. **Commits input offset**: Streams task commits the processed input partition offset to `__consumer_offsets` via `OffsetCommit` API
   - From: `Streams Task`
   - To: `kafkaBrokerNetworkApi`
   - Protocol: Kafka Wire Protocol (TCP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Task crash | Streams client reassigns the task; new task restores state from changelog topic before resuming processing | No data loss; processing catches up from last committed input offset |
| State store corruption | Streams deletes local RocksDB directory and restores from changelog topic | Full restoration from changelog; processing delayed until caught up |
| Produce failure to output topic | Streams enters `ERROR` state and stops processing; requires manual restart or `default.production.exception.handler` override | Processing halted; input offsets not advanced |
| Rebalance (new Streams instance added/removed) | Streams protocol reassigns task partitions; state stores are migrated or rebuilt on new assignee | Brief processing pause; state restored from changelog on the new instance |

## Sequence Diagram

```
StreamsTask         -> kafkaBrokerNetworkApi:     Fetch input records (fetch_offset)
kafkaBrokerNetworkApi -> continuumKafkaLogStorage: Read input topic segments
continuumKafkaLogStorage --> kafkaBrokerNetworkApi: Record batch
kafkaBrokerNetworkApi --> StreamsTask:             Input record batch
StreamsTask         -> RocksDB:                   Read/update state store (aggregate/join)
StreamsTask         -> kafkaBrokerNetworkApi:     Produce changelog record (state update)
kafkaBrokerNetworkApi -> continuumKafkaLogStorage: Append changelog segment
kafkaBrokerNetworkApi --> StreamsTask:            Changelog produce ack
StreamsTask         -> kafkaBrokerNetworkApi:     Produce output record to output topic
kafkaBrokerNetworkApi --> StreamsTask:            Output produce ack
StreamsTask         -> kafkaBrokerNetworkApi:     OffsetCommit (input partition offset)
kafkaBrokerNetworkApi --> StreamsTask:            OffsetCommit ack
```

## Related

- Architecture dynamic view: `dynamic-kafka-kraft-cluster-control`
- Related flows: [Message Produce and Replication](message-produce-and-replication.md), [Message Consumption and Offset Commit](message-consumption-and-offset-commit.md)
