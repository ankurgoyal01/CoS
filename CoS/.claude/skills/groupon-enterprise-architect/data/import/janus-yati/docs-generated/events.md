---
service: "janus-yati"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: ["kafka", "mbus"]
---

# Events

## Overview

Janus Yati is a heavy Kafka consumer. It runs multiple concurrent Spark Structured Streaming jobs, each subscribing to a specific Kafka topic with a dedicated consumer group. Events are consumed in micro-batches (configurable `--batchIntervalMs`) with bounded offsets per trigger (`--maxOffsetsPerTrigger`). On the publish side, it produces replay events back to Kafka and to the Groupon MessageBus for downstream bridge use cases.

All Kafka connections use SSL/TLS mutual authentication with keystore and truststore files provisioned on the Dataproc nodes at `/var/groupon/janus-yati-keystore.jks` and `/var/groupon/truststore.jks`.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `janus-cloud-replay-raw` | Replay event | Manual Airflow DAG trigger (`janus_replay_raw`) | Original Janus event envelope, region, topic, date range |
| `gcs-janus-replay` | GCS-sourced replay event | On-demand via `ReplayMain` when `kafkaWriter=true` | Canonical Janus event, kafkaTopicDestination prefix |
| MessageBus (mbus) | Bridge message | `janusReplayAndMbusBridge` replay flow | Janus event payload republished to downstream mbus consumers |

### janus-cloud-replay-raw Detail

- **Topic**: `janus-cloud-replay-raw`
- **Trigger**: Manual execution of the `janus_replay_raw` Airflow DAG with `kafkaWriter=true` in the DAG params
- **Payload**: Re-encoded Janus events sourced from `gs://grpn-dnd-prod-pipelines-yati-raw/kafka/region=*/` paths
- **Consumers**: Downstream Janus Yati canonical ingestion jobs (`yati-gcs-janus-replay-*`) that re-process the replayed events into canonical Delta Lake tables
- **Guarantees**: at-least-once (Spark checkpoint-based offset tracking)

### MessageBus Bridge Detail

- **Topic**: MessageBus (internal broker)
- **Trigger**: `janusReplayAndMbusBridge` Spark job
- **Payload**: Janus events read from raw GCS storage, re-published for legacy mbus consumers
- **Consumers**: Internal platform services subscribed to mbus topics
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `janus-all` | All Janus platform events (NA GCP) | `KafkaToFileJobMain` (muncher/juno/jupiter/jovi output formats) | Writes Delta Lake tables, BigQuery tables, GCS canonical files |
| `janus-all-sox` | SOX-scoped Janus events (NA GCP) | `KafkaToFileJobMain` (muncher / sox-pipeline formats) | Writes SOX-segregated GCS paths and BigQuery tables |
| `janus-all-sox_snc1` | SOX-scoped EMEA/legacy events | `KafkaToFileJobMain` (muncher / sox-pipeline formats) | Writes SOX EMEA GCS paths |
| `gcs-janus-replay` | Replay events from raw storage | `KafkaToFileJobMain` (muncher/juno/jupiter output formats) | Writes canonical or Delta Lake outputs from replayed events |
| `cdp_ingress` | CDP/Bloomreach platform events | `CdpImporter` | Writes segmented Bloomreach exports to GCS CDP bucket |
| `tracky`, `cdp_ingress`, `tracky_json_nginx`, `mobile_tracking`, `grout_access`, `rocketman_send`, `msys_delivery`, `push_service`, `msys_fbl`, `msys_inbandbounce`, `msys_listunsub`, `msys_remotebounce`, `janus-raw`, `global_subscription_service`, `mobile_proximity_locations`, `mobile_notifications` | Raw source events (loggernaut-json / loggernaut-text) | `KafkaToFileJobMain` (muncher-format-for-raw-sources) | Writes raw event files to GCS raw and canonical buckets |

### janus-all Detail

- **Topic**: `janus-all`
- **Handler**: Multiple concurrent Spark Structured Streaming jobs (`yati-janus-all-gcp`, `yati-janus-all-juno-gcp`, `yati-janus-all-jupiter-gcp`, `yati-janus-all-jovi`) each with a dedicated consumer group
- **Idempotency**: Spark checkpoint-based; offset tracking in GCS operational bucket ensures no re-processing within a run; deduplication is applied separately by the `janus_juno_deduplicator` DAG
- **Error handling**: Job failure triggers email alert to `platform-data-eng@groupon.com` via Airflow `on_failure_callback`; no automatic retry (retries=0 on all DAGs)
- **Processing order**: Unordered within a micro-batch; partitioned by event date on write

### cdp_ingress Detail

- **Topic**: `cdp_ingress`
- **Handler**: `CdpImporter` Spark job; separate runs for NA (`kafka-grpn.us-central1.kafka.prod.gcp.groupondev.com:9094`) and EMEA (`kafka-grpn-k8s.grpn-dse-prod.eu-west-1.aws.groupondev.com:9094`)
- **Idempotency**: Checkpoint-based
- **Error handling**: Email alert on failure; no automatic retry
- **Processing order**: Unordered; event type filtering applied (push notifications, AB experiments, all CDP events written to separate GCS paths)

## Dead Letter Queues

> No evidence found in codebase.

No dedicated DLQ configuration is present. Failed events within a Spark micro-batch cause the job to fail, which triggers an email alert. Replay via the `janus_replay_raw` DAG serves as the recovery mechanism.
