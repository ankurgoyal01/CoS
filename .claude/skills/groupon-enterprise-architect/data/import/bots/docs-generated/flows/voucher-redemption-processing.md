---
service: "bots"
title: "Voucher Redemption Processing"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "voucher-redemption-processing"
flow_type: synchronous
trigger: "HTTP PUT request to /merchants/{id}/bookings/{bookingId}/checkin"
participants:
  - "botsApiResourcesComponent"
  - "botsApiDomainServicesComponent"
  - "botsApiPersistenceComponent"
  - "botsApiIntegrationClientsComponent"
  - "botsWorkerJobServicesComponent"
  - "continuumBotsMysql"
  - "continuumVoucherInventoryService"
  - "messageBus"
architecture_ref: "dynamic-bots-booking-request-flow"
---

# Voucher Redemption Processing

## Summary

When a merchant checks in a customer at the time of their booking, BOTS processes the voucher redemption. The checkin API call triggers a synchronous update to the booking status in `continuumBotsMysql` and coordinates voucher redemption with `continuumVoucherInventoryService` (VIS). Upon successful redemption, a `booking.events.checked-in` event is published. Background worker jobs (`botsWorkerJobServicesComponent`) also handle deferred voucher redemption processing scenarios.

## Trigger

- **Type**: api-call
- **Source**: Merchant tooling calling `PUT /merchants/{id}/bookings/{bookingId}/checkin`
- **Frequency**: On-demand, per customer checkin at time of appointment

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Resources | Receives the checkin HTTP request | `botsApiResourcesComponent` |
| Domain Services | Orchestrates checkin and redemption logic | `botsApiDomainServicesComponent` |
| Persistence Access | Reads booking state and writes checkin/redemption outcome | `botsApiPersistenceComponent` |
| Integration Clients | Calls VIS for voucher redemption | `botsApiIntegrationClientsComponent` |
| Job Services | Handles deferred voucher redemption background processing | `botsWorkerJobServicesComponent` |
| BOTS MySQL | Stores booking checkin state and voucher redemption record | `continuumBotsMysql` |
| Voucher Inventory Service | Marks the voucher as redeemed | `continuumVoucherInventoryService` |
| Message Bus | Receives the `booking.events.checked-in` event | `messageBus` |

## Steps

1. **Receive checkin request**: HTTP PUT arrives at `continuumBotsApi`.
   - From: `caller (merchant tooling)`
   - To: `botsApiResourcesComponent`
   - Protocol: REST

2. **Invoke checkin use case**: Resource layer delegates to domain services.
   - From: `botsApiResourcesComponent`
   - To: `botsApiDomainServicesComponent`
   - Protocol: Direct

3. **Load booking record**: Domain services retrieve the booking from `continuumBotsMysql` and validate it is in a checkable state.
   - From: `botsApiPersistenceComponent`
   - To: `continuumBotsMysql`
   - Protocol: JDBC / SQL

4. **Redeem voucher**: Domain services call VIS to mark the associated voucher as redeemed.
   - From: `botsApiIntegrationClientsComponent`
   - To: `continuumVoucherInventoryService`
   - Protocol: REST

5. **Update booking status to checked-in**: Domain services update the booking record in `continuumBotsMysql`.
   - From: `botsApiPersistenceComponent`
   - To: `continuumBotsMysql`
   - Protocol: JDBC / SQL

6. **Write voucher redemption record**: Domain services persist the voucher redemption outcome.
   - From: `botsApiPersistenceComponent`
   - To: `continuumBotsMysql`
   - Protocol: JDBC / SQL

7. **Publish booking.events.checked-in**: Domain services publish the checkin event to the Message Bus.
   - From: `botsApiDomainServicesComponent`
   - To: `messageBus`
   - Protocol: Message Bus

8. **Return HTTP response**: API returns success to caller.
   - From: `botsApiResourcesComponent`
   - To: `caller`
   - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Booking not found or wrong state | Return HTTP 404 / 422 | Checkin rejected |
| VIS unavailable | Return HTTP 500; booking status not updated | Merchant must retry; voucher not redeemed |
| VIS returns redemption error (already redeemed, invalid) | Return HTTP 422 with error detail | Checkin rejected; merchant informed |
| DB failure writing checkin status | Return HTTP 500; transaction rolled back | Checkin not recorded; no event published |
| Message Bus publish failure | Log error; booking and redemption persisted but event not delivered | Downstream consumers may miss checkin event |
| Deferred redemption (Worker path) | `botsWorkerJobServicesComponent` retries VIS call | Redemption completed asynchronously |

## Sequence Diagram

```
Caller -> botsApiResourcesComponent: PUT /merchants/{id}/bookings/{bookingId}/checkin
botsApiResourcesComponent -> botsApiDomainServicesComponent: Handle checkin request
botsApiDomainServicesComponent -> botsApiPersistenceComponent: Load booking record
botsApiPersistenceComponent -> continuumBotsMysql: SELECT booking
continuumBotsMysql --> botsApiPersistenceComponent: Booking record
botsApiDomainServicesComponent -> botsApiIntegrationClientsComponent: Redeem voucher
botsApiIntegrationClientsComponent -> continuumVoucherInventoryService: POST voucher redemption
continuumVoucherInventoryService --> botsApiIntegrationClientsComponent: Redemption confirmed
botsApiDomainServicesComponent -> botsApiPersistenceComponent: Update booking status and write redemption record
botsApiPersistenceComponent -> continuumBotsMysql: UPDATE booking; INSERT voucher redemption
continuumBotsMysql --> botsApiPersistenceComponent: Success
botsApiDomainServicesComponent -> messageBus: Publish booking.events.checked-in
botsApiResourcesComponent --> Caller: HTTP 200 OK
```

## Related

- Architecture dynamic view: `dynamic-bots-booking-request-flow`
- Related flows: [Booking Creation and Confirmation](booking-creation-and-confirmation.md)
