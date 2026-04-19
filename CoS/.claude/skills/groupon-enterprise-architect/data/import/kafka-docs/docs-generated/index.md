---
service: "kafka-docs"
title: "Kafka Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumKafkaDocsSite"]
tech_stack:
  language: "Markdown"
  framework: "GitBook 3.2.2"
  runtime: "Node.js ^4.2.6"
---

# Kafka Documentation

Groupon's authoritative documentation site for operating, consuming from, and producing to the Kafka distributed streaming platform, published via GitBook to GitHub Pages.

## Contents

| Document | Description |
|----------|-------------|
| [Overview](overview.md) | Service identity, purpose, domain context, tech stack |
| [Architecture Context](architecture-context.md) | Containers, components, C4 references |
| [API Surface](api-surface.md) | Broker endpoints and Kafka protocol access patterns |
| [Events](events.md) | Kafka topics, producing, and consuming patterns |
| [Data Stores](data-stores.md) | Kafka broker storage, ZooKeeper, offset retention |
| [Integrations](integrations.md) | Logstash, Hydra, MirrorMaker, AWS MSK, Wavefront |
| [Configuration](configuration.md) | Broker configs, consumer/producer config parameters |
| [Flows](flows/index.md) | Process and flow documentation |
| [Deployment](deployment.md) | Infrastructure, cluster topology, environments |
| [Runbook](runbook.md) | Operations, monitoring, troubleshooting |

## Quick Facts

| Property | Value |
|----------|-------|
| Language | Markdown |
| Framework | GitBook 3.2.2 |
| Runtime | Node.js ^4.2.6 |
| Build tool | Make (`docs/Makefile`) |
| Platform | Continuum (Data Systems) |
| Domain | Streaming Infrastructure |
| Team | Data Systems (data-systems-team@groupon.com) |
