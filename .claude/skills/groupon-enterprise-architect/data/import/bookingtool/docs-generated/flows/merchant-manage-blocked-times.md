---
service: "bookingtool"
title: "Merchant Manage Blocked Times"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "merchant-manage-blocked-times"
flow_type: synchronous
trigger: "Merchant creates or removes a blocked-time entry via admin UI"
participants:
  - "Merchant (browser)"
  - "continuumBookingToolApp"
  - "btControllers"
  - "btDomainServices"
  - "btRepositories"
  - "continuumBookingToolMySql"
architecture_ref: "dynamic-bookingtool"
---

# Merchant Manage Blocked Times

## Summary

This flow describes how a merchant blocks out a date/time range to prevent customer bookings during that period — for example, for vacations, maintenance, or public holidays. The Booking Tool records the blocked-time entry in MySQL and ensures no new availability slots are offered within the blocked range. Existing confirmed bookings within the blocked range are not automatically cancelled; merchants must handle those separately.

## Trigger

- **Type**: user-action
- **Source**: Merchant submits a blocked-time form in the Booking Tool admin portal
- **Frequency**: On-demand — when merchants need to close availability

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Initiates the blocked-time creation or deletion | — |
| Booking Tool Application | Receives and processes the blocked-time request | `continuumBookingToolApp` |
| HTTP Controllers | Routes `?api_screen=blockedTime` to the appropriate handler | `btControllers` |
| Domain Services | Validates blocked-time range and applies overlap rules | `btDomainServices` |
| Repositories | Persists or removes blocked-time records in MySQL | `btRepositories` |
| Booking Tool MySQL | Stores blocked_times records | `continuumBookingToolMySql` |

## Steps — Create Blocked Time

1. **Receives blocked-time request**: Merchant submits POST to `?api_screen=blockedTime` with merchant_id, start_datetime, end_datetime, and optional reason.
   - From: `Merchant (browser)`
   - To: `continuumBookingToolApp`
   - Protocol: HTTPS/REST

2. **Routes to blocked-time handler**: HTTP Controllers dispatch to the blocked-time domain service.
   - From: `btControllers`
   - To: `btDomainServices`
   - Protocol: direct

3. **Validates blocked-time range**: Domain Services checks that start_datetime < end_datetime and validates against existing blocked-time entries for conflicts.
   - From: `btDomainServices`
   - To: `btRepositories`
   - Protocol: direct

4. **Persists blocked-time entry**: Repositories insert the new blocked_time record into MySQL.
   - From: `btRepositories`
   - To: `continuumBookingToolMySql`
   - Protocol: SQL/TCP

5. **Returns confirmation**: Controller returns HTTP 200 with the new blocked_time_id.
   - From: `continuumBookingToolApp`
   - To: `Merchant (browser)`
   - Protocol: HTTPS/REST

## Steps — Remove Blocked Time

1. **Receives delete request**: Merchant submits DELETE to `?api_screen=blockedTime` with blocked_time_id.
   - From: `Merchant (browser)`
   - To: `continuumBookingToolApp`
   - Protocol: HTTPS/REST

2. **Routes to delete handler**: HTTP Controllers dispatch to the blocked-time deletion handler.
   - From: `btControllers`
   - To: `btDomainServices`
   - Protocol: direct

3. **Validates ownership**: Domain Services confirms the blocked_time_id belongs to the authenticated merchant.
   - From: `btDomainServices`
   - To: `btRepositories`
   - Protocol: direct

4. **Deletes blocked-time record**: Repositories remove the blocked_time row from MySQL; the previously blocked slots become available for booking.
   - From: `btRepositories`
   - To: `continuumBookingToolMySql`
   - Protocol: SQL/TCP

5. **Returns confirmation**: Controller returns HTTP 200.
   - From: `continuumBookingToolApp`
   - To: `Merchant (browser)`
   - Protocol: HTTPS/REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid datetime range (start >= end) | Domain Services validation rejects request | HTTP 400 with validation error |
| Blocked-time not found (delete) | Repositories return not-found; domain service rejects | HTTP 404 |
| Unauthorized merchant (delete) | Domain Services ownership check fails | HTTP 403 |
| MySQL write/delete failure | Repository exception; operation rolls back | HTTP 500; blocked-time state unchanged |

## Sequence Diagram

```
Merchant -> continuumBookingToolApp: POST/DELETE ?api_screen=blockedTime
continuumBookingToolApp -> btControllers: Route request
btControllers -> btDomainServices: Handle blocked-time create/delete
btDomainServices -> btRepositories: Validate and check existing records
btRepositories -> continuumBookingToolMySql: SELECT blocked_times (SQL/TCP)
continuumBookingToolMySql --> btRepositories: Existing records
btDomainServices -> btRepositories: INSERT or DELETE blocked_time
btRepositories -> continuumBookingToolMySql: Write operation (SQL/TCP)
continuumBookingToolMySql --> btRepositories: Confirmed
btRepositories --> btDomainServices: Result
btDomainServices --> btControllers: Success
btControllers --> continuumBookingToolApp: HTTP 200
continuumBookingToolApp --> Merchant: Confirmation
```

## Related

- Architecture dynamic view: `dynamic-bookingtool`
- Related flows: [Merchant Setup Availability](merchant-setup-availability.md), [Customer Book Appointment](customer-book-appointment.md)
