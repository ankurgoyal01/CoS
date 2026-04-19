---
service: "raas_c1"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 2
---

# Flows

Process and flow documentation for RAAS C1 (Redis as a Service — C1).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Service Portal Registration and Routing](service-portal-registration.md) | synchronous | OCT tooling or BASTIC ticket creation | How internal tooling resolves and routes C1 Redis operational requests through the Service Portal entry |
| [Operational Request Submission](operational-request-submission.md) | synchronous | Operator action | How engineers submit operational requests for C1 Redis nodes through the registered Service Portal channels |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The `raas_c1` Service Portal entry itself participates in no multi-step cross-service flows. C1 Redis node management flows — cluster health monitoring, database provisioning, Kubernetes config sync — are executed by the `raas` platform. See the [RaaS flows documentation](../../raas/docs-generated/flows/index.md) for those flows.
