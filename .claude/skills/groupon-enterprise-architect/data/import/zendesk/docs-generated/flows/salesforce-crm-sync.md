---
service: "zendesk"
title: "Salesforce CRM Sync"
generated: "2026-03-03"
type: flow
flow_name: "salesforce-crm-sync"
flow_type: synchronous
trigger: "Ticket update or resolution in Zendesk triggers outbound CRM sync to Salesforce"
participants:
  - "continuumZendesk"
  - "salesForce"
architecture_ref: "dynamic-zendesk-ticket-flow"
---

# Salesforce CRM Sync

## Summary

This flow describes how Zendesk synchronizes support case and ticket data with Salesforce CRM. When a support ticket is created, updated, or resolved in Zendesk, the integration between `continuumZendesk` and `salesForce` pushes relevant case data to Salesforce so that sales and account management teams have a unified view of customer interactions alongside support history. This relationship is declared in the architecture DSL as `continuumZendesk -> salesForce "Synchronizes support/CRM information"`.

## Trigger

- **Type**: api-call (SaaS-to-SaaS integration trigger)
- **Source**: A ticket or case state change within Zendesk (e.g., ticket creation, status update, resolution) triggers the outbound Salesforce sync
- **Frequency**: On-demand, driven by ticket lifecycle events within Zendesk

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Zendesk | Source of support ticket and case data; initiates CRM sync | `continuumZendesk` |
| Salesforce | Target CRM system receiving synchronized support records | `salesForce` |

## Steps

1. **Ticket Event Occurs**: A support ticket is created, updated, or resolved within Zendesk's Ticketing and Case Management component.
   - From: `zendeskTicketing`
   - To: `continuumZendesk` (internal Zendesk SaaS trigger)
   - Protocol: Internal SaaS

2. **Trigger Salesforce Sync**: Zendesk's Salesforce integration connector detects the ticket event and prepares the CRM payload.
   - From: `continuumZendesk`
   - To: `salesForce`
   - Protocol: API (Salesforce REST or Bulk API via Zendesk connector)

3. **Update Salesforce Record**: Salesforce receives the sync payload and creates or updates the corresponding CRM case, contact, or account record.
   - From: Salesforce API
   - To: Salesforce CRM data store (managed by Salesforce SaaS)
   - Protocol: Internal Salesforce

4. **Confirm Sync**: Salesforce returns a confirmation to the Zendesk connector, completing the synchronization cycle.
   - From: `salesForce`
   - To: `continuumZendesk`
   - Protocol: API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce API unavailable | No evidence found in codebase; handled by Zendesk connector retry logic | CRM records may be stale; ticket data remains intact in Zendesk |
| Salesforce authentication failure | No evidence found in codebase of specific Groupon-configured handling | Sync fails; GSS team must investigate Salesforce connector credentials in Zendesk admin |
| Data mapping error | No evidence found in codebase | Sync fails for affected record; no impact on Zendesk ticket operations |

## Sequence Diagram

```
zendeskTicketing -> continuumZendesk: Ticket event (create/update/resolve)
continuumZendesk -> salesForce: Sync support/CRM data via API
salesForce -> salesForce: Create or update CRM record
salesForce --> continuumZendesk: Sync confirmation
```

## Related

- Architecture relationship: `continuumZendesk -> salesForce`
- Related flows: [Zendesk Ticket Flow](zendesk-ticket-flow.md)
- Integrations: [Integrations](../integrations.md)
