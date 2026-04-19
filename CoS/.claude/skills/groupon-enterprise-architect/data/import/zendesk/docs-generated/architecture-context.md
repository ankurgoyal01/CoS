---
service: "zendesk"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumZendesk]
---

# Architecture Context

## System Context

Zendesk sits within the Continuum Platform as an externally hosted SaaS dependency consumed by Groupon's Global Support Systems (GSS). It is modelled as a container (`continuumZendesk`) inside the `continuumSystem` software system. Groupon systems interact with Zendesk exclusively through its API integration component (`zendeskApi`). The service has no internally hosted application code — all capabilities are accessed via API calls to Zendesk's managed SaaS environment. Key relationships connect Zendesk to OgWall (for identity), Cyclops (internal tooling), Salesforce (CRM synchronization), and the Global Support Systems service (support workflows).

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Zendesk | `continuumZendesk` | SaaS Platform | SaaS Platform | N/A | SaaS support platform integrated by Groupon Global Support Systems for case and ticket operations |

## Components by Container

### Zendesk (`continuumZendesk`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Zendesk API Integration | Integration surface used by Groupon systems to read and write support data | SaaS API |
| Ticketing and Case Management | Core Zendesk ticket and case lifecycle capabilities consumed by support workflows | SaaS Application |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `zendeskApi` | `zendeskTicketing` | Routes API calls to ticket and case workflows | Internal SaaS |
| `continuumZendesk` | `continuumOgwallService` | Integrates with OgWall for identity and user management | API |
| `continuumZendesk` | `cyclops` | Integrates with Cyclops internal tooling | API |
| `continuumZendesk` | `salesForce` | Synchronizes support and CRM information | API |
| `continuumZendesk` | `continuumGlobalSupportSystems` | Supports global support workflows | API |

## Architecture Diagram References

- Component: `components-zendesk`
- Dynamic flow: `dynamic-zendesk-ticket-flow`
