---
service: "cloudability"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for Cloudability.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Cluster Registration and Manifest Generation](cluster-registration.md) | batch | Manual — Cloud SRE runs `get_agent_config.sh` | Registers a Conveyor Kubernetes cluster with Cloudability, fetches the generated manifest, and applies Groupon-specific patches |
| [Agent Deployment](agent-deployment.md) | batch | Merge to `main` branch (deploybot) or manual kubectl | Deploys the patched Cloudability Metrics Agent manifest to a target Kubernetes cluster via deploybot or kubectl |
| [Kubernetes Metrics Collection and Upload](metrics-collection.md) | scheduled | Continuous — agent runtime timer (approx. every 10 minutes) | Cloudability Metrics Agent reads cluster usage data from the Kubernetes API and uploads metric samples to the Cloudability ingestion endpoint |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 3 |

## Cross-Service Flows

The overall end-to-end provisioning and metrics flow spans the Cloudability SaaS platform and the Conveyor Kubernetes infrastructure. It is documented in the architecture dynamic view `dynamic-cloudability-agent-provisioning-flow`. See [Architecture Context](../architecture-context.md) for the full relationship table.
