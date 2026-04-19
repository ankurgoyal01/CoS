---
service: "lavatoryRunner"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Lavatory Runner.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Scheduled Artifact Purge](scheduled-artifact-purge.md) | scheduled | Host cron job | Full end-to-end flow: cron triggers the container, policies are loaded and evaluated, purge candidates are identified and deleted from Artifactory |
| [Docker Conveyor Retention Policy](docker-conveyor-retention.md) | batch | Cron-triggered container invocation | Applies the `docker-conveyor` policy: removes images older than 30 days, trims repositories beyond 20 tags, preserves items downloaded within 90 days, respects path-based whitelist |
| [Docker Conveyor Snapshots Retention Policy](docker-conveyor-snapshots-retention.md) | batch | Cron-triggered container invocation | Applies the `docker-conveyor-snapshots` policy: removes snapshot images older than 7 days and trims repositories to a maximum of 10 tags |
| [Integration Test Flow](integration-test-flow.md) | batch | Jenkins CI pipeline | Spins up a local Artifactory Pro container, seeds it with fixture data at known ages, runs the runner, and asserts expected artifact counts |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 4 |

## Cross-Service Flows

All Lavatory Runner flows are self-contained: the service connects directly to Artifactory REST APIs without routing through other Groupon services. The purge outcome is observable cross-service only through Splunk log aggregation (`index=prod_ops sourcetype=lavatory`) and Wavefront metrics.
