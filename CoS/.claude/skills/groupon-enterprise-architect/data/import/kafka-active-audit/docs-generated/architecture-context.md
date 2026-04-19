---
service: "kafka-active-audit"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: ["continuumKafkaActiveAuditService"]
---

# Architecture Context

## System Context

Kafka Active Audit sits within the Continuum platform as a dedicated infrastructure health-probe service. It connects to Kafka clusters (`messageBus`) across multiple cloud environments (AWS MSK in `us-west-2` and `eu-west-1`, GCP in `us-central1` and `europe-west1`) to verify that the message bus is functioning correctly. It does not interact with application-level systems or end users. Its only consumers are monitoring and alerting stacks (`metricsStack`) that process the metrics it emits via monitord, JMX, and Jolokia.

One pod per cluster/implementation variant is deployed; all pods are stateless workers (no HTTP ingress, no persistent storage).

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Kafka Active Audit Service | `continuumKafkaActiveAuditService` | Worker | Java 11 | 1.3.x | Daemon that produces and consumes audit records on a Kafka topic, tracks missing/latency signals, and emits operational metrics |

## Components by Container

### Kafka Active Audit Service (`continuumKafkaActiveAuditService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `auditBootstrap` | Loads runtime configuration from `.conf` file, initializes all subsystems, registers JVM shutdown hook, and orchestrates startup/shutdown sequencing | Java / Commons-CLI |
| `auditProducer` | Generates timestamped audit records at a configured rate and publishes them to the `kafka-active-audit` topic; tracks produced records in the message cache; emits producer throughput and latency metrics | Apache Kafka Clients |
| `auditConsumer` | Subscribes to the `kafka-active-audit` topic using a configurable thread pool; acknowledges consumed records in the message cache; computes round-trip latency; emits consumer metrics | Apache Kafka Clients |
| `auditMessageCache` | In-process Guava `Cache<UUID, (timestamp, ProducerRecord)>` with a configurable TTL; fires `missing` meter when entries expire without being consumed | Guava Cache |
| `auditMetricsReporter` | Publishes Codahale meters, histograms, and gauges to monitord via synchronous push and exposes JMX beans scraped by Telegraf/Jolokia | Codahale Metrics / Jolokia |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumKafkaActiveAuditService` | `messageBus` | Produces and consumes audit topic messages | Kafka (SSL / mTLS, port 9093 or 9094) |
| `continuumKafkaActiveAuditService` | `metricsStack` | Pushes operational metrics (counters, meters, histograms) | monitord HTTP / JMX |
| `auditBootstrap` | `auditProducer` | Initializes and starts producer execution | internal |
| `auditBootstrap` | `auditConsumer` | Initializes and starts consumer execution | internal |
| `auditBootstrap` | `auditMessageCache` | Initializes message cache and expiry scheduler | internal |
| `auditBootstrap` | `auditMetricsReporter` | Initializes Codahale registry and JMX reporter | internal |
| `auditProducer` | `auditMessageCache` | Adds produced record identifiers for tracking | internal |
| `auditConsumer` | `auditMessageCache` | Removes consumed record identifiers | internal |
| `auditMessageCache` | `auditMetricsReporter` | Fires missing meter on TTL expiry | internal |
| `auditProducer` | `auditMetricsReporter` | Publishes producer throughput/failure/latency metrics | internal |
| `auditConsumer` | `auditMetricsReporter` | Publishes consumer throughput/failure/latency metrics | internal |
| `auditMetricsReporter` | `metricsStack` | Sends metrics for observability | monitord HTTP / JMX |

## Architecture Diagram References

- Container: `containers-continuumKafkaActiveAuditService`
- Component: `components-continuumKafkaActiveAuditService`
- Dynamic view: `dynamic-audit-produce-consume-flow`
