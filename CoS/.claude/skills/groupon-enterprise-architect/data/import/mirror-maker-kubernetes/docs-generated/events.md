---
service: "mirror-maker-kubernetes"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [kafka]
---

# Events

## Overview

MirrorMaker Kubernetes is a pure Kafka replication service. It consumes records from a set of whitelisted source topics and republishes them verbatim (with optional topic prefix transformation) to the corresponding destination topics on the destination cluster. It does not originate events — it acts as a transparent conduit. Each deployment component is scoped to a domain-specific whitelist of topics.

## Published Events (Replicated Topics by Component)

Each deployed pod publishes to topics on the destination cluster, typically prefixed by the destination label (`k8s.*`, `msk.*`, `gcp.*`) or renamed via a Janus forwarder handler.

| Source Topic(s) | Destination Topic Pattern | Component | Direction |
|-----------------|--------------------------|-----------|-----------|
| `janus-all_snc1`, `janus-tier1`, `janus-tier2`, `janus-tier3`, `janus-raw`, `janus-cloud-*`, `gcs-janus-replay`, `janus-all-sox_snc1`, `janus-email_snc1` | `k8s.<source-topic>` | `k8s-msk-janus-mirrors` (eu-west-1) | K8s → MSK |
| `janus-all_snc1`, `janus-tier1`, `janus-tier2`, `janus-tier3`, `janus-raw`, `janus-cloud-*`, `gcs-janus-replay`, `janus-all-sox_snc1`, `janus-email_snc1` | `msk.<source-topic>` | `msk-k8s-janus-mirrors` (eu-west-1) | MSK → K8s |
| `janus-cloud-all`, `janus-cloud-email`, `janus-cloud-tier1/2/3`, `gcs-janus-replay` | `gcp.<source-topic>` | `gcp-msk-janus-mirrors` (us-central1, europe-west1) | GCP → MSK |
| Same as above | `msk.<source-topic>` | `msk-gcp-janus-mirrors` (europe-west1) | MSK → GCP |
| `janus-all_snc1` | `janus-all-eu` (renamed) | `janus-all-eu` (eu-west-1 forwarder) | MSK EU → MSK US |
| `im_push_regla_delayed_instances`, `im_push_regla_storm` | `k8s.<source-topic>` | `k8s-msk-im-mirrors` (eu-west-1) | K8s → MSK |
| `user_event_payload`, `user_event_payload_mobile` | `k8s.<source-topic>` | `k8s-msk-user-event-mirrors` (eu-west-1) | K8s → MSK |
| `msys_delivery`, `msys_delivery_replay`, `msys_fbl`, `msys_inbandbounce`, `msys_inbandbounce_json`, `msys_listunsub`, `msys_remotebounce` | `k8s.<source-topic>` | `k8s-msk-msys-mirrors` (eu-west-1) | K8s → MSK |
| `tracky` | `k8s.<source-topic>` | `k8s-msk-tracky-mirrors` (eu-west-1) | K8s → MSK |
| `mobile_notifications`, `mobile_proximity_locations` | `k8s.<source-topic>` | `k8s-msk-mobile-mirrors` (eu-west-1) | K8s → MSK |
| `batch_dispatch_email` | as-is | `batch-dispatch-email-usc-to-k8s-eu` (eu-west-1) | GCP → K8s EU |
| `batch_dispatch_push` | as-is | `batch-dispatch-push-usc-to-k8s-eu` (eu-west-1) | GCP → K8s EU |
| `batch_dispatch_rapi` | as-is | `gcp-k8s-eu-rapi-forwarder` (eu-west-1) | GCP → K8s EU |
| `cdp_ingress` | as-is | `cdp-ingress-eu-to-usc-topic` (us-central1) | MSK EU → GCP USC |
| Various logging topics (e.g., `logging_staging_nginx`, `logging_staging_rm_service`) | as-is | `logging-test-mirrors` (staging) | K8s → K8s (staging) |

### Janus Topic Replication Detail

- **Source topic pattern**: Pipe-delimited whitelist in `WHITELIST` env var (e.g., `janus-all_snc1|janus-tier1|janus-raw`)
- **Destination topic naming**: When `USE_DESTINATION_TOPIC_PREFIX=true`, each source topic is prefixed with `DESTINATION_TOPIC_PREFIX` (e.g., `k8s.janus-all_snc1`). When `IS_JANUS_FORWARDER=true` and `DESTINATION_TOPIC_NAME` is set, all records are routed to a single renamed topic.
- **Guarantees**: at-least-once (Kafka consumer group commit with `ACKS=1`)
- **Compression**: Snappy applied at the producer side

## Consumed Events

All topics listed above are consumed from the source broker. The service acts as a Kafka consumer group, with the group ID pattern `mirror_maker-<env>-<component>` (e.g., `mirror_maker-production-k8s-msk-janus-mirrors`).

| Topic Pattern | Consumer Group Pattern | Handler | Side Effects |
|---------------|-----------------------|---------|-------------|
| `WHITELIST` topics (per component) | `mirror_maker-<env>-<component>` | MirrorMaker Runtime Launcher | Records are republished to destination cluster topic |

### Consumption Detail

- **Handler**: `mirrorMaker_runtimeLauncher` (kafka-mirror-maker process)
- **Idempotency**: Not guaranteed at-exactly-once; at-least-once delivery is the semantic
- **Error handling**: `MirrorMaker-numDroppedMessages` JMX counter tracks dropped messages; no DLQ configured
- **Offset reset**: Configurable via `AUTO_OFFSET_RESET` env var; defaults to `latest` in most production components, `earliest` in some forwarder and staging configs
- **Processing order**: Partition-ordered within each topic partition

## Dead Letter Queues

> No evidence found in codebase. No DLQ is configured. Dropped messages are tracked via the `mirror_maker.MirrorMaker-numDroppedMessages` JMX metric.
