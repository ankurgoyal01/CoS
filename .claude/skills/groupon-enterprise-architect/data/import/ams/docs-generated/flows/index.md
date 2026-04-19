---
service: "ams"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 8
---

# Flows

Process and flow documentation for Audience Management Service (AMS).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Audience Creation and Persistence](audience-creation-persistence.md) | synchronous | API call (POST /audience/*) | Validates and persists a new audience definition with criteria |
| [Sourced Audience Calculation](sourced-audience-calculation.md) | asynchronous | Schedule or API trigger | Submits a Spark job to compute sourced audience membership |
| [Published Audience Publishing](published-audience-publishing.md) | asynchronous | Sourced audience job completion | Publishes computed audience to Kafka and multi-store targets |
| [Custom Query Execution](custom-query-execution.md) | synchronous | API call (POST /custom-query/*) | Executes a custom query against audience data and returns results |
| [Audience Schedule Execution](audience-schedule-execution.md) | scheduled | Cron schedule | Triggers audience compute jobs based on configured schedules |
| [Batch Optimization](batch-optimization.md) | batch | Scheduler / queue manager | Optimizes and deduplicates pending audience job queue |
| [Audience Criteria Resolution](audience-criteria-resolution.md) | synchronous | API call (GET /criteria, GET /ca-attributes/{id}) | Resolves and returns audience criteria and attribute definitions |
| [Audience Export Orchestration](audience-export-orchestration.md) | asynchronous | API call (POST /export/*) or job completion | Orchestrates audience data export to Bigtable, Cassandra, and MySQL |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 3 |

## Cross-Service Flows

- **Sourced Audience Calculation** and **Published Audience Publishing** span `continuumAudienceManagementService`, `livyGateway`, `kafkaBroker`, `bigtableCluster`, and `cassandraCluster`. See the central architecture dynamic view `dynamic-ams-audience-calculation`.
- **Audience Schedule Execution** coordinates with YARN for job monitoring across service boundaries.
- **Audience Export Orchestration** writes results to `bigtableCluster` and `cassandraCluster` via Spark jobs submitted through `livyGateway`.
