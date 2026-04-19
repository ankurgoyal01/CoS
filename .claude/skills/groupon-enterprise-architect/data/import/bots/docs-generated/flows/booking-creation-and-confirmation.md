---
service: "bots"
title: "Booking Creation and Confirmation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "booking-creation-and-confirmation"
flow_type: synchronous
trigger: "HTTP POST request to /merchants/{id}/bookings"
participants:
  - "botsApiResourcesComponent"
  - "botsApiDomainServicesComponent"
  - "botsApiPersistenceComponent"
  - "botsApiIntegrationClientsComponent"
  - "continuumBotsMysql"
  - "continuumM3MerchantService"
  - "continuumVoucherInventoryService"
  - "continuumCalendarService"
  - "messageBus"
architecture_ref: "dynamic-bots-booking-request-flow"
---

# Booking Creation and Confirmation

## Summary

This flow covers the end-to-end process of creating a new booking for a merchant. A caller (merchant tooling or internal service) submits a booking request to `continuumBotsApi`. The API validates the request by resolving merchant, deal, and voucher data from upstream services, persists the booking to `continuumBotsMysql`, updates the calendar via `continuumCalendarService`, and publishes a `booking.events.created` event to the Message Bus.

## Trigger

- **Type**: api-call
- **Source**: Merchant tooling or internal Groupon system calling `POST /merchants/{id}/bookings`
- **Frequency**: On-demand, per booking request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Resources | Receives and validates the incoming HTTP request | `botsApiResourcesComponent` |
| Domain Services | Orchestrates booking creation business logic | `botsApiDomainServicesComponent` |
| Persistence Access | Persists the new booking record | `botsApiPersistenceComponent` |
| Integration Clients | Calls upstream services for merchant and voucher data | `botsApiIntegrationClientsComponent` |
| BOTS MySQL | Stores the persisted booking | `continuumBotsMysql` |
| M3 Merchant Service | Provides merchant account data | `continuumM3MerchantService` |
| Voucher Inventory Service | Validates and resolves voucher details | `continuumVoucherInventoryService` |
| Calendar Service | Registers the booking in Continuum's calendar layer | `continuumCalendarService` |
| Message Bus | Receives the `booking.events.created` event | `messageBus` |

## Steps

1. **Receive booking request**: HTTP POST arrives at `continuumBotsApi`.
   - From: `caller`
   - To: `botsApiResourcesComponent`
   - Protocol: REST

2. **Invoke booking use case**: Resource layer delegates to domain services.
   - From: `botsApiResourcesComponent`
   - To: `botsApiDomainServicesComponent`
   - Protocol: Direct

3. **Resolve merchant account**: Domain services fetch merchant profile.
   - From: `botsApiIntegrationClientsComponent`
   - To: `continuumM3MerchantService`
   - Protocol: REST

4. **Resolve voucher details**: Domain services validate the voucher associated with the booking.
   - From: `botsApiIntegrationClientsComponent`
   - To: `continuumVoucherInventoryService`
   - Protocol: REST

5. **Persist booking**: Domain services write the new booking record to the database.
   - From: `botsApiPersistenceComponent`
   - To: `continuumBotsMysql`
   - Protocol: JDBC / SQL

6. **Update calendar entity**: Domain services register the booking in the Continuum calendar layer.
   - From: `botsApiIntegrationClientsComponent`
   - To: `continuumCalendarService`
   - Protocol: REST

7. **Publish booking-created event**: Domain services publish `booking.events.created` to the Message Bus.
   - From: `botsApiDomainServicesComponent`
   - To: `messageBus`
   - Protocol: Message Bus

8. **Return HTTP response**: API returns success response to caller.
   - From: `botsApiResourcesComponent`
   - To: `caller`
   - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Merchant not found in M3 Merchant Service | Return HTTP 404 | Booking not created |
| Voucher invalid or already redeemed | Return HTTP 422 | Booking not created |
| Database write failure | Return HTTP 500; transaction rolled back | Booking not created; no event published |
| Calendar Service unavailable | Log error; return HTTP 500 | Booking may be created but calendar not updated (data inconsistency risk) |
| Message Bus publish failure | Log error; booking persisted but event not delivered | Downstream consumers may miss the event |

## Sequence Diagram

```
Caller -> botsApiResourcesComponent: POST /merchants/{id}/bookings
botsApiResourcesComponent -> botsApiDomainServicesComponent: Handle booking request
botsApiDomainServicesComponent -> botsApiIntegrationClientsComponent: Resolve merchant and voucher dependencies
botsApiIntegrationClientsComponent -> continuumM3MerchantService: GET merchant account
continuumM3MerchantService --> botsApiIntegrationClientsComponent: Merchant data
botsApiIntegrationClientsComponent -> continuumVoucherInventoryService: GET voucher details
continuumVoucherInventoryService --> botsApiIntegrationClientsComponent: Voucher data
botsApiDomainServicesComponent -> botsApiPersistenceComponent: Load and persist booking entities
botsApiPersistenceComponent -> continuumBotsMysql: INSERT booking record
continuumBotsMysql --> botsApiPersistenceComponent: Success
botsApiDomainServicesComponent -> botsApiIntegrationClientsComponent: Update calendar entity
botsApiIntegrationClientsComponent -> continuumCalendarService: POST calendar event
continuumCalendarService --> botsApiIntegrationClientsComponent: Calendar entity updated
botsApiDomainServicesComponent -> messageBus: Publish booking.events.created
botsApiResourcesComponent --> Caller: HTTP 201 Created
```

## Related

- Architecture dynamic view: `dynamic-bots-booking-request-flow`
- Related flows: [Booking Availability Query](booking-availability-query.md), [Voucher Redemption Processing](voucher-redemption-processing.md)
