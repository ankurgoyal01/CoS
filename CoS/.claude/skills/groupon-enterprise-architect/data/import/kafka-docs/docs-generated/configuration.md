---
service: "kafka-docs"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [config-files, host-templates, ops-config]
---

# Configuration

## Overview

The `kafka-docs` documentation site itself has no runtime configuration — it is a static site built by `make server` (dev) and `make publish` (publish). The Kafka platform it documents is configured via Groupon's `ops-config` host template system (`host_templates/kafka-08-broker.yml.erb`, `kafka-10-broker.yml.erb`) and per-host/hostclass YAML files pushed via `roller`. Key configuration items for Kafka clients (producers and consumers) are documented in this file as they represent the primary configuration surface teams must know.

## Environment Variables

> No evidence found in codebase. The GitBook documentation build pipeline does not use environment variables. Kafka broker configuration is managed via `ops-config` host templates, not environment variables.

## Feature Flags

> No evidence found in codebase.

## Config Files

### Kafka Docs Site Build

| File | Format | Purpose |
|------|--------|---------|
| `docs/book.json` | JSON | GitBook site metadata: title, GitHub repo, plugins (`page-toc`, `wide-page`, `expandable-chapters`, `richquotes`) |
| `docs/package.json` | JSON | npm dependencies: `gitbook@3.2.2`, `browser-sync@2.16.0`, `graceful-fs@4.2.4`; Node.js engine `^4.2.6` |
| `docs/Makefile` | Makefile | Defines `setup`, `server`, and `publish` build targets |
| `docs/src/SUMMARY.md` | Markdown | GitBook navigation structure and chapter hierarchy |

### Kafka Broker Configuration

| File | Format | Purpose |
|------|--------|---------|
| `/usr/local/etc/kafka/server.properties` | Properties | Kafka broker configuration on each broker host (e.g., `unclean.leader.election.enable`, `message.max.bytes=10000000`, `zookeeper.session.timeout.ms=6000`) |
| `ops-config/etc/host_templates/kafka-08-broker.yml.erb` | YAML/ERB | Host template for Kafka 0.8/0.10 brokers |
| `ops-config/etc/host_templates/kafka-10-broker.yml.erb` | YAML/ERB | Host template for Kafka 0.10 brokers |

### Logstash Producer Configuration (per client hostclass)

| Parameter | Format | Purpose |
|-----------|--------|---------|
| `params.logstash.kafka_broker_list` | YAML (host file only) | Target Kafka broker endpoint for Logstash; must be set per-host, not per-hostclass, to avoid cross-environment data leakage |
| `params.logstash.global_sincedb_keep_days` | YAML | Days Logstash tracks processed log files; must exceed log retention period |
| `params.logstash.kafka_client_threads` | YAML | Number of Kafka producer threads in Logstash |
| `params.logstash.tmp_dir` | YAML | Logstash working directory (`/var/groupon/logstash`) |
| `params.logstash.global_exclude` | YAML | File patterns Logstash should not process (e.g., `["*.gz","*.zip"]`) |
| `params.logstash_forwarder.file_inputs[].filename` | YAML | Log file glob pattern for a sourcetype |
| `params.logstash_forwarder.file_inputs[].sourcetype` | YAML | Kafka topic name that log lines are published to |
| `params.logstash_forwarder.file_inputs[].file_signature_size` | YAML | Bytes used to fingerprint log file identity (default 1024) |

### Consumer Offset Monitoring Configuration

| Parameter | Format | Purpose |
|-----------|--------|---------|
| `monitors.kafka_consumer_offset.run_every` | YAML | Frequency in seconds to run offset checker (recommended: 60) |
| `monitors.kafka_consumer_offset.shell_command` | YAML | Command path and args for `KafkaConsumerOffsetChecker` jar |

## Secrets

> No evidence found in codebase. No secrets are documented for the kafka-docs static site. Kafka broker communication is plaintext on-prem (no client authentication). AWS MSK TLS uses Conveyor Cert Manager certificates — secret values are never documented.

## Per-Environment Overrides

| Environment | Key Differences |
|-------------|----------------|
| Production (SNC1/SAC1/DUB1) | Auto-topic creation **disabled**; default retention 96 hours; partition count 25; replication factor 3; `unclean.leader.election.enable=false` |
| Staging (SNC1) | Auto-topic creation **disabled** on aggregate cluster; endpoint `kafka-08-broker-staging-vip.snc1:9092` |
| Development (SNC1) | Auto-topic creation **enabled** on local cluster; endpoint `kafka-08-broker-dev-vip.snc1:9092` |
| AWS MSK gensandbox | Auto-topic creation **enabled**; plaintext port 9092; Kafka 2.3.1; minimal sizing |
| AWS MSK grpn-dse-dev | TLS required port 9094; split producer/consumer endpoints; Kafka 2.2.1 (general) / 2.6.0 (metrics) |

### Key Kafka Client Configuration Parameters (for service teams)

| Parameter | Recommended Value | Notes |
|-----------|------------------|-------|
| `client.id` | `<team>-<app>-<datastream>` | Required; unique per application |
| `compression.type` | `lz4` or `snappy` | Use for throughput tuning |
| `batch.size` | Tuned to workload | Larger batches improve throughput |
| `linger.ms` | Tuned to workload | Trade latency for throughput |
| `fetch.message.max.bytes` | `10000000` | Required for old 0.8-protocol consumers |
| `bootstrap.servers` | Cluster endpoint | Use for 0.9+ clients |
| `metadata.broker.list` | Cluster endpoint | Legacy 0.8 clients only |
| `zookeeper.connect` | ZooKeeper endpoint | Legacy 0.8 consumers only; avoid in cloud |
