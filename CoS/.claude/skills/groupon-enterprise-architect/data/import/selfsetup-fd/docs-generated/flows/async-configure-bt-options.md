---
service: "selfsetup-fd"
title: "Async Configure BT Options"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "async-configure-bt-options"
flow_type: scheduled
trigger: "Cron job fires on a scheduled interval and processes pending setup jobs in the MySQL queue"
participants:
  - "ssuCronJobs"
  - "ssuQueueRepository"
  - "selfsetupFd_ssuSalesforceClient"
  - "selfsetupFd_ssuBookingToolClient"
  - "continuumEmeaBtSelfSetupFdDb"
architecture_ref: "dynamic-ssu_fd_self_setup_flow"
---

# Async Configure BT Options

## Summary

After an employee initiates a setup (see [Employee Initiates F&D Setup](employee-initiate-fd-setup.md)), the actual Booking Tool creation and configuration is handled asynchronously. The `ssuCronJobs` component runs on a scheduled cron interval, reads pending jobs from the MySQL queue, resolves merchant identifiers from Salesforce, and then calls the Booking Tool API to create and configure the merchant's BT instance. Job status is updated in the queue upon completion or failure.

## Trigger

- **Type**: schedule
- **Source**: Cron scheduler fires `ssuCronJobs` inside the container
- **Frequency**: Scheduled interval (exact cron expression not evidenced in inventory; defined in container cron configuration)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cron Jobs | Orchestrates the async processing loop | `ssuCronJobs` |
| Queue Repository | Reads pending jobs and updates job status | `ssuQueueRepository` |
| SSU FD Database | Persists queue state | `continuumEmeaBtSelfSetupFdDb` |
| Salesforce Client | Fetches merchant identifiers needed for BT setup | `selfsetupFd_ssuSalesforceClient` |
| Booking Tool Client | Calls Booking Tool API to create and configure BT instance | `selfsetupFd_ssuBookingToolClient` |

## Steps

1. **Cron fires**: The cron scheduler triggers `ssuCronJobs` on the configured interval.
   - From: cron scheduler
   - To: `ssuCronJobs`
   - Protocol: OS-level cron / process exec

2. **Reads pending queue jobs**: Cron Jobs reads the list of pending setup jobs from the MySQL queue via Queue Repository.
   - From: `ssuCronJobs`
   - To: `ssuQueueRepository`
   - Protocol: direct (in-process)

3. **Fetches jobs from database**: Queue Repository queries `continuumEmeaBtSelfSetupFdDb` for jobs in pending status.
   - From: `ssuQueueRepository`
   - To: `continuumEmeaBtSelfSetupFdDb`
   - Protocol: MySQL

4. **Fetches merchant identifiers**: For each pending job, Cron Jobs calls Salesforce Client to resolve the merchant identifiers required by the Booking Tool API.
   - From: `ssuCronJobs`
   - To: `selfsetupFd_ssuSalesforceClient`
   - Protocol: direct (in-process)

5. **Queries Salesforce**: Salesforce Client calls the Salesforce REST API to retrieve merchant identifiers.
   - From: `selfsetupFd_ssuSalesforceClient`
   - To: `salesForce`
   - Protocol: HTTPS

6. **Returns merchant identifiers**: Salesforce returns the resolved identifiers.
   - From: `salesForce`
   - To: `selfsetupFd_ssuSalesforceClient` -> `ssuCronJobs`
   - Protocol: HTTPS

7. **Creates Booking Tool setup**: Cron Jobs calls Booking Tool Client with the merchant identifiers and setup parameters to create and configure the BT instance.
   - From: `ssuCronJobs`
   - To: `selfsetupFd_ssuBookingToolClient`
   - Protocol: direct (in-process)

8. **Calls Booking Tool API**: Booking Tool Client makes HTTPS calls to the Booking Tool System to create the merchant BT instance.
   - From: `selfsetupFd_ssuBookingToolClient`
   - To: `bookingToolSystem_7f1d`
   - Protocol: HTTPS

9. **Updates job status**: Cron Jobs updates the queue job status (completed or failed) in MySQL via Queue Repository.
   - From: `ssuCronJobs`
   - To: `ssuQueueRepository`
   - Protocol: direct (in-process)

10. **Persists status update**: Queue Repository writes the updated job status to `continuumEmeaBtSelfSetupFdDb`.
    - From: `ssuQueueRepository`
    - To: `continuumEmeaBtSelfSetupFdDb`
    - Protocol: MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce merchant ID fetch fails | Cron job logs error; job remains in pending state | Job retried on next cron cycle |
| Booking Tool API call fails | Cron job logs error; job status updated to failed or remains pending | Job retried on next cron cycle; no partial BT state |
| MySQL connection failure | Cron job cannot read queue; exits with error | No jobs processed; queue unchanged; retried on next cron cycle |
| Reminder email cron fails | Non-critical sub-task; no impact on BT creation | Email not sent; BT creation unaffected |

## Sequence Diagram

```
cron-scheduler         ->  ssuCronJobs: Scheduled trigger
ssuCronJobs            ->  ssuQueueRepository: Processes queued setup requests
ssuQueueRepository     ->  continuumEmeaBtSelfSetupFdDb: MySQL SELECT (pending jobs)
continuumEmeaBtSelfSetupFdDb --> ssuQueueRepository: Pending job list
ssuQueueRepository     --> ssuCronJobs: Pending jobs
ssuCronJobs            ->  selfsetupFd_ssuSalesforceClient: Fetches merchant identifiers
selfsetupFd_ssuSalesforceClient -> salesForce: HTTPS REST query (merchant ID)
salesForce             --> selfsetupFd_ssuSalesforceClient: Merchant identifiers
selfsetupFd_ssuSalesforceClient --> ssuCronJobs: Merchant identifiers
ssuCronJobs            ->  selfsetupFd_ssuBookingToolClient: Creates booking tool setup
selfsetupFd_ssuBookingToolClient -> bookingToolSystem_7f1d: HTTPS API call (create/configure BT)
bookingToolSystem_7f1d --> selfsetupFd_ssuBookingToolClient: BT creation result
selfsetupFd_ssuBookingToolClient --> ssuCronJobs: Result
ssuCronJobs            ->  ssuQueueRepository: Processes queued setup requests (update status)
ssuQueueRepository     ->  continuumEmeaBtSelfSetupFdDb: MySQL UPDATE (job status)
```

## Related

- Architecture dynamic view: `dynamic-ssu_fd_self_setup_flow`
- Related flows: [Employee Initiates F&D Setup](employee-initiate-fd-setup.md), [Fetch Merchant BT Details](fetch-merchant-bt-details.md)
