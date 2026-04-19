---
service: "ORR"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for ORR (Operational Readiness Review) Audit Toolkit.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Host Monitor Audit by Service](host-monitor-audit-by-service.md) | synchronous | Manual CLI invocation with service name argument | Audits all on-prem host-level monitor notify recipients for a single named service and reports pageability status |
| [VIP Monitor Audit by Service](vip-monitor-audit-by-service.md) | synchronous | Manual CLI invocation with service name argument | Traverses host-to-VIP topology and audits VIP monitor notify recipients for a single named service |
| [Fleet-Wide Monitor Audit](fleet-wide-monitor-audit.md) | batch | Manual CLI invocation with no arguments | Generates fleet-wide host and VIP monitor recipient reports across all production services |
| [Orphaned Host Detection](orphaned-host-detection.md) | batch | Manual CLI invocation with no arguments | Scans all ops-config host YAML files to identify production hosts with no service mapping |
| [Autoscoring Compliance Audit](autoscoring-compliance-audit.md) | synchronous | Manual CLI invocation with no arguments | Queries Service Portal to list all Live services that have ORR autoscoring disabled |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 3 |

## Cross-Service Flows

The service monitoring audit flow is modelled in the central architecture dynamic view `dynamic-hostNotifyAuditByService-monitoring-hostsWithoutServiceAudit-flow`, which captures the `continuumOrrAuditToolkit` interactions with `servicePortal`, `opsConfigRepository`, `rawGithubContent`, and `lbmsApi` during an audit run.
