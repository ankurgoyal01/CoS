---
service: "akamai-cdn"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 1
---

# Flows

Process and flow documentation for Akamai CDN.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Akamai CDN Operations Flow](cdn-operations-flow.md) | synchronous | Manual operator action or automated configuration tooling | Applies and verifies CDN configuration changes (property rules, caching policies, routing settings) from the Configuration Management component to the Akamai edge platform, with operational signals published to the Observability component |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The Akamai CDN Operations Flow is modeled as a dynamic view in the central architecture model under the `continuumSystem`. It spans the `continuumAkamaiCdn` container and the external `akamai` software system.

Architecture dynamic view reference: `dynamic-akamai-cdn-operations-flow`
