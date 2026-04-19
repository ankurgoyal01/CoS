---
service: "calcom"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for Calcom.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Booking Request and Confirmation](booking-confirmation.md) | synchronous | User selects a time slot and submits booking | End user submits a meeting booking via the Booking UI; the Scheduling API validates the session, persists the booking, and triggers confirmation notifications |
| [Background Reminder and Notification Dispatch](reminder-dispatch.md) | asynchronous | Scheduled time before a booked meeting | The Worker Service processes queued reminder jobs and dispatches email notifications via Gmail SMTP |
| [Admin User Promotion](admin-user-promotion.md) | batch | Manual operation by an authorized admin | An administrator promotes a regular user to admin role via direct database update, bypassing the paid UI user management feature |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- The **Booking Confirmation Flow** is modeled as a Structurizr dynamic view: `dynamic-calcom-booking-confirmation`. It spans components within `continuumCalcomService` and triggers downstream email delivery via `gmailSmtpService`.
- The **Reminder Dispatch Flow** crosses from `continuumCalcomService` (job creation) to `continuumCalcomWorkerService` (job processing) via the internal PostgreSQL-backed job queue.
