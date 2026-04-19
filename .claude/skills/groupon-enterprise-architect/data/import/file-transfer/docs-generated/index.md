---
service: "file-transfer"
title: "file-transfer Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["fileTransferService", "continuumFileTransferDatabase"]
tech_stack:
  language: "Clojure 1.5.1"
  framework: "N/A"
  runtime: "JVM (Java 8)"
  build_tool: "Leiningen 2.7.1"
---

# File Transfer Service Documentation

A scheduled worker service that retrieves files from remote SFTP servers, uploads them to the internal File Sharing Service (FSS), and publishes availability notifications to the messagebus.

## Contents

| Document | Description |
|----------|-------------|
| [Overview](overview.md) | Service identity, purpose, domain context, tech stack |
| [Architecture Context](architecture-context.md) | Containers, components, C4 references |
| [API Surface](api-surface.md) | Endpoints, contracts, protocols |
| [Events](events.md) | Async messages published and consumed |
| [Data Stores](data-stores.md) | Databases, caches, storage |
| [Integrations](integrations.md) | External and internal dependencies |
| [Configuration](configuration.md) | Environment, flags, secrets |
| [Flows](flows/index.md) | Process and flow documentation |
| [Deployment](deployment.md) | Infrastructure and environments |
| [Runbook](runbook.md) | Operations, monitoring, troubleshooting |

## Quick Facts

| Property | Value |
|----------|-------|
| Language | Clojure 1.5.1 |
| Framework | N/A (standalone worker) |
| Runtime | JVM (Java 8) |
| Build tool | Leiningen 2.7.1 |
| Platform | Continuum |
| Domain | Finance Engineering |
| Team | Finance Engineering (fed@groupon.com) |
