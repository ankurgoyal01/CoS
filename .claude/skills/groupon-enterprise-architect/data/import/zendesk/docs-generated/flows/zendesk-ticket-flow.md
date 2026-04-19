---
service: "zendesk"
title: "Zendesk Ticket Flow"
generated: "2026-03-03"
type: flow
flow_name: "zendesk-ticket-flow"
flow_type: synchronous
trigger: "API call from a Groupon internal service requesting ticket or case operation"
participants:
  - "zendeskApi"
  - "zendeskTicketing"
architecture_ref: "dynamic-zendesk-ticket-flow"
---

# Zendesk Ticket Flow

## Summary

This flow describes the internal processing path within the `continuumZendesk` container when a Groupon system submits a support ticket request. The `zendeskApi` integration component receives inbound API calls from Groupon services and routes them to the `zendeskTicketing` component, which executes the ticket or case lifecycle operation within Zendesk's SaaS platform. This flow is documented as a dynamic view (`dynamic-zendesk-ticket-flow`) in the architecture DSL.

## Trigger

- **Type**: api-call
- **Source**: Groupon internal service (e.g., Global Support Systems service or commerce event handler) calling the Zendesk REST API endpoint
- **Frequency**: On-demand, triggered by customer support events such as order issues, refund requests, or direct agent actions

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Zendesk API Integration | Receives inbound API requests from Groupon systems; validates and routes to ticketing operations | `zendeskApi` |
| Ticketing and Case Management | Executes ticket and case lifecycle operations (create, update, resolve) within Zendesk SaaS | `zendeskTicketing` |

## Steps

1. **Receive API Request**: A Groupon internal service submits a ticket operation (create, update, or resolve) to the Zendesk API Integration component.
   - From: Groupon internal service (e.g., `continuumGlobalSupportSystems`)
   - To: `zendeskApi`
   - Protocol: REST (HTTPS)

2. **Route to Ticketing**: The Zendesk API Integration component processes and routes the request to the Ticketing and Case Management component for execution.
   - From: `zendeskApi`
   - To: `zendeskTicketing`
   - Protocol: Internal SaaS

3. **Execute Ticket Operation**: The Ticketing and Case Management component creates, updates, or resolves the support ticket within Zendesk's SaaS data store.
   - From: `zendeskTicketing`
   - To: Zendesk SaaS managed data store
   - Protocol: Internal SaaS

4. **Return Result**: The result of the ticket operation is returned from `zendeskTicketing` back through `zendeskApi` to the originating Groupon service.
   - From: `zendeskTicketing`
   - To: `zendeskApi`
   - Protocol: Internal SaaS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Zendesk API unavailable | No evidence found in codebase of a specific retry or circuit breaker strategy | Ticket operation fails; originating Groupon service receives error response |
| Invalid ticket data | Zendesk API returns validation error | API integration layer returns error to calling service |
| Authentication failure | Zendesk API returns 401/403 | Operation fails; GSS team alerted to investigate credentials |

## Sequence Diagram

```
GrouponService -> zendeskApi: Submit ticket operation (REST/HTTPS)
zendeskApi -> zendeskTicketing: Route ticket/case operation
zendeskTicketing -> zendeskTicketing: Execute create/update/resolve
zendeskTicketing --> zendeskApi: Return operation result
zendeskApi --> GrouponService: Return success or error response
```

## Related

- Architecture dynamic view: `dynamic-zendesk-ticket-flow`
- Related flows: [Salesforce CRM Sync](salesforce-crm-sync.md)
