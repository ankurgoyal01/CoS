---
service: "breakage-reduction-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Breakage Reduction Service (VEX).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Voucher Next-Actions Computation](voucher-next-actions.md) | synchronous | POST `/voucher/v1/next_actions` | Aggregates voucher context and evaluates workflow rules to return a prioritized list of next-actions for a voucher |
| [Reminder Scheduling](reminder-scheduling.md) | synchronous | POST `remind_me_later/.../send_reminder` or `.../reminders` | Validates user and voucher state then schedules a reminder job in RISE |
| [Message Content Assembly](message-content-assembly.md) | synchronous | GET `/message/v1/content` | Assembles and returns rendered push or in-app notification message content for campaign delivery |
| [Notification Backfill](notification-backfill.md) | batch | Internal backfill API call | Bulk-schedules notification workflows in RISE for vouchers that missed initial scheduling |
| [Voucher Context Preload](voucher-context-preload.md) | synchronous | Internal — invoked by Next-Actions and Reminder flows | Orchestrates parallel downstream service calls to assemble complete voucher context before workflow evaluation |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

The reminder scheduling flow is modeled as a Structurizr dynamic view: `dynamic-brs-reminder-scheduling-flow`. This view captures the sequence of BRS calling `continuumUsersService` to load the user account and `continuumVoucherInventoryApi` to load voucher metadata before submitting the reminder to RISE.

See [Reminder Scheduling](reminder-scheduling.md) for full detail.
