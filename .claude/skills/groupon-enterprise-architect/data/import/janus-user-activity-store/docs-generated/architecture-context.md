---
service: "janus-user-activity-store"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumJanusUserActivityStore"
    - "continuumJanusUserActivityOrchestrator"
---

# Architecture Context

## System Context

Janus User Activity Store sits within the Continuum platform as a data ingestion batch pipeline. It is orchestrated by Apache Airflow (Cloud Composer) running on GCP and executes Spark jobs on ephemeral Dataproc clusters. The service reads from a GCS bucket populated by the Janus canonical event pipeline, interacts with the Janus API for event metadata, and writes user activity records to Google Cloud Bigtable. It has no inbound HTTP API surface — all interactions are triggered by the Airflow scheduler.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| Janus User Activity Store | `continuumJanusUserActivityStore` | Batch / DataPipeline | Scala, Apache Spark 2.4.8, HBase Bigtable client | Spark batch application that transforms Janus canonical events into user activity records and writes them to Bigtable |
| Janus User Activity Orchestrator | `continuumJanusUserActivityOrchestrator` | Orchestrator / Batch | Python, Apache Airflow, Dataproc Operators | Airflow DAG orchestration for hourly processing plus monthly table create/purge operational jobs |

## Components by Container

### Janus User Activity Store (`continuumJanusUserActivityStore`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `JanusUserActivityRunner` | CLI entry point — loads config from args, wires core and extended translators, writers, and engines; executes both processing passes; publishes total runner runtime metric | Scala object |
| `Core UserActivityEngine` | Reads Parquet DataFrame, parses JSON `value` column, iterates partitions, calls translator and writer for the core column family (`a`) | Scala class |
| `Extended UserActivityEngine` | Same partition processing as core engine but for the extended column family (`extended`) covering `dealPurchase` events | Scala class |
| `UserActivityTranslator` | Delegates event map to `UserActivity.apply()` with event set and attribute set from the metastore client; returns `Option[UserActivity]` | Scala class |
| `InMemoryJanusMetaStoreClient` | Holds in-memory event attribute maps; calls `GET /janus/api/v1/destination` via edge proxy to resolve JUNO destination metadata | Scala class |
| `UserActivityHBaseWriter` | Partitions `UserActivity` records by platform, creates HBase `Put` operations keyed by `consumerId`, writes in bulk to per-platform Bigtable tables, emits write metrics | Scala class |
| `BigTableConnectionPool` | Creates and caches a `BigtableConfiguration`-backed HBase `Connection` per Spark executor JVM; registers shutdown hook for connection cleanup | Scala object |
| `MetricsPublisher` | Publishes gauge metrics (input record count, partition time, input bytes, per-table record count, time, bytes, runner time) to Telegraf/Wavefront via Influx writer | Scala class |

### Janus User Activity Orchestrator (`continuumJanusUserActivityOrchestrator`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `janus_user_activity_process_bigtable.py` | Defines hourly Airflow DAG (`janus-user-activity-process`, `schedule_interval="5 * * * *"`) — creates ephemeral Dataproc cluster, submits Spark job, deletes cluster | Python DAG |
| `janus_user_activity_create_bigtable_tables.py` | Monthly DAG (`janus-user-activity-bigtable-create-tables`, `schedule_interval="10 16 1 * *"`) — creates upcoming month's user activity Bigtable tables with pre-split keys and column families | Python script |
| `janus_user_activity_purge_bigtable_tables.py` | Monthly DAG (`janus-user-activity-bigtable-purge-tables`, `schedule_interval="10 16 1 * *"`) — purges Bigtable tables older than 732 days (2-year retention) | Python script |
| `DataprocSubmitJobOperator payload` | Spark job submission config invoking `com.groupon.janus.ua.JanusUserActivityRunner` with 7 positional CLI arguments | Airflow Dataproc operator configuration |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumJanusUserActivityOrchestrator` | `bigtableRealtimeStore` | Creates and purges monthly user activity tables | GCP Bigtable Admin API |
| `continuumJanusUserActivityStore` | `bigtableRealtimeStore` | Writes mobile/web/email user activity records | HBase API over gRPC |
| `continuumJanusUserActivityStore` | `apiProxy` | Calls Janus destination metadata API via hybrid boundary edge proxy | HTTPS / mTLS |
| `continuumJanusUserActivityStore` | `metricsStack` | Publishes partition and runtime metrics | Telegraf Influx line protocol |
| `continuumJanusUserActivityStore` | `loggingStack` | Emits batch execution and error logs | Stackdriver/Cloud Logging |
| `janusUserActivityRunner` | `coreUserActivityEngine` | Runs core user activity processing (family=a) | direct (Scala) |
| `janusUserActivityRunner` | `extendedUserActivityEngine` | Runs extended user activity processing (family=extended) | direct (Scala) |
| `userActivityHBaseWriter` | `bigTableConnectionPool` | Obtains Bigtable HBase connection | direct (Scala) |
| `userActivityTranslator` | `janusMetaStoreClient` | Resolves destination metadata for supported event names | direct (Scala) |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component (Store): `components-continuumJanusUserActivityStore`
- Component (Orchestrator): `components-continuumJanusUserActivityOrchestrator`
- Dynamic view: `dynamic-janusUserActivityProcessing` (commented out — references stub-only IDs)
