---
service: "cs-api"
title: "Convert to Cash Refund"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "convert-to-cash-refund"
flow_type: synchronous
trigger: "Agent initiates a convert-to-cash (Groupon Bucks) refund action"
participants:
  - "customerSupportAgent"
  - "continuumCsApiService"
  - "csApi_apiResources"
  - "authModule"
  - "serviceClients"
  - "continuumOrdersService"
  - "continuumIncentivesService"
architecture_ref: "dynamic-cs-api"
---

# Convert to Cash Refund

## Summary

This flow enables a CS agent to convert a customer's refund into Groupon Bucks (the convert-to-cash operation). CS API first validates the order's eligibility by querying the Orders Service, then calls the Incentives Service to execute the conversion. This is a sensitive financial operation that requires the agent to have the appropriate ability (resolved via [Agent Ability Check](agent-ability-check.md)) before the action is permitted.

## Trigger

- **Type**: user-action
- **Source**: Cyclops CS agent web application (POST `/convert-to-cash`)
- **Frequency**: On-demand; initiated by the agent for specific customer refund cases

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cyclops CS Agent App | Initiates convert-to-cash action | `customerSupportAgent` |
| CS API Service | Orchestrates eligibility check and conversion | `continuumCsApiService` |
| API Resources | Validates request and agent authorization | `csApi_apiResources` |
| Auth/JWT Module | Verifies agent identity and abilities | `authModule` |
| Service Clients | Issues HTTP calls to Orders and Incentives | `serviceClients` |
| Orders Service | Validates order eligibility for conversion | `continuumOrdersService` |
| Incentives Service | Executes the Groupon Bucks credit | `continuumIncentivesService` |

## Steps

1. **Receive convert-to-cash request**: Cyclops sends POST `/convert-to-cash` with order ID and refund amount.
   - From: `customerSupportAgent`
   - To: `csApi_apiResources`
   - Protocol: REST / HTTPS

2. **Verify agent ability**: `authModule` confirms the agent holds the convert-to-cash ability (resolved from roles).
   - From: `csApi_apiResources`
   - To: `authModule`
   - Protocol: Internal

3. **Validate order eligibility**: `serviceClients` queries `continuumOrdersService` to confirm the order is eligible for conversion.
   - From: `serviceClients`
   - To: `continuumOrdersService`
   - Protocol: HTTP

4. **Execute incentive conversion**: `serviceClients` calls `continuumIncentivesService` to credit the refund amount as Groupon Bucks.
   - From: `serviceClients`
   - To: `continuumIncentivesService`
   - Protocol: HTTP

5. **Return confirmation**: `csApi_apiResources` returns the conversion result (transaction ID, credit amount) to Cyclops.
   - From: `csApi_apiResources`
   - To: `customerSupportAgent`
   - Protocol: REST / HTTPS / JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Agent lacks convert-to-cash ability | `authModule` / ability check fails | 403 returned; action blocked in Cyclops |
| Order not eligible for conversion | Orders Service returns ineligibility | 422 returned; agent shown eligibility message |
| Incentives Service unavailable | HTTP call fails | 503 returned; conversion not executed; no funds credited |
| Incentives Service returns error | Error response propagated | 500 returned; agent advised to retry |

## Sequence Diagram

```
CyclopsUI      -> csApi_apiResources  : POST /convert-to-cash { orderId, amount }
csApi_apiResources -> authModule      : Verify convert-to-cash ability
authModule --> csApi_apiResources     : Ability confirmed
csApi_apiResources -> serviceClients  : Validate order eligibility
serviceClients -> continuumOrdersService : GET order eligibility (HTTP)
continuumOrdersService --> serviceClients : Eligible
csApi_apiResources -> serviceClients  : Execute conversion
serviceClients -> continuumIncentivesService : POST convert (HTTP)
continuumIncentivesService --> serviceClients : { transactionId, creditsApplied }
serviceClients --> csApi_apiResources : Conversion result
csApi_apiResources --> CyclopsUI      : 200 { transactionId, creditsApplied }
```

## Related

- Architecture dynamic view: `dynamic-cs-api` (not yet defined in DSL)
- Related flows: [Agent Ability Check](agent-ability-check.md), [Deal and Order Inquiry](deal-order-inquiry.md)
