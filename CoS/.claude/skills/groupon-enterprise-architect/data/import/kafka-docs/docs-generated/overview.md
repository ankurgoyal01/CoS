---
service: "kafka-docs"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Streaming Infrastructure"
platform: "Continuum"
team: "Data Systems"
status: active
tech_stack:
  language: "Markdown"
  language_version: ""
  framework: "GitBook"
  framework_version: "3.2.2"
  runtime: "Node.js"
  runtime_version: "^4.2.6"
  build_tool: "Make"
  package_manager: "npm"
---

# Kafka Overview

## Purpose

Kafka is a distributed, partitioned, replicated streaming platform operated by the Data Systems team at Groupon. It serves as the central event-streaming backbone, enabling high-volume, near-real-time data pipelines between dozens of producer and consumer services across multiple data centers. The `kafka-docs` repository is the documentation site — a GitBook-based site published to GitHub Pages — that describes how to correctly use, operate, and monitor this platform.

## Scope

### In scope

- Documentation of Kafka cluster endpoints for SNC1, SAC1, and DUB1 (on-prem) and AWS MSK (cloud)
- Kafka client usage guidelines: producing, consuming, offsets, consumer groups
- Hydra multi-colo architecture and migration paths
- Kafka topic and mirror request processes
- MirrorMaker cross-colo topic mirroring documentation
- Logstash-based log forwarding to Kafka
- Cluster operations: rolling restarts, partition management, leader election, capacity planning
- SLA definitions: uptime (99.5% target), retention (default 96 hours), replication factor (3), classified data policy
- Active-audit health-check process documentation
- Runbooks: deploy, provision, health, PagerDuty
- Cloud migration guidance (AWS MSK / Amazon Managed Streaming for Apache Kafka)
- GitBook site build-and-publish pipeline

### Out of scope

- Application-level Kafka client code (handled by individual service teams)
- Janus canonical stream platform (separate service)
- Storm topology framework (StaaS — separate service)
- Spark streaming jobs (separate service teams)
- Long-term data archiving and persistence (not a Kafka use-case)

## Domain Context

- **Business domain**: Streaming Infrastructure / Data Platform
- **Platform**: Continuum (Data Systems group)
- **Upstream consumers**: Any Groupon service team that produces log data, application events, or streaming data to Kafka topics (e.g., logstash agents, application Kafka producers across SNC1/SAC1/DUB1)
- **Downstream dependencies**: Groupon services consuming from Kafka topics; GDoop (Hadoop); Janus canonical event streams; Wavefront metrics; AWS MSK (cloud migration target)

## Stakeholders

| Role | Description |
|------|-------------|
| Data Systems Team | Owns and operates all Kafka clusters and the kafka-docs site. Contact: data-systems-team@groupon.com |
| Service Engineers | Any engineer at Groupon who produces to or consumes from Kafka topics |
| SRE / On-call | Uses runbooks and PagerDuty integration to respond to cluster alerts |
| Data Systems Team Lead | pcammarano (owner) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Content format | Markdown | — | `docs/src/**/*.md` |
| Documentation framework | GitBook | 3.2.2 | `docs/package.json` |
| Runtime | Node.js | ^4.2.6 | `docs/package.json` engines field |
| Build tool | Make | — | `docs/Makefile` |
| Package manager | npm | — | `docs/package.json` |
| Site config | book.json | — | `docs/book.json` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| gitbook | 3.2.2 | ui-framework | Converts markdown to static documentation site |
| browser-sync | 2.16.0 | ui-framework | Live-reloading local development server (`make server`) |
| graceful-fs | 4.2.4 | testing | Polyfill for Node.js `fs` compatibility with GitBook CLI |
| page-toc | — | ui-framework | GitBook plugin: per-page table of contents |
| wide-page | — | ui-framework | GitBook plugin: wide layout |
| expandable-chapters | — | ui-framework | GitBook plugin: collapsible chapter navigation |
| richquotes | — | ui-framework | GitBook plugin: styled blockquote callouts |
