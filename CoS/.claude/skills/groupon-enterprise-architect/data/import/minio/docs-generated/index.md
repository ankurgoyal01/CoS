---
service: "minio"
title: "MinIO Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMinioService]
tech_stack:
  language: "N/A (upstream binary)"
  framework: "MinIO"
  runtime: "Alpine Linux"
---

# MinIO Documentation

Groupon's containerized MinIO deployment — an S3-compatible object storage service running on Kubernetes, providing a self-hosted object storage layer for the Continuum platform.

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
| Language | N/A (upstream MinIO binary, no custom application code) |
| Framework | MinIO RELEASE.2025-09-07T16-13-09Z |
| Runtime | Alpine Linux (Docker) |
| Build tool | Docker (Dockerfile) + Helm (cmf-generic-worker 3.92.0) |
| Platform | Continuum |
| Domain | Object Storage / Infrastructure |
| Team | Conveyor Cloud |
