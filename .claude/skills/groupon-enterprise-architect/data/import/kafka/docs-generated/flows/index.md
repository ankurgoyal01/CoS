---
service: "kafka"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 8
---

# Flows

Process and flow documentation for Apache Kafka.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Message Produce and Replication](message-produce-and-replication.md) | synchronous | Producer sends Produce API request | Producer writes records to a topic-partition; broker persists and replicates to ISR followers |
| [Message Consumption and Offset Commit](message-consumption-and-offset-commit.md) | synchronous | Consumer sends Fetch API request | Consumer fetches records from a partition offset; commits offset after processing |
| [Partition Leadership Failover](partition-leadership-failover.md) | event-driven | Broker failure or controller-triggered reassignment | KRaft controller detects leader loss and elects a new leader from the ISR |
| [KRaft Metadata Replication](kraft-metadata-replication.md) | asynchronous | Controller appends a metadata record | KRaft controller writes metadata change; follower controllers and brokers apply the update |
| [Kafka Connect Source Ingestion](kafka-connect-source-ingestion.md) | event-driven | External system emits data / poll interval fires | Connect source connector polls an external system and produces records to a Kafka topic |
| [Kafka Streams Stateful Processing](kafka-streams-stateful-processing.md) | event-driven | Records arrive on input topic | Streams application consumes records, applies stateful operations using RocksDB, and produces results |
| [Log Compaction and Retention](log-compaction-and-retention.md) | scheduled | Log Manager background thread wakes | Log Manager enforces time/size retention and rewrites compacted segments for compacted topics |
| [Trogdor Performance Testing](trogdor-performance-testing.md) | manual | Operator submits task via Coordinator REST API | Coordinator assigns workload tasks to agents; agents generate produce/consume traffic against brokers |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 4 |
| Batch / Scheduled | 1 |
| Manual | 1 |

## Cross-Service Flows

- The **Message Produce and Replication** and **Message Consumption and Offset Commit** flows are entry points for all Continuum services publishing or subscribing to events. These flows span any Continuum service acting as a producer or consumer and the `continuumKafkaBroker`.
- The **Kafka Connect Source Ingestion** flow spans external data systems (not modeled in this module) and `continuumKafkaBroker` via `continuumKafkaConnectWorker`.
- The central architecture dynamic view `dynamic-kafka-kraft-cluster-control` illustrates the combined KRaft control and data flow across all containers.
