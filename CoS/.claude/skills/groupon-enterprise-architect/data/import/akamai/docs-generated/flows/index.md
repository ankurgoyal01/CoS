---
service: "akamai"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 1
---

# Flows

Process and flow documentation for Akamai Product Security.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [WAF and Bot Management Security Enforcement](waf-bot-management-enforcement.md) | synchronous | Inbound HTTP/HTTPS request to Groupon consumer or merchant platform | Akamai edge evaluates every inbound request against WAF rules and bot management policies before forwarding to Groupon origin |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The WAF and bot management enforcement flow is a foundational cross-service concern: all inbound traffic to the Continuum platform passes through the Akamai edge before reaching any Groupon origin service. The `akamai-cdn` service (`continuumAkamaiCdn`) manages the complementary CDN delivery side of the same Akamai platform; see the central architecture dynamic view `dynamic-akamai-cdn-operations-flow` for CDN operations context.

> Note: The dynamics DSL in the akamai repository contains no evidence-backed runtime flows (`// No evidence-backed runtime flows detected in this repository`). The flow documented here is derived from the service description, architecture model relationships, and `.service.yml` configuration, consistent with documented Akamai platform behavior.
