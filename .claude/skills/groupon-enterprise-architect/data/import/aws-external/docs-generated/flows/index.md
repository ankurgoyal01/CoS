---
service: "aws-external"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 2
---

# Flows

Process and flow documentation for aws-external.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [AWS Alert Routing to Cloud SRE](aws-alert-routing.md) | event-driven | AWS control plane generates an alert or incident signal | Routes AWS third-party alerts to Cloud SRE via ownership metadata and runbook references |
| [AWS Incident Response](aws-incident-response.md) | event-driven | Production incident detected in AWS-hosted infrastructure | Guides Cloud SRE and IMOC through the steps for triaging, escalating, and resolving AWS platform incidents |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

Both flows span multiple Continuum platform services. The alert routing flow is modelled as a dynamic view (`awsAlertRoutingFlow`) in the architecture DSL but is currently disabled in federation because `continuumAwsControlPlane` and `continuumCloudSreOperations` are stub-only containers not resolved in the central model. See [Architecture Context](../architecture-context.md) for details.
