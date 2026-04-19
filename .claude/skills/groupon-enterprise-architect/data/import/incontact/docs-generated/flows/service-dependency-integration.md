---
service: "incontact"
title: "Service Dependency Integration"
generated: "2026-03-03"
type: flow
flow_name: "service-dependency-integration"
flow_type: synchronous
trigger: "InContact requires data or capability from an internal Continuum service"
participants:
  - "continuumIncontactService"
  - "ogwall"
  - "global_support_systems"
architecture_ref: "components-incontact-repo-component"
---

# Service Dependency Integration

## Summary

InContact declares dependencies on two internal Continuum platform services: `ogwall` and `global_support_systems`. These dependencies are registered in the service's `.service.yml` and reflected in the architecture DSL. This flow documents what is known about InContact's integration with these internal services. Both relationships are currently marked as stub-only in the architecture model, meaning the specific protocols, data exchanged, and interaction patterns have not yet been fully elaborated.

## Trigger

- **Type**: api-call or event (exact mechanism not yet elaborated — stub-only in DSL)
- **Source**: InContact SaaS platform or a GSS agent action requiring internal Continuum data
- **Frequency**: On-demand during GSS operations

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| InContact | Initiates dependency call to access internal Continuum capabilities | `continuumIncontactService` |
| ogwall | Internal Continuum dependency — exact role not yet elaborated | `ogwall` |
| Global Support Systems | Internal Continuum dependency providing CRM and support data capabilities | `global_support_systems` |

## Steps

1. **InContact requires internal data**: During a support operation, InContact or a GSS process requires data or capability from an internal Continuum service (`ogwall` or `global_support_systems`).
   - From: `continuumIncontactService`
   - To: `ogwall` or `global_support_systems`
   - Protocol: Unknown (stub-only — not yet elaborated in architecture DSL)

2. **Internal service responds**: The target Continuum service processes the request and returns data or confirmation.
   - From: `ogwall` or `global_support_systems`
   - To: `continuumIncontactService`
   - Protocol: Unknown (stub-only)

3. **InContact uses response**: InContact incorporates the returned data into the ongoing GSS support operation (e.g., enriching agent view, updating CRM record, or routing decision).
   - From: `continuumIncontactService`
   - To: GSS Agent / InContact internal process
   - Protocol: Internal SaaS platform (vendor-managed)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `ogwall` unavailable | Unknown — not elaborated in architecture DSL | Operational procedures to be defined by service owner |
| `global_support_systems` unavailable | Unknown — not elaborated in architecture DSL | Operational procedures to be defined by service owner |
| Integration protocol failure | Unknown — not elaborated in architecture DSL | Escalate to GSS team via Slack CFED5CCSV or PagerDuty PN9TCKJ |

## Sequence Diagram

```
InContact SaaS  -> ogwall:                  Requests internal capability (stub-only)
ogwall          --> InContact SaaS:         Returns response (stub-only)
InContact SaaS  -> global_support_systems:  Requests support data (stub-only)
global_support_systems --> InContact SaaS:  Returns CRM/support data (stub-only)
InContact SaaS  -> GSS Agent Desktop:       Enriches agent view with internal data
```

> All interactions marked "stub-only" are declared in `architecture/models/relations.dsl` but have not been elaborated with actual protocol, payload, or data-flow details. The GSS team (owner: flueck, gss@groupon.com) should elaborate these relationships in a future architecture update.

## Related

- Architecture dynamic view: No dynamic views modelled (`views/dynamics/no-dynamics.dsl`)
- Related flows: [Agent Contact Handling](agent-contact-handling.md)
- Architecture context: [Architecture Context](../architecture-context.md)
- Integrations: [Integrations](../integrations.md)
