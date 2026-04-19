---
service: "kafka-docs"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 6
---

# Integrations

## Overview

The Kafka platform (documented by kafka-docs) integrates with multiple internal Groupon systems and external services. The `kafka-docs` site build pipeline itself has minimal external dependencies (GitHub Pages for hosting). The Kafka platform integrates with Logstash for log forwarding, Wavefront for metrics, Nagios for alerting, Hydra/MirrorMaker for cross-colo replication, AWS MSK for cloud migration, and PagerDuty for incident management.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| AWS MSK (Amazon Managed Streaming for Apache Kafka) | Kafka binary (plaintext/TLS) | Cloud Kafka clusters for cloud migration target | yes | `continuumKafkaDocsSite` |
| GitHub Pages | Git push (gh-pages branch) | Hosts the static kafka-docs documentation site | yes | `continuumKafkaDocsSite` / `docsPublisher` |
| Wavefront | HTTP metrics push (monitord) | Cluster, topic, consumer lag, and active-audit metrics dashboards | yes | — |
| PagerDuty | Webhook / alert | Incident alerting for cluster health, active-audit failures, and broker downtime | yes | — |

### AWS MSK Detail

- **Protocol**: Kafka binary protocol; plaintext on port 9092 (gensandbox), TLS on port 9094 (grpn-dse-dev and metrics clusters)
- **Base URL / SDK**: `kafka-grpn.gensandbox.us-west-2.aws.groupondev.com:9092`, `kafka-grpn-producer/consumer.grpn-dse-dev.us-west-2.aws.groupondev.com:9094`
- **Auth**: Plaintext (gensandbox), TLS via Conveyor Cert Manager certificates (dev/stable/prod)
- **Purpose**: Cloud migration target for on-prem Kafka workloads; development and POC environment currently available
- **Failure mode**: Cloud clusters are separate from on-prem; on-prem workloads continue unaffected if MSK is unavailable
- **Circuit breaker**: No — clients connect directly; retry handled by Kafka client library

### GitHub Pages Detail

- **Protocol**: Git push to `gh-pages` orphan branch via `make publish`
- **Base URL / SDK**: `https://pages.github.groupondev.com/data/kafka-docs/`
- **Auth**: GitHub repository write access
- **Purpose**: Hosts the compiled static GitBook site; final endpoint is `http://kafka-docs.groupondev.com` (ogwall redirect)
- **Failure mode**: Documentation site unavailable; no impact to Kafka clusters themselves
- **Circuit breaker**: No

### Wavefront Detail

- **Protocol**: Monitord metrics push
- **Base URL / SDK**: `https://groupon.wavefront.com`
- **Auth**: Internal monitord agent
- **Purpose**: Kafka audit dashboard (`kafka-audit`), cluster dashboard (`kafka`), topics dashboard (`kafka-topics`), MSK dashboard (`kafka-msk`), consumer offset lag dashboard (`sac1_snc1-kafka-consumer-offset`)
- **Failure mode**: Loss of observability; cluster continues to function
- **Circuit breaker**: No

### PagerDuty Detail

- **Protocol**: Webhook alert trigger
- **Base URL / SDK**: `https://groupon.pagerduty.com/services/P4VBAQS`
- **Auth**: Internal alerting integration
- **Purpose**: Incident escalation for broker down, ZooKeeper down, disk space critical, and active-audit failures
- **Failure mode**: Alerts not delivered; manual monitoring required
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Logstash (Groupon fork of 1.1.2) | File tail + Kafka producer | Tails application log files and forwards events to Kafka topics | `continuumKafkaDocsSite` |
| MirrorMaker (Apache Kafka MirrorMaker) | Kafka binary (consumer + producer) | Replicates topics from SNC1 Local / SAC1 Local to SNC1 Aggregate / SAC1 Aggregate clusters | `continuumKafkaDocsSite` |
| Janus | Kafka consumer | Consumes canonical Janus topics from aggregate clusters | — |
| GDoop (Hadoop) | Kafka consumer | Ingests topics for batch analytics via Mezzanine | — |
| kafka-active-audit | Kafka producer + consumer | Produces/consumes synthetic audit messages for end-to-end cluster health validation | — |
| Nagios | Monitor (fping / process checks) | Monitors broker and ZooKeeper host availability; triggers alerts for DOWN/CRITICAL states | — |

### Logstash Detail

- **Protocol**: Kafka producer (0.8 wire format via `kafka_broker_list` config)
- **Base URL / SDK**: Groupon fork at `https://github.groupondev.com/data/log-stash/` (Logstash 1.1.2 fork); package `logstash-2015.05.12_18.22_1.1.2.grpn_kafka0.8.1.1`
- **Auth**: No authentication (plaintext broker connection)
- **Purpose**: Primary log-to-Kafka forwarding mechanism; tails log files by sourcetype and publishes to Kafka topics matching the sourcetype name
- **Failure mode**: Log data backlog builds on host; alert fires when `total_back_log` exceeds threshold or `output_exceptions` exceed threshold
- **Circuit breaker**: No; Logstash retries internally and reports backlog metrics

### MirrorMaker Detail

- **Protocol**: Kafka binary (consumer from source cluster + producer to destination cluster)
- **Base URL / SDK**: Apache Kafka MirrorMaker; cloud version at `https://github.groupondev.com/data/mirror-maker-kubernetes`
- **Auth**: No authentication (internal network)
- **Purpose**: Copies topic data from local clusters (SNC1/SAC1) to aggregate clusters (SNC1/SAC1) to enable Hydra multi-colo consumption; upgraded to Kafka v2.8.1
- **Failure mode**: Aggregate topic consumers experience lag or data gap; MirrorMaker restart resolves most issues
- **Circuit breaker**: No

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Groupon service engineers (browser) | HTTPS (GitHub Pages) | Read Kafka usage documentation and runbooks |
| Application teams (Kafka clients) | Kafka binary protocol | Produce to and consume from Kafka topics per the documented client guidelines |

> Upstream Kafka topic consumers are tracked in the central architecture model and Janus service documentation.

## Dependency Health

- Broker health: checked by Nagios via `fping` (host reachability) and `kafka_broker_alive` process check on port 9092
- ZooKeeper health: checked by Nagios via `fping` and `zk_alive` process check; validated with `ruok` 4-letter command
- Active-audit: continuous round-trip message health check; alerts to PagerDuty service `P4VBAQS` on missing or duplicate messages
- Consumer lag: monitored via `KafkaConsumerOffsetChecker` jar emitting `kafka_consumer_offset_topic_[topic]_consumerid_[id]_partition_[n]_lag` metrics to Wavefront
