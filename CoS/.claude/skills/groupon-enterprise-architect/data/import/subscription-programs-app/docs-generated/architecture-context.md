---
service: "subscription-programs-app"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumSubscriptionProgramsApp, continuumSubscriptionProgramsDb]
---

# Architecture Context

## System Context

Subscription Programs App lives inside the `continuumSystem` software system — Groupon's core commerce engine. It acts as the authoritative membership service for Groupon Select, sitting between consumer-facing frontends (MBNXT) and billing/loyalty infrastructure (KillBill, Incentive Service). Consumer membership requests flow in via the REST API; billing lifecycle events arrive as KillBill webhooks; processed membership state changes flow out as MBus events to downstream consumers.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Subscription Programs App | `continuumSubscriptionProgramsApp` | Service | Java, Dropwizard | JTier 5.14.1 | Dropwizard/JTier HTTP service exposing Select subscription APIs and Quartz-scheduled worker jobs |
| Subscription Programs DB | `continuumSubscriptionProgramsDb` | Database | MySQL | — | Stores subscriptions, memberships, incentive records, and program configuration (`mm_programs` schema) |

## Components by Container

### Subscription Programs App (`continuumSubscriptionProgramsApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `selectApi` | Exposes all HTTP endpoints for subscription program operations; routes requests to Membership Service | Dropwizard Resources |
| `membershipService` | Core business logic — membership state transitions, eligibility evaluation, incentive orchestration, event publishing | Java service layer |
| `subscriptionRepository` | Persistence layer — all reads and writes against the `mm_programs` MySQL database | JTier DaaS MySQL |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `selectApi` | `membershipService` | Invokes business logic for each API operation | Direct (in-process) |
| `membershipService` | `subscriptionRepository` | Reads and writes membership, subscription, and incentive data | Direct (in-process) |
| `continuumSubscriptionProgramsApp` | `continuumSubscriptionProgramsDb` | Reads/writes subscriptions, memberships, incentives | JDBC / MySQL |

## Architecture Diagram References

- System context: `contexts-subscription-programs-app`
- Container: `containers-subscription-programs-app`
- Component: `components-subscription-programs-app-components`
