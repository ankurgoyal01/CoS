---
service: "killbill-subscription-programs-plugin"
title: "Subscription Entitlement Check"
generated: "2026-03-03"
type: flow
flow_name: "subscription-entitlement-check"
flow_type: synchronous
trigger: "Kill Bill entitlement API hook (before subscription creation/modification)"
participants:
  - "continuumSubscriptionProgramsPlugin"
architecture_ref: "components-continuum-subscription-programs-plugin"
---

# Subscription Entitlement Check

## Summary

The plugin registers a `SPEntitlementPluginApi` with the Kill Bill OSGI framework. Kill Bill invokes this hook before processing entitlement operations (subscription creation, modification, cancellation) to allow the plugin to intercept and enforce program-specific rules. This is a synchronous in-process call that runs within the Kill Bill entitlement lifecycle. If the plugin finds that the tenant listener is disabled or that a specific condition should block entitlement, it can veto the operation.

## Trigger

- **Type**: api-call (Kill Bill in-process entitlement plugin API hook)
- **Source**: Kill Bill entitlement engine, before committing subscription lifecycle operations
- **Frequency**: Per subscription creation or modification request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kill Bill Entitlement Engine | Initiates hook invocation before processing subscription operations | Kill Bill platform (in-process) |
| `SPEntitlementPluginApi` | Evaluates program-specific entitlement rules and signals allow/veto | `continuumSubscriptionProgramsPlugin` |
| `SPConfigurationHandler` | Provides per-tenant configuration used in entitlement decisions | `continuumSubscriptionProgramsPlugin` |

## Steps

1. **Entitlement Operation Initiated**: A caller (API client or Kill Bill internal scheduler) initiates a subscription create/modify/cancel operation via the Kill Bill entitlement API.
   - From: External caller or Kill Bill scheduler
   - To: Kill Bill entitlement engine (in-process)
   - Protocol: REST/HTTP (Kill Bill API) or direct

2. **Plugin Hook Invoked**: Kill Bill entitlement engine calls `SPEntitlementPluginApi.priorCall()` (or equivalent hook method) before committing the operation.
   - From: Kill Bill entitlement engine
   - To: `SPEntitlementPluginApi`
   - Protocol: In-process Java call (OSGi EntitlementPluginApi)

3. **Check Tenant Configuration**: Plugin reads the per-tenant `SPConfiguration` (via `SPConfigurationHandler`) to determine if entitlement interception is applicable.
   - From: `SPEntitlementPluginApi`
   - To: `SPConfigurationHandler`
   - Protocol: direct

4. **Evaluate Entitlement Rules**: Plugin evaluates program-specific rules (e.g., whether a `SPBaseEntitlementWithAddOnsSpecifier` meets subscription program requirements).
   - From: `SPEntitlementPluginApi`
   - To: Kill Bill Subscription/Account API (in-process)
   - Protocol: direct

5. **Return Allow or Veto**: Plugin returns an `EntitlementContext` result allowing the operation to proceed or vetoing it with an error message.
   - From: `SPEntitlementPluginApi`
   - To: Kill Bill entitlement engine
   - Protocol: In-process return value

6. **Entitlement Operation Committed or Rejected**: Kill Bill proceeds with the subscription operation (if allowed) or returns an error to the original caller (if vetoed).
   - From: Kill Bill entitlement engine
   - To: External caller
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Configuration not found for tenant | Plugin defaults to allowing the operation | Subscription operation proceeds |
| Plugin throws exception | Kill Bill treats as veto or re-throws depending on configuration | Operation may be rejected; logged as error |
| Listener disabled for tenant | Plugin allows operation without custom logic | Default Kill Bill entitlement behavior applies |

## Sequence Diagram

```
Caller -> KillBillEntitlementAPI: POST /1.0/kb/subscriptions (create/modify/cancel)
KillBillEntitlementAPI -> SPEntitlementPluginApi: priorCall(entitlementContext, properties)
SPEntitlementPluginApi -> SPConfigurationHandler: getConfigurable(tenantId)
SPEntitlementPluginApi -> KillBillAPI: read account/subscription state if needed
SPEntitlementPluginApi --> KillBillEntitlementAPI: EntitlementContext (ALLOW or VETO)
KillBillEntitlementAPI -> KillBillSubscriptionEngine: commit operation (if ALLOW)
KillBillEntitlementAPI --> Caller: HTTP 201 (success) or 400 (vetoed)
```

## Related

- Architecture dynamic view: `components-continuum-subscription-programs-plugin`
- Related flows: [Invoice-Driven Order Creation](invoice-order-creation.md)
