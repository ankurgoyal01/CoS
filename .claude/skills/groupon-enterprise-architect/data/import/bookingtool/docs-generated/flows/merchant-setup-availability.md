---
service: "bookingtool"
title: "Merchant Setup Availability"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "merchant-setup-availability"
flow_type: synchronous
trigger: "Merchant submits availability configuration via admin UI"
participants:
  - "Merchant (browser)"
  - "continuumBookingToolApp"
  - "btControllers"
  - "btDomainServices"
  - "btRepositories"
  - "continuumBookingToolMySql"
  - "salesForce"
architecture_ref: "dynamic-bookingtool"
---

# Merchant Setup Availability

## Summary

This flow describes how a merchant configures their available time slots for a given Groupon deal. The merchant uses the Booking Tool admin UI to define recurring or one-off availability windows with capacity limits. The Booking Tool validates the request against deal metadata from Salesforce, persists the availability windows to MySQL, and makes those slots available for customer booking.

## Trigger

- **Type**: user-action
- **Source**: Merchant submits an availability configuration form in the Booking Tool admin portal
- **Frequency**: On-demand — merchants set up availability at deal launch and update as needed

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Initiates availability configuration; submits form data | — |
| Booking Tool Application | Receives and processes the availability request | `continuumBookingToolApp` |
| HTTP Controllers | Routes `?api_screen=availability` request to domain logic | `btControllers` |
| Domain Services | Validates availability rules; applies business constraints | `btDomainServices` |
| Repositories | Persists availability windows to MySQL | `btRepositories` |
| Booking Tool MySQL | Stores availability records | `continuumBookingToolMySql` |
| Salesforce | Provides deal and merchant metadata for validation | `salesForce` |

## Steps

1. **Receives availability request**: Merchant submits POST to `?api_screen=availability` with slot configuration (deal_id, start_datetime, end_datetime, capacity, recurrence_rule, locale).
   - From: `Merchant (browser)`
   - To: `continuumBookingToolApp`
   - Protocol: HTTPS/REST

2. **Routes to handler**: HTTP Controllers parse the `api_screen` parameter and dispatch to the availability handler.
   - From: `btControllers`
   - To: `btDomainServices`
   - Protocol: direct

3. **Fetches deal metadata**: Domain Services calls Salesforce via Integration Clients to retrieve and validate deal and merchant configuration.
   - From: `btDomainServices` (via `btIntegrationClients`)
   - To: `salesForce`
   - Protocol: HTTPS/REST

4. **Validates availability rules**: Domain Services applies business rules — no overlapping windows, capacity > 0, datetimes within deal active period.
   - From: `btDomainServices`
   - To: `btDomainServices`
   - Protocol: direct

5. **Persists availability windows**: Repositories write the validated availability records to MySQL.
   - From: `btRepositories`
   - To: `continuumBookingToolMySql`
   - Protocol: SQL/TCP

6. **Returns confirmation**: Controller returns HTTP 200 with the created availability window IDs.
   - From: `continuumBookingToolApp`
   - To: `Merchant (browser)`
   - Protocol: HTTPS/REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce unavailable | Integration client catches HTTP error; request fails | HTTP 503 returned to merchant; availability not saved |
| Overlapping availability window | Domain Services validation rejects request | HTTP 400 with conflict detail returned |
| Invalid datetime range | Domain Services validation rejects request | HTTP 400 with validation error returned |
| MySQL write failure | Repository throws exception; transaction rolls back | HTTP 500 returned; availability not persisted |

## Sequence Diagram

```
Merchant -> continuumBookingToolApp: POST ?api_screen=availability
continuumBookingToolApp -> btControllers: Route request
btControllers -> btDomainServices: Handle availability creation
btDomainServices -> salesForce: GET deal/merchant metadata (HTTPS/REST)
salesForce --> btDomainServices: Deal config response
btDomainServices -> btRepositories: Persist availability windows
btRepositories -> continuumBookingToolMySql: INSERT availability rows (SQL/TCP)
continuumBookingToolMySql --> btRepositories: Write confirmed
btRepositories --> btDomainServices: Availability IDs
btDomainServices --> btControllers: Success result
btControllers --> continuumBookingToolApp: HTTP 200 response
continuumBookingToolApp --> Merchant: Availability created confirmation
```

## Related

- Architecture dynamic view: `dynamic-bookingtool`
- Related flows: [Merchant Manage Blocked Times](merchant-manage-blocked-times.md), [Customer Book Appointment](customer-book-appointment.md)
