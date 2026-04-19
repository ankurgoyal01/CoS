---
service: "file-sharing-service"
title: "File Sharing Service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumFileSharingService", "continuumFileSharingMySql"]
tech_stack:
  language: "Clojure 1.7.0"
  framework: "Compojure 1.6.1 / Ring 1.6.3"
  runtime: "JVM (Java 8+)"
---

# File Sharing Service Documentation

A Clojure service that provides upload, download, and sharing of files via Google Drive, with a MySQL-backed metadata store and REST API for use by internal finance engineering consumers.

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
| Language | Clojure 1.7.0 |
| Framework | Compojure 1.6.1 / Ring 1.6.3 |
| Runtime | JVM (Java 8+) |
| Build tool | Leiningen 2+ |
| Platform | Continuum |
| Domain | Finance Engineering |
| Team | finance-engineering (FED) |
