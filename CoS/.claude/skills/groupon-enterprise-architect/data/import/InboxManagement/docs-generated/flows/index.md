---
service: "inbox_management_platform"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for InboxManagement.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Calculation Coordination Workflow](calculation-coordination-workflow.md) | event-driven | CampaignSendEvent received from Campaign Management | Dequeues users from calc queue, fetches campaign data, applies CAS arbitration, and promotes eligible users to dispatch queue |
| [Dispatch Scheduling and Send Publication](dispatch-scheduling-and-send-publication.md) | event-driven | User promoted to dispatch-ready state in Redis | Dispatches scheduler moves candidates to send-ready, and RocketMan publisher produces final SendEvents to Kafka |
| [User Synchronization and Attribute Refresh](user-synchronization-and-attribute-refresh.md) | event-driven | UserProfileEvent received from user profile system | Consumes user profile events and refreshes inbox user attribute state from EDW |
| [Error Handling and Send Failure Recovery](error-handling-and-send-failure-recovery.md) | event-driven | SendErrorEvent received from error topic | Records send failures, applies retry/suppression logic, and manages error state in Postgres |
| [Subscription Preference Management](subscription-preference-management.md) | event-driven | SubscriptionEvent received from subscription topic | Updates subscription and opt-out preference state affecting future dispatch eligibility |
| [Queue Monitoring and Health Checks](queue-monitoring-and-health-checks.md) | scheduled | Polling schedule (daemon-driven) | Measures calc and dispatch queue depths, emits metrics, and surfaces health signals for alerting |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 5 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

The following flows span multiple services and are documented in the central architecture dynamic views:

- **Core Coordination Flow** — spans `continuumInboxManagementCore`, Campaign Management, CAS, and RocketMan. See architecture dynamic view: `dynamic-inbox-core-coordination`.
- The full end-to-end campaign send path originates in Campaign Management, passes through InboxManagement coordination and dispatch, and terminates in RocketMan channel delivery.
