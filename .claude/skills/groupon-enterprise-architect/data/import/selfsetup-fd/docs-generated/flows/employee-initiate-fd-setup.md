---
service: "selfsetup-fd"
title: "Employee Initiates F&D Setup"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "employee-initiate-fd-setup"
flow_type: synchronous
trigger: "Groupon EMEA employee submits an opportunity ID in the self-setup wizard"
participants:
  - "grouponEmployee_51c9"
  - "ssuWebControllers"
  - "selfsetupFd_ssuSalesforceClient"
  - "ssuCappingService"
  - "ssuQueueRepository"
  - "continuumEmeaBtSelfSetupFdDb"
architecture_ref: "dynamic-ssu_fd_self_setup_flow"
---

# Employee Initiates F&D Setup

## Summary

A Groupon EMEA employee opens the selfsetup-fd wizard and submits a Salesforce opportunity ID to begin the Food & Drinks merchant Booking Tool setup process. The service fetches the opportunity from Salesforce, validates deal eligibility via the capping service, and if valid, persists a setup job to the MySQL queue for async processing. The employee receives a confirmation that the job has been queued.

## Trigger

- **Type**: user-action
- **Source**: Groupon EMEA employee (`grouponEmployee_51c9`) submits the setup wizard form via browser
- **Frequency**: On-demand (per merchant setup request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Groupon EMEA Employee | Initiates the request via browser | `grouponEmployee_51c9` |
| Web Controllers | Receives HTTP request, orchestrates the flow | `ssuWebControllers` |
| Salesforce Client | Fetches opportunity and merchant details from Salesforce | `selfsetupFd_ssuSalesforceClient` |
| Capping Calculator | Validates capacity and deal eligibility rules | `ssuCappingService` |
| Queue Repository | Persists the validated setup job to MySQL | `ssuQueueRepository` |
| SSU FD Database | Stores the enqueued setup job | `continuumEmeaBtSelfSetupFdDb` |

## Steps

1. **Receives setup request**: Employee submits opportunity ID via the wizard UI.
   - From: `grouponEmployee_51c9`
   - To: `ssuWebControllers`
   - Protocol: HTTPS (browser POST)

2. **Fetches opportunity details**: Web Controllers delegate to the Salesforce Client to retrieve the opportunity and merchant data via SOQL/REST.
   - From: `ssuWebControllers`
   - To: `selfsetupFd_ssuSalesforceClient`
   - Protocol: direct (in-process)

3. **Queries Salesforce**: Salesforce Client calls the Salesforce REST API with the opportunity ID.
   - From: `selfsetupFd_ssuSalesforceClient`
   - To: `salesForce`
   - Protocol: HTTPS

4. **Returns opportunity data**: Salesforce returns opportunity and merchant details.
   - From: `salesForce`
   - To: `selfsetupFd_ssuSalesforceClient` -> `ssuWebControllers`
   - Protocol: HTTPS

5. **Validates deal eligibility**: Web Controllers invoke the Capping Calculator with the opportunity data to check capacity and validation rules.
   - From: `ssuWebControllers`
   - To: `ssuCappingService`
   - Protocol: direct (in-process)

6. **Enqueues setup job**: If validation passes, Web Controllers write the setup job to the MySQL queue via Queue Repository.
   - From: `ssuWebControllers`
   - To: `ssuQueueRepository`
   - Protocol: direct (in-process)

7. **Persists job to database**: Queue Repository writes the job record to `continuumEmeaBtSelfSetupFdDb`.
   - From: `ssuQueueRepository`
   - To: `continuumEmeaBtSelfSetupFdDb`
   - Protocol: MySQL

8. **Returns confirmation**: Web Controllers respond to the employee with a queued-confirmation page.
   - From: `ssuWebControllers`
   - To: `grouponEmployee_51c9`
   - Protocol: HTTPS (browser response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce returns no opportunity | Web Controllers surface error to employee | Setup wizard displays "opportunity not found" message; no job enqueued |
| Salesforce connectivity failure | Request fails; exception surfaced by `selfsetupFd_ssuSalesforceClient` | Employee sees error page; retry manually |
| Capping validation fails | `ssuCappingService` returns validation failure | Employee sees ineligibility reason; no job enqueued |
| MySQL write failure | `ssuQueueRepository` throws exception | Job not enqueued; employee sees error; no partial state |

## Sequence Diagram

```
grouponEmployee_51c9  ->  ssuWebControllers: POST setup wizard form (opportunity ID)
ssuWebControllers     ->  selfsetupFd_ssuSalesforceClient: Reads opportunity and merchant details
selfsetupFd_ssuSalesforceClient -> salesForce: HTTPS SOQL/REST query (opportunity ID)
salesForce            --> selfsetupFd_ssuSalesforceClient: Opportunity + merchant data
selfsetupFd_ssuSalesforceClient --> ssuWebControllers: Opportunity data
ssuWebControllers     ->  ssuCappingService: Calculates capping and validation
ssuCappingService     --> ssuWebControllers: Validation result (pass/fail)
ssuWebControllers     ->  ssuQueueRepository: Reads/writes setup queue (enqueue job)
ssuQueueRepository    ->  continuumEmeaBtSelfSetupFdDb: MySQL INSERT (job record)
continuumEmeaBtSelfSetupFdDb --> ssuQueueRepository: OK
ssuQueueRepository    --> ssuWebControllers: Job enqueued
ssuWebControllers     --> grouponEmployee_51c9: Confirmation page (job queued)
```

## Related

- Architecture dynamic view: `dynamic-ssu_fd_self_setup_flow`
- Related flows: [Validate F&D Deal Eligibility](validate-fd-deal-eligibility.md), [Async Configure BT Options](async-configure-bt-options.md)
