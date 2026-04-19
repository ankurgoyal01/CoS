---
service: "mirror-maker-kubernetes"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for MirrorMaker Kubernetes.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Startup and Initialization](startup-initialization.md) | synchronous | Pod start | Environment validation, config generation, security bootstrap, and MirrorMaker process launch |
| [Topic Replication](topic-replication.md) | event-driven | Continuous (records available on source topic) | Consumption of whitelisted topics from source cluster and republication to destination cluster |
| [Janus Topic Forwarding](janus-topic-forwarding.md) | event-driven | Continuous (janus records on source) | Specialized replication with Janus-forwarder message handler: topic prefix or rename transform |
| [Cross-Cloud Replication](cross-cloud-replication.md) | event-driven | Continuous (GCP or MSK records available) | Bidirectional replication between GCP Kafka and AWS MSK clusters |
| [Metrics Emission](metrics-emission.md) | scheduled | 60-second Telegraf scrape cycle | Jolokia JMX metric collection and InfluxDB forwarding |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 3 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

The `dynamic-mirror-maker-replication-flow` architecture dynamic view in the Continuum workspace captures the end-to-end replication flow across `continuumMirrorMakerService`, `continuumKafkaBroker`, `metricsStack`, and `loggingStack`.
