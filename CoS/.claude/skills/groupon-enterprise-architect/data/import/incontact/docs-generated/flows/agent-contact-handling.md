---
service: "incontact"
title: "Agent Contact Handling"
generated: "2026-03-03"
type: flow
flow_name: "agent-contact-handling"
flow_type: synchronous
trigger: "Customer initiates inbound contact (voice call, chat, or digital channel)"
participants:
  - "continuumIncontactService"
  - "global_support_systems"
architecture_ref: "components-incontact-repo-component"
---

# Agent Contact Handling

## Summary

When a customer initiates contact with Groupon support (via phone, chat, or digital channel), InContact receives and routes the contact to an available GSS agent. The agent uses the InContact agent desktop to handle the interaction. Upon resolution, relevant contact data flows through to the `global_support_systems` service for tracking and reporting. This is the primary operational flow for InContact within Groupon's GSS domain.

## Trigger

- **Type**: user-action
- **Source**: Customer contact initiation (inbound call to GSS phone number, chat widget, or digital channel entry point managed by InContact)
- **Frequency**: On-demand — continuous during GSS operating hours

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Customer | Initiates contact with Groupon support | External actor |
| InContact SaaS Platform | Routes contact, manages agent queue, provides agent desktop | `continuumIncontactService` |
| GSS Agent | Handles customer interaction via InContact agent desktop | Internal actor |
| Global Support Systems | Receives contact data for tracking and CRM integration | `global_support_systems` (stub-only) |

## Steps

1. **Customer initiates contact**: Customer places a call, starts a chat, or engages via a digital channel connected to InContact.
   - From: `Customer`
   - To: `continuumIncontactService` (InContact SaaS)
   - Protocol: Telephony (PSTN/VoIP) or HTTPS (web chat/digital)

2. **InContact routes contact to agent queue**: InContact applies routing rules (skills-based routing, IVR, or queue assignment) to direct the contact to the appropriate GSS agent pool.
   - From: `continuumIncontactService`
   - To: GSS agent queue within InContact
   - Protocol: Internal SaaS routing (vendor-managed)

3. **Agent accepts contact**: An available GSS agent accepts the contact through the InContact agent desktop application.
   - From: InContact agent queue
   - To: GSS Agent desktop
   - Protocol: InContact SaaS agent interface

4. **Agent handles interaction**: The GSS agent communicates with the customer, accesses support tools, and works toward resolution.
   - From: GSS Agent
   - To: `Customer`
   - Protocol: Telephony (voice) or HTTPS (chat/digital)

5. **Contact data recorded**: Upon contact completion, InContact records interaction data (duration, disposition, agent, outcome).
   - From: `continuumIncontactService`
   - To: `global_support_systems` (dependency — stub-only; exact mechanism not elaborated)
   - Protocol: Unknown (stub-only in architecture DSL)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No agents available | InContact queues customer contact with hold messaging | Customer waits in queue; contact handled when agent becomes available |
| InContact SaaS outage | SaaS platform unavailable; vendor SLA applies | GSS agents cannot handle contacts; escalate to vendor support and PagerDuty PN9TCKJ |
| Contact dropped mid-interaction | InContact reconnect/callback mechanisms (vendor-managed) | Customer may need to re-initiate contact |
| `global_support_systems` unavailable | Contact handling continues in InContact; data sync may be delayed | Risk of contact data loss if outage is prolonged |

## Sequence Diagram

```
Customer          -> InContact SaaS:       Initiates contact (call/chat/digital)
InContact SaaS    -> Agent Queue:          Routes contact via skills-based routing
Agent Queue       -> GSS Agent Desktop:    Presents contact to available agent
GSS Agent         -> Customer:             Handles interaction
GSS Agent         -> InContact SaaS:       Closes contact with disposition
InContact SaaS    -> global_support_systems: Records contact data (stub-only)
```

## Related

- Architecture dynamic view: No dynamic views modelled (`views/dynamics/no-dynamics.dsl`)
- Related flows: [Service Dependency Integration](service-dependency-integration.md)
- Architecture context: [Architecture Context](../architecture-context.md)
