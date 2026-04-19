---
service: "janus-yati"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 6
internal_count: 3
---

# Integrations

## Overview

Janus Yati integrates with six external GCP/cloud platform services (Kafka brokers, GCS, BigQuery, Dataproc, Hive Metastore, and a MySQL database) and three internal Groupon services (Janus metadata API via Hybrid Boundary, MessageBus, and the Metrics/Telegraf stack). All integrations are outbound from the Spark jobs; no service calls Janus Yati directly over a network connection.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Kafka (NA GCP) | Kafka/SSL | Primary event source: consumes `janus-all`, `janus-all-sox`, and raw-source topics | yes | `continuumKafkaBroker` |
| Kafka (EMEA AWS/Strimzi) | Kafka/SSL | EMEA event source: consumes EMEA topics and SOX topics | yes | `continuumKafkaBroker` |
| Google Cloud Storage (GCS) | GCS API | Reads/writes Delta Lake tables, raw archives, canonical files, checkpoints, JAR artifacts | yes | `cloudPlatform` |
| Google BigQuery | BigQuery API | Writes Jovi native tables; executes schema and view DDL | yes | `bigQuery` |
| Google Dataproc | Dataproc API | Hosts and runs all Spark jobs; managed by Airflow orchestrator | yes | `cloudPlatform` |
| Hive Metastore | JDBC (HiveDriver) | Schema registration for Jupiter Delta tables | no | `hiveWarehouse` |
| MySQL (janus-web-cloud RW) | JDBC (MySQL) | Writes business metrics aggregates | no | stub — not in central model |

### Kafka (NA GCP) Detail

- **Protocol**: Kafka SSL/TLS (port 9094)
- **Base URL / SDK**: `kafka-grpn.us-central1.kafka.prod.gcp.groupondev.com:9094`; also `kafka-grpn-consumer.grpn-dse-prod.us-west-2.aws.groupondev.com:9094` (legacy AWS)
- **Auth**: Mutual TLS — keystore `/var/groupon/janus-yati-keystore.jks`, truststore `/var/groupon/truststore.jks`
- **Purpose**: Consumes `janus-all`, `janus-all-sox`, `cdp_ingress`, `gcs-janus-replay`, and raw source topics for all NA/GCP ingestion pipelines
- **Failure mode**: Spark job fails; Airflow sends alert email; no automatic retry; replay flow enables recovery from raw GCS archive
- **Circuit breaker**: No — Spark handles transient Kafka connectivity via internal retries before job failure

### Kafka (EMEA AWS/Strimzi) Detail

- **Protocol**: Kafka SSL/TLS (port 9094)
- **Base URL / SDK**: `kafka-grpn-k8s.grpn-dse-prod.eu-west-1.aws.groupondev.com:9094` (Strimzi), `kafka-grpn-consumer.grpn-dse-prod.eu-west-1.aws.groupondev.com:9094` (legacy AWS)
- **Auth**: Mutual TLS — same keystore/truststore as NA
- **Purpose**: Consumes EMEA `janus-all-sox_snc1`, `cdp_ingress` (INTL), and EMEA raw source topics
- **Failure mode**: Job failure and email alert
- **Circuit breaker**: No

### Google Cloud Storage Detail

- **Protocol**: GCS SDK (Hadoop-compatible filesystem `gs://`)
- **Base URL / SDK**: Google Cloud Hadoop connector (embedded in Dataproc image)
- **Auth**: GCP service account `sa-dataproc-nodes@prj-grp-janus-prod-0808.iam.gserviceaccount.com`; SOX workloads use `loc-sa-dataproc-nodes-sox@prj-grp-janus-prod-0808.iam.gserviceaccount.com`
- **Purpose**: All durable storage — Delta Lake tables, raw archives, canonical files, Spark checkpoints, JAR artifacts, BigQuery staging
- **Failure mode**: Spark job fails on GCS write error; Airflow alert sent
- **Circuit breaker**: No

### Google BigQuery Detail

- **Protocol**: BigQuery Java SDK (`google-cloud-bigquery` 2.35.0)
- **Base URL / SDK**: Project `prj-grp-datalake-prod-8a19`, dataset `janus`; BigLake connection `prj-grp-datalake-prod-8a19.us-central1.janus_biglake`
- **Auth**: GCP service account (inherited from Dataproc node)
- **Purpose**: Native table writes (Jovi sink via indirect GCS load), schema updates, view creation/refresh
- **Failure mode**: Spark job fails; alert sent; schema state can be re-synchronised by re-running `janus_schema_update`
- **Circuit breaker**: No

### Hive Metastore Detail

- **Protocol**: JDBC — `org.apache.hive.jdbc.HiveDriver`
- **Base URL / SDK**: `jdbc:hive2://analytics.data-comp.prod.gcp.groupondev.com:8443/default;ssl=true;transportMode=http;httpPath=gateway/pipelines-adhoc-query/hive`
- **Auth**: Username `svc_gcp_janus`; password retrieved from GCP Secret Manager secret `janus-hive-credentials`
- **Purpose**: Registers and updates Hive Metastore schema for Jupiter Delta table so analytics query engines can discover it
- **Failure mode**: `HiveSchemaUpdate` job fails; analytics queries use stale schema until next successful run
- **Circuit breaker**: No

### MySQL (janus-web-cloud RW) Detail

- **Protocol**: JDBC — MySQL connector 8.0.27
- **Base URL / SDK**: `jdbc:mysql://janus-web-cloud-rw-na-production-db.gds.prod.gcp.groupondev.com:3306/janus?prepareThreshold=0&relaxAutoCommit=true&enabledTLSProtocols=TLSv1.2`
- **Auth**: Credential source not documented in code; provisioned as Dataproc node secret
- **Purpose**: Writes Janus business metrics aggregates from the Business Metrics Exporter Spark job
- **Failure mode**: Metrics export fails; business metrics dashboards show stale data
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Janus Metadata Service (`janus-web-cloud`) | HTTPS via Hybrid Boundary | Resolves event attributes, output routing, schema, and metadata for all Spark ingestion jobs | stub — `unknown_janusmetadataserviceapi_44630dae` |
| Groupon MessageBus | mbus-client | Publishes replay and bridge messages to legacy mbus consumers | `messageBus` |
| Telegraf / Metrics Stack | HTTP (Telegraf push) | Publishes runtime and orchestration metrics; endpoint `telegraf.production.service` via edge-proxy | `metricsStack` |

### Janus Metadata Service Detail

- **Protocol**: HTTPS via Hybrid Boundary edge proxy at `https://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com`
- **Base URL / SDK**: Service URL `janus-web-cloud.production.service`, base path `/janus/api/v1`; uses `okhttp` 3.14.9 with mutual TLS (same keystore/truststore)
- **Auth**: Mutual TLS via Hybrid Boundary
- **Purpose**: All ingestion jobs call the Janus metadata API to resolve event routing and schema attributes before writing to output sinks
- **Failure mode**: Spark job fails if metadata cannot be resolved; alert sent

## Consumed By

> Upstream consumers are tracked in the central architecture model.

The outputs of Janus Yati (GCS Delta Lake tables, BigQuery tables, raw GCS files) are consumed by analytics teams, BI tools, and downstream data pipelines. These consumers are not discoverable from this repository.

## Dependency Health

No circuit breakers or health-check probes are defined in this codebase. Dependency health is monitored via Airflow DAG failure alerts (email to `platform-data-eng@groupon.com`) and dashboards on Wavefront (`https://groupon.wavefront.com/dashboards/janus-yati--sma`). PagerDuty service `P25RQWA` handles critical alerts at `janus-prod-alerts@groupon.pagerduty.com`.
