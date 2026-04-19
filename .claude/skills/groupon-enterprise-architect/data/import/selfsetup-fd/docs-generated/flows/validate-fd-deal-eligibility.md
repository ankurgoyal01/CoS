---
service: "selfsetup-fd"
title: "Validate F&D Deal Eligibility"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "validate-fd-deal-eligibility"
flow_type: synchronous
trigger: "Called by Web Controllers during setup wizard submission, after opportunity data is fetched from Salesforce"
participants:
  - "ssuWebControllers"
  - "ssuCappingService"
  - "selfsetupFd_ssuSalesforceClient"
architecture_ref: "dynamic-ssu_fd_self_setup_flow"
---

# Validate F&D Deal Eligibility

## Summary

Before any Booking Tool setup job is enqueued, the service runs a synchronous eligibility check against the fetched Salesforce opportunity. The Capping Calculator applies capacity limits and business validation rules to determine whether the merchant deal qualifies for BT self-setup. If validation passes, the flow returns control to the initiating flow to proceed with enqueueing. If it fails, the employee is shown an ineligibility reason and no job is created.

## Trigger

- **Type**: api-call (internal)
- **Source**: `ssuWebControllers` invokes `ssuCappingService` after receiving Salesforce opportunity data
- **Frequency**: Once per setup wizard submission (on-demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Web Controllers | Orchestrates validation; passes opportunity data and receives pass/fail result | `ssuWebControllers` |
| Capping Calculator | Applies capacity limits and deal validation rules | `ssuCappingService` |
| Salesforce Client | Provides opportunity context (fetched in preceding step) | `selfsetupFd_ssuSalesforceClient` |

## Steps

1. **Passes opportunity data to Capping Calculator**: Web Controllers call `ssuCappingService` with the opportunity and merchant details retrieved from Salesforce.
   - From: `ssuWebControllers`
   - To: `ssuCappingService`
   - Protocol: direct (in-process)

2. **Evaluates capacity rules**: Capping Calculator checks whether the deal falls within configured capacity limits for F&D Booking Tool setups (e.g., merchant eligibility, booking slot availability, deal type constraints).
   - From: `ssuCappingService`
   - To: `ssuCappingService` (internal evaluation)
   - Protocol: direct

3. **Returns validation result**: Capping Calculator returns a pass or fail result with an optional reason to Web Controllers.
   - From: `ssuCappingService`
   - To: `ssuWebControllers`
   - Protocol: direct (in-process)

4. **Routes on result**:
   - If **pass**: Web Controllers proceed to enqueue the setup job (see [Employee Initiates F&D Setup](employee-initiate-fd-setup.md), step 6).
   - If **fail**: Web Controllers return an ineligibility message to the employee; flow terminates.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Capping rules cannot be evaluated (missing data) | `ssuCappingService` returns validation failure | Employee sees error; no job enqueued |
| Opportunity data is incomplete | Validation fails with missing-data reason | Employee is prompted to check the Salesforce opportunity |
| Unexpected exception in Capping Calculator | Exception propagates to Web Controllers | Employee sees error page; no job enqueued |

## Sequence Diagram

```
ssuWebControllers  ->  ssuCappingService: Calculates capping and validation (opportunity data)
ssuCappingService  --> ssuWebControllers: Validation result (pass / fail + reason)
ssuWebControllers  ->  ssuQueueRepository: (if pass) Enqueue setup job
ssuWebControllers  --> grouponEmployee_51c9: (if fail) Ineligibility reason displayed
```

## Related

- Architecture dynamic view: `dynamic-ssu_fd_self_setup_flow`
- Related flows: [Employee Initiates F&D Setup](employee-initiate-fd-setup.md), [Async Configure BT Options](async-configure-bt-options.md)
