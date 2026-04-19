---
service: "EC_StreamJob"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumEcStreamJob"]
---

# Architecture Context

## System Context

EC_StreamJob sits within the `continuumSystem` platform as a streaming data-pipeline component owned by the Emerging Channels team. It acts as a bridge between Groupon's real-time Janus behavioral event bus and the Targeted Deal Message (TDM) service. The job has no inbound callers; it is a pure consumer-and-forwarder. It reads from Kafka, enriches events using the Janus metadata API, and pushes results to TDM via HTTP. Two parallel instances run — one against the NA Hadoop cluster (snc1) and one against the EMEA cluster (dub1).

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| EC Stream Job | `continuumEcStreamJob` | Batch / Streaming Job | Scala / Apache Spark | 2.0.1 | Spark Streaming job that consumes Janus events and updates Targeted Deal Message service |

## Components by Container

### EC Stream Job (`continuumEcStreamJob`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| RealTimeJob (main entry point) | Bootstraps SparkConf and StreamingContext; selects Kafka topic and TDM endpoint based on colo/env args | Scala object |
| Kafka Direct Stream reader | Opens a direct stream from `janus-tier2` or `janus-tier2_snc1` with a 20-second batch interval | spark-streaming-kafka-0-8 |
| Avro decoder | Transforms raw Avro bytes to JSON using `AvroUtil.transform()` with the Janus metadata API URL | janus-mapper 1.31 |
| Event filter | Retains only `dealview` and `dealpurchase` events with required fields and matching country for the colo | Scala predicate functions |
| In-partition deduplicator | Removes duplicate events within a partition using a composite key (event+country+bcookie+dealUUID+consumerId+platform+brand) | Scala HashSet |
| TDM HTTP poster | Posts filtered, enriched JSON payloads to TDM `/v1/updateUserData` using async NingWSClient with a 10-thread pool per partition | play-ws 2.4.0-M1 |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumEcStreamJob` | `kafkaTopicJanusTier2` | Consumes Janus event stream | Kafka direct (0.8) |
| `continuumEcStreamJob` | `janusApi` | Fetches schema metadata for Avro decoding | HTTP |
| `continuumEcStreamJob` | `tdmApi` | Posts user event updates to `/v1/updateUserData` | HTTP/JSON |
| `continuumEcStreamJob` | `sparkStreamingCluster` | Runs on YARN-managed Spark cluster | Spark/YARN |

> Note: All relationship targets are stubs in the federated model (`stub_only`). Relationships are defined in `architecture/models/relations.dsl` as commented-out entries pending federation of the target services.

## Architecture Diagram References

- Container: `containers-EC_StreamJob_Containers` (see `architecture/views/components/ecStreamJob-container-view.dsl`)
- Dynamic flow (TDM update): `dynamic-TDMUpdateFlow` (see `architecture/views/dynamics/tdm-update-flow.dsl` — currently disabled pending stub resolution)
