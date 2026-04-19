---
service: "nifi-3pip"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Nifi - Third Party Inventory.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [NiFi Node Bootstrap and Startup](nifi-node-startup.md) | synchronous | Container start | Entrypoint script configures NiFi properties and launches the NiFi node process |
| [Cluster Formation and Leader Election](cluster-formation.md) | event-driven | Node startup | NiFi nodes register with ZooKeeper and elect a cluster coordinator |
| [Third-Party Inventory Ingestion](inventory-ingestion.md) | batch | Operator-triggered / scheduled via NiFi UI | NiFi flow processes and routes third-party inventory data |
| [Node Health Check](node-health-check.md) | synchronous | Kubernetes probe | Health check script queries the NiFi cluster API and validates node connectivity |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

No cross-service dynamic views are currently defined in the nifi-3pip architecture DSL (`views/dynamics.dsl` is empty). The cluster-internal flows between `nifiNode1`, `nifiNode2`, `nifiNode3`, and `zookeeper` are the primary modeled interactions. Downstream integration with Continuum services consuming ingested inventory data is tracked in the central architecture model.
