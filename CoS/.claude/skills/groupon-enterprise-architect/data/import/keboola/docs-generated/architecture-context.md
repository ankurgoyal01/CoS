---
service: "keboola"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumKeboolaConnectionService]
---

# Architecture Context

## System Context

Keboola Connection is modeled as a container within the `continuumSystem` (Continuum Platform) — Groupon's core commerce and data engine. It acts as a managed integration layer that bridges Salesforce CRM data with BigQuery analytics storage. Groupon teams configure and orchestrate pipelines inside the Keboola platform; the platform itself is operated by the Keboola vendor on single-tenant GCP infrastructure. Operational notifications are routed outbound to Google Chat via webhook.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Keboola Connection Service | `continuumKeboolaConnectionService` | SaaS Integration Runtime | Keboola SaaS | Not applicable | Managed single-tenant Keboola integration runtime used by Groupon for extraction, transformation, and destination loading workflows |

## Components by Container

### Keboola Connection Service (`continuumKeboolaConnectionService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Pipeline Orchestrator (`kbcPipelineOrchestrator`) | Coordinates end-to-end extraction, transformation, and load runs; schedules and triggers all pipeline stages | Workflow Orchestrator |
| Extraction Connectors (`kbcExtractionConnectors`) | Source connectors that pull datasets from upstream systems such as Salesforce | Source Connectors |
| Transformation Engine (`kbcTransformationEngine`) | Applies augmentation and transformation steps to extracted datasets before loading | Transformation Runtime |
| Destination Writers (`kbcDestinationWriters`) | Loads transformed outputs into destination systems and warehouses such as BigQuery | Destination Connectors |
| Ops Notifier (`kbcOpsNotifier`) | Publishes run status, failures, and escalation notifications to Google Chat | Notification Adapter |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumKeboolaConnectionService` | `salesForce` | Extracts CRM and merchant datasets | HTTPS/API |
| `continuumKeboolaConnectionService` | `bigQuery` | Writes transformed datasets for analytics consumption | HTTPS/Batch Load |
| `continuumKeboolaConnectionService` | `googleChat` | Sends operational alerts and support notifications | Webhook |
| `kbcPipelineOrchestrator` | `kbcExtractionConnectors` | Schedules and triggers source extraction runs | Internal |
| `kbcPipelineOrchestrator` | `kbcTransformationEngine` | Starts configured transformation steps | Internal |
| `kbcPipelineOrchestrator` | `kbcDestinationWriters` | Dispatches load stages for destination systems | Internal |
| `kbcPipelineOrchestrator` | `kbcOpsNotifier` | Emits success/failure status events | Internal |
| `kbcExtractionConnectors` | `kbcTransformationEngine` | Passes extracted datasets for transformation | Internal |
| `kbcTransformationEngine` | `kbcDestinationWriters` | Publishes transformed datasets for loading | Internal |
| `kbcDestinationWriters` | `kbcOpsNotifier` | Reports destination load outcomes | Internal |

## Architecture Diagram References

- Component: `components-kbc`
- Dynamic (pipeline run flow): `dynamic-pipeline-run-flow`
