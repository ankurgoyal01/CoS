---
service: "incontact"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 2
---

# Flows

Process and flow documentation for InContact.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Agent Contact Handling](agent-contact-handling.md) | synchronous | Customer initiates contact (call, chat, or digital channel) | An inbound customer contact is routed through InContact to a GSS agent for resolution |
| [Service Dependency Integration](service-dependency-integration.md) | synchronous | Internal Continuum service interaction | InContact interacts with declared internal dependencies (`ogwall`, `global_support_systems`) to fulfil support operations |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

InContact participates in cross-service flows with `ogwall` and `global_support_systems` within the Continuum platform. These relationships are declared in the architecture DSL but are currently stub-only; full flow elaboration is pending. See the central architecture model for the Continuum platform context view (`containers-continuumSystem`).

> Note: No dynamic flow views are modelled for InContact in the architecture DSL (`views/dynamics/no-dynamics.dsl`). The flows documented here are derived from `.service.yml` dependency declarations and the service's domain context.
