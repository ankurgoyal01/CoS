---
service: "AudiencePayloadSpark"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumAudiencePayloadSpark", "continuumAudiencePayloadOps"]
---

# Architecture Context

## System Context

AudiencePayloadSpark sits within the **Continuum Platform** (`continuumSystem`) as a batch data pipeline subsystem. It is operated by the `continuumAudiencePayloadOps` container (Python Fabric/submit scripts running on `cerebro-audience-job-submitter*.snc1` hosts) which submits Spark jobs via `spark-submit` to a YARN cluster. The Spark applications read audience data from Hive tables managed by AMS, call the AMS API for metadata, and write payload artifacts to multiple data stores consumed by the real-time audience serving layer.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Audience Payload Spark Applications | `continuumAudiencePayloadSpark` | Application | Scala 2.12, Apache Spark 2.4, SBT Assembly | 1.56.5 | Scala Spark applications that generate audience attributes and published-audience payloads, aggregate SAD/NonSAD payloads, and write results to data stores |
| Audience Payload Operations Scripts | `continuumAudiencePayloadOps` | Operations | Python, Fabric, spark-submit | — | Python Fabric and helper scripts used to deploy artifacts and submit payload jobs to cluster infrastructure |

## Components by Container

### Audience Payload Spark Applications (`continuumAudiencePayloadSpark`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `attrPayloadGeneratorMain` | Spark entrypoint — uploads system attributes from Hive to Cassandra/Bigtable payload tables | Scala object |
| `paPayloadGeneratorMain` | Spark entrypoint — uploads and deletes PA memberships for a given time window | Scala object |
| `paPayloadAggregatorMain` | Spark entrypoint — SAD and NonSAD PA aggregation pipelines | Scala object |
| `caAttributeRedisWriterMain` | Spark entrypoint — writes CA attributes to Redis | Scala object |
| `caAttributeBigtableWriterMain` | Spark entrypoint — writes CA attributes to GCP Bigtable | Scala object |
| `hiveToKeyspaceWriterMain` | Retry/migration entrypoint — writes Hive-derived SAD payloads to AWS Keyspaces | Scala object |
| `cassandraWriterMain` | Generic Spark tool — writes Hive datasets directly into Cassandra | Scala object |
| `attributePayloadEngine` | Core orchestrator for attribute and PA payload generation (`AttrPayloadGenerator`, `PAPayloadGenerator`) | Scala classes |
| `payloadAggregationEngine` | Core aggregation logic for PA, SAD metadata, and cleanup/update operations (`PAPayloadAggregator`, `PAPayloadAggregatorUnified`) | Scala classes |
| `cassandraAccessLayer` | Connector layer wrapping Cassandra/Keyspaces reads and writes (`CassandraWriter`, `CassandraClientFactory`) | Scala classes |
| `redisAccessLayer` | Redis client layer for CA attribute writes (`RedisClient`, `JedisWrapper`) | Scala classes |
| `bigtableAccessLayer` | Bigtable client and metadata persistence helpers (`BigtableClientFactory`, `SADMetadataWriterBigtable`) | Scala classes |
| `configAndAudienceUtil` | Configuration loading and AMS API utilities used by Spark jobs (`ConfigFactory`, `AudienceUtil`) | Scala objects |

### Audience Payload Operations Scripts (`continuumAudiencePayloadOps`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `fabricTasks` | Operational commands for deployment and job submission (`fabfile.py`) | Python module |
| `submitPayloadScript` | Builds `spark-submit` commands for attribute, PA, and aggregation jobs (`submit_payload.py CommandBuilder`) | Python script |
| `submitCaRedisScript` | Wrapper script for CA Redis upload submission (`submit_consumer_attributes_redis.py`) | Python script |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumAudiencePayloadOps` | `continuumAudiencePayloadSpark` | Submits Spark jobs and operational flows | spark-submit |
| `continuumAudiencePayloadSpark` | `yarnCluster` (stub) | Runs distributed Spark applications | Apache Spark on YARN |
| `continuumAudiencePayloadSpark` | `hiveMetastore` (stub) | Reads source audience tables and writes derived/aggregated tables | Spark SQL with Hive support |
| `continuumAudiencePayloadSpark` | `amsApi` (stub) | Fetches system-table metadata and PA details; updates audience counters | HTTP |
| `continuumAudiencePayloadSpark` | `cassandraKeyspaces` (stub) | Writes payload attributes and PA/SAD membership datasets | Spark Cassandra connector and Keyspaces client |
| `continuumAudiencePayloadSpark` | `gcpBigtable` (stub) | Writes Bigtable metadata and selected attribute payloads | Bigtable client (gRPC) |
| `continuumAudiencePayloadSpark` | `redisCluster` (stub) | Writes CA attributes for consumer access paths | Redis protocol |
| `continuumAudiencePayloadSpark` | `splunkLogging` (stub) | Emits application and operational logs | Log4j / Filebeat |
| `fabricTasks` | `submitPayloadScript` | Builds spark-submit commands for payload workflows | direct |
| `submitPayloadScript` | `attrPayloadGeneratorMain` | Submits attribute upload jobs | spark-submit |
| `submitPayloadScript` | `paPayloadGeneratorMain` | Submits PA membership upload/delete jobs | spark-submit |
| `submitPayloadScript` | `paPayloadAggregatorMain` | Submits SAD and NonSAD aggregation jobs | spark-submit |
| `submitPayloadScript` | `caAttributeRedisWriterMain` | Submits CA attribute Redis writes | spark-submit |
| `submitPayloadScript` | `hiveToKeyspaceWriterMain` | Submits retry/migration writes to Keyspaces | spark-submit |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-continuumAudiencePayloadSpark`
- Component: `components-continuumAudiencePayloadOps`
- Dynamic flow: `dynamic-payload_generation_flow`
