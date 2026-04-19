---
service: "kafka"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 0
internal_count: 4
---

# Integrations

## Overview

Apache Kafka has no unresolved external dependencies — all components interact exclusively within the Continuum system boundary. The cluster is self-contained: brokers, controllers, Connect workers, and Trogdor agents communicate with each other and with the two filesystem-backed data stores. No stubs for external services were required (confirmed by `stubs.dsl`).

## External Dependencies

> No evidence found. The Kafka module declares no external system dependencies. All relationships are within `continuumSystem`.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Kafka Log Storage | Filesystem I/O | Brokers read and write topic-partition segment files | `continuumKafkaLogStorage` |
| KRaft Metadata Log | Filesystem I/O | Controller persists quorum metadata; brokers read snapshots and deltas | `continuumKafkaMetadataLog` |
| Kafka Broker | Kafka Wire Protocol | Connect workers produce/consume connector records; Trogdor agents generate benchmark traffic | `continuumKafkaBroker` |
| Trogdor Agent | REST | Coordinator dispatches workload tasks to agent nodes | `continuumKafkaTrogdorAgent` |

### Kafka Log Storage Detail

- **Protocol**: Filesystem I/O (local disk or network-attached volume)
- **Auth**: File system permissions
- **Purpose**: Durable storage for all topic-partition records; segment files are appended by the Log Manager and read by the Fetch path
- **Failure mode**: Broker halts affected partitions if the storage volume becomes unavailable; partitions with sufficient ISR replicas on other brokers continue serving traffic

### KRaft Metadata Log Detail

- **Protocol**: Filesystem I/O
- **Auth**: File system permissions
- **Purpose**: Replicated source of truth for cluster metadata; controller writes and followers replicate via the Raft fetch protocol
- **Failure mode**: If the active controller loses access to the metadata log, a new controller is elected from the quorum; cluster remains operational with the last committed metadata state

### Kafka Broker (consumed by Connect and Trogdor) Detail

- **Protocol**: Kafka Wire Protocol (binary TCP)
- **Auth**: SASL / mTLS (same as external clients)
- **Purpose**: Connect workers use the broker's produce/fetch APIs to move records for connectors; Trogdor agents use the same APIs to generate controlled load during benchmarks
- **Failure mode**: Connect workers retry produce/fetch operations using standard Kafka client retry semantics; Trogdor agents report task failure if the target broker is unreachable

### Trogdor Agent Detail

- **Protocol**: REST (HTTP/JSON via Jetty/Jersey)
- **Auth**: None (internal network only)
- **Purpose**: Coordinator issues task start/stop commands to agents and polls their status
- **Failure mode**: If an agent becomes unreachable, the coordinator marks the task as failed and can reassign to another agent

## Consumed By

> Upstream consumers are tracked in the central architecture model. Any Continuum service that produces or consumes events uses the Kafka Wire Protocol against `continuumKafkaBroker`. Known integration points include the Kafka Connect Worker (`continuumKafkaConnectWorker`) and Trogdor Agent (`continuumKafkaTrogdorAgent`) within this module.

## Dependency Health

- Brokers perform periodic segment flush and log-end-offset checks; storage unavailability is surfaced as `KAFKA_STORAGE_EXCEPTION` to producers
- KRaft controller quorum health is assessed by the number of voters in the ISR of the metadata log; operator tooling (`kafka-metadata-quorum.sh`) reports current quorum state
- Kafka Connect worker exposes a REST health endpoint (`GET /connectors/{name}/status`) per connector; the herder (`kafkaConnectHerder`) retries failed tasks with configurable backoff
- No circuit breaker pattern is implemented at the broker level; back-pressure is applied through quota enforcement and fetch throttling
