---
service: "bookingtool"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for the Booking Tool.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Merchant Setup Availability](merchant-setup-availability.md) | synchronous | Merchant configures availability windows via admin UI | Merchant defines available time slots and capacity for a deal; slots become bookable by customers |
| [Customer Book Appointment](customer-book-appointment.md) | synchronous | Customer selects a slot and confirms booking | Customer reserves a time slot against a valid voucher; booking record created and confirmation event published |
| [Customer Cancel or Reschedule](customer-cancel-reschedule.md) | synchronous | Customer requests cancellation or reschedule via UI | Existing reservation is cancelled or moved to a new slot; downstream events trigger email and voucher reinstatement |
| [Merchant Manage Blocked Times](merchant-manage-blocked-times.md) | synchronous | Merchant blocks out a time range | Merchant creates or removes blocked-time entries; affected availability slots are removed from the bookable set |
| [API Request Lifecycle](api-request-lifecycle.md) | synchronous | Any inbound HTTP request via `?api_screen=` | End-to-end request handling from HTTP ingress through controllers, domain services, repositories, and response |
| [Admin Authentication via Okta](admin-authentication-okta.md) | synchronous | Admin user logs into the Booking Tool admin portal | Admin is redirected to Okta, authenticates, receives a session token, and accesses protected admin functions |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 6 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- The [Customer Book Appointment](customer-book-appointment.md) flow publishes to `jms.topic.BookingTool.Services.BookingEngine`, triggering downstream email delivery via Rocketman V2 and appointment coordination via Appointment Engine.
- The [Customer Cancel or Reschedule](customer-cancel-reschedule.md) flow publishes cancellation/reschedule events to the same topic, triggering voucher reinstatement via Voucher Inventory.
- Cross-service dynamic views for these flows are not yet modeled in the central architecture repository (`structurizr/import/bookingtool/architecture/views/dynamics.dsl` contains no dynamic views).
