---
service: "inbox_management_platform"
title: "Calculation Coordination Workflow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "calculation-coordination-workflow"
flow_type: event-driven
trigger: "CampaignSendEvent received from Campaign Management via Kafka/mbus"
participants:
  - "inbox_coordinationWorker"
  - "inbox_campaignManagementClient"
  - "inbox_arbitrationClient"
  - "inbox_dispatchScheduler"
  - "continuumInboxManagementRedis"
  - "continuumInboxManagementPostgres"
architecture_ref: "dynamic-inbox-core-coordination"
---

# Calculation Coordination Workflow

## Summary

The calculation coordination workflow is the primary processing loop of InboxManagement. When Campaign Management publishes a CampaignSendEvent, the coordination worker dequeues user-campaign pairs from the Redis calc queue, loads full campaign details from Campaign Management, applies CAS arbitration filtering to suppress ineligible users, and promotes eligible candidates into the Redis dispatch queue. This flow is the bridge between campaign triggering and channel delivery.

## Trigger

- **Type**: event
- **Source**: Campaign Management publishes a CampaignSendEvent to the Kafka/mbus topic consumed by `inbox_coordinationWorker`
- **Frequency**: Continuous; events arrive whenever Campaign Management schedules a send batch

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Coordination Worker | Orchestrates the full coordination cycle; dequeues, enriches, filters, and promotes | `inbox_coordinationWorker` |
| Campaign Management Client | Fetches campaign send event metadata and targeting details | `inbox_campaignManagementClient` |
| Arbitration Client | Calls CAS to apply suppression and frequency-cap filtering | `inbox_arbitrationClient` |
| Dispatch Scheduler | Receives eligible users and writes them to the dispatch queue | `inbox_dispatchScheduler` |
| Inbox Management Redis | Hosts the calc queue and user locks; stores dispatch-ready entries | `continuumInboxManagementRedis` |
| Inbox Management Postgres | Provides runtime config (throttle rates, circuit breaker state) | `continuumInboxManagementPostgres` |

## Steps

1. **Receive CampaignSendEvent**: `inbox_coordinationWorker` consumes a CampaignSendEvent from the Kafka/mbus topic.
   - From: Campaign Management (Kafka/mbus topic)
   - To: `inbox_coordinationWorker`
   - Protocol: Kafka / mbus

2. **Acquire user lock**: Coordination worker acquires a distributed lock in Redis per user_id to prevent concurrent processing.
   - From: `inbox_coordinationWorker`
   - To: `continuumInboxManagementRedis`
   - Protocol: Redis

3. **Load campaign send events**: Coordination worker calls Campaign Management Client to fetch full campaign metadata for the event.
   - From: `inbox_coordinationWorker`
   - To: `inbox_campaignManagementClient`
   - Protocol: Internal

4. **Fetch campaign data from Campaign Management API**: Campaign Management Client makes a REST call to the Campaign Management API.
   - From: `inbox_campaignManagementClient`
   - To: Campaign Management API (external)
   - Protocol: REST

5. **Apply CAS arbitration filtering**: Coordination worker passes the user-campaign candidates to the Arbitration Client for suppression evaluation.
   - From: `inbox_coordinationWorker`
   - To: `inbox_arbitrationClient`
   - Protocol: Internal

6. **Call CAS for suppression decisions**: Arbitration Client calls the CAS (Campaign Arbitration Service) API with the candidate list.
   - From: `inbox_arbitrationClient`
   - To: CAS API (external)
   - Protocol: REST

7. **Read runtime config**: Coordination worker reads throttle rates and active flags from Postgres via `inbox_configAndStateAccess`.
   - From: `inbox_coordinationWorker`
   - To: `continuumInboxManagementPostgres`
   - Protocol: JDBC

8. **Schedule dispatch work**: Coordination worker passes eligible (non-suppressed) users to the Dispatch Scheduler.
   - From: `inbox_coordinationWorker`
   - To: `inbox_dispatchScheduler`
   - Protocol: Internal

9. **Write to dispatch queue**: Dispatch Scheduler writes dispatch-ready user-campaign entries to the Redis dispatch queue.
   - From: `inbox_dispatchScheduler`
   - To: `continuumInboxManagementRedis`
   - Protocol: Redis

10. **Release user lock**: Coordination worker releases the Redis lock after processing completes.
    - From: `inbox_coordinationWorker`
    - To: `continuumInboxManagementRedis`
    - Protocol: Redis

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Campaign Management API unavailable | Circuit breaker opens (configurable); coordination pauses for affected campaign | Error logged; event retried on next cycle |
| CAS API unavailable | Circuit breaker opens; configurable fail-open (send all) or fail-closed (suppress all) | Depends on circuit breaker config |
| Redis unavailable | Lock acquisition fails; event processing halted | Processing pauses; daemon retries |
| User lock contention | Skip or retry after backoff | User skipped for this cycle |
| Unexpected exception | Error state recorded in Postgres | Event marked as failed; retry logic applied |

## Sequence Diagram

```
CampaignManagement -> inbox_coordinationWorker: CampaignSendEvent (Kafka/mbus)
inbox_coordinationWorker -> continuumInboxManagementRedis: Acquire user lock
inbox_coordinationWorker -> inbox_campaignManagementClient: Load campaign send events
inbox_campaignManagementClient -> CampaignManagementAPI: GET campaign data (REST)
CampaignManagementAPI --> inbox_campaignManagementClient: Campaign metadata
inbox_campaignManagementClient --> inbox_coordinationWorker: Campaign send events
inbox_coordinationWorker -> inbox_arbitrationClient: Filter candidates with CAS
inbox_arbitrationClient -> CAS_API: POST suppression check (REST)
CAS_API --> inbox_arbitrationClient: Suppression decisions
inbox_arbitrationClient --> inbox_coordinationWorker: Eligible candidates
inbox_coordinationWorker -> inbox_dispatchScheduler: Schedule dispatch work
inbox_dispatchScheduler -> continuumInboxManagementRedis: Write dispatch queue entries
inbox_coordinationWorker -> continuumInboxManagementRedis: Release user lock
```

## Related

- Architecture dynamic view: `dynamic-inbox-core-coordination`
- Related flows: [Dispatch Scheduling and Send Publication](dispatch-scheduling-and-send-publication.md)
- See also: [Integrations](../integrations.md) for Campaign Management and CAS details
