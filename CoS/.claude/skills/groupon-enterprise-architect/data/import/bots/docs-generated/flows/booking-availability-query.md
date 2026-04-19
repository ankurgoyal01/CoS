---
service: "bots"
title: "Booking Availability Query"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "booking-availability-query"
flow_type: synchronous
trigger: "HTTP GET request to /merchants/{id}/availability"
participants:
  - "botsApiResourcesComponent"
  - "botsApiDomainServicesComponent"
  - "botsApiPersistenceComponent"
  - "botsApiIntegrationClientsComponent"
  - "continuumBotsMysql"
  - "continuumM3PlacesService"
architecture_ref: "dynamic-bots-booking-request-flow"
---

# Booking Availability Query

## Summary

This flow covers how callers query available booking slots for a merchant. When a request arrives at `continuumBotsApi`, the API loads the merchant's configured availability windows and existing bookings from `continuumBotsMysql`, optionally enriches the response with place/location data from `continuumM3PlacesService`, computes open slots, and returns the computed availability to the caller.

## Trigger

- **Type**: api-call
- **Source**: Merchant tooling, consumer-facing frontend, or internal Groupon system calling `GET /merchants/{id}/availability`
- **Frequency**: On-demand, per availability query

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Resources | Receives and routes the HTTP availability request | `botsApiResourcesComponent` |
| Domain Services | Computes available slots from stored windows and bookings | `botsApiDomainServicesComponent` |
| Persistence Access | Reads availability windows and existing bookings from database | `botsApiPersistenceComponent` |
| Integration Clients | Fetches place/location context from M3 Places | `botsApiIntegrationClientsComponent` |
| BOTS MySQL | Source of availability window and booking records | `continuumBotsMysql` |
| M3 Place Read | Provides merchant place/location metadata for availability context | `continuumM3PlacesService` |

## Steps

1. **Receive availability query**: HTTP GET arrives at `continuumBotsApi`.
   - From: `caller`
   - To: `botsApiResourcesComponent`
   - Protocol: REST

2. **Invoke availability use case**: Resource layer delegates to domain services.
   - From: `botsApiResourcesComponent`
   - To: `botsApiDomainServicesComponent`
   - Protocol: Direct

3. **Load availability windows**: Domain services read merchant availability configuration.
   - From: `botsApiPersistenceComponent`
   - To: `continuumBotsMysql`
   - Protocol: JDBC / SQL

4. **Load existing bookings**: Domain services read current bookings to determine slot occupancy.
   - From: `botsApiPersistenceComponent`
   - To: `continuumBotsMysql`
   - Protocol: JDBC / SQL

5. **Fetch place/location context** (if required): Integration clients retrieve merchant location details.
   - From: `botsApiIntegrationClientsComponent`
   - To: `continuumM3PlacesService`
   - Protocol: REST

6. **Compute open slots**: Domain services calculate which time slots are available given windows, existing bookings, and capacity.
   - From: `botsApiDomainServicesComponent`
   - To: `botsApiDomainServicesComponent`
   - Protocol: Direct (in-process computation)

7. **Return availability response**: API returns the computed availability slots to the caller.
   - From: `botsApiResourcesComponent`
   - To: `caller`
   - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Merchant has no availability configured | Return empty availability list with HTTP 200 | Caller receives empty slots |
| Database read failure | Return HTTP 500 | Availability not returned |
| M3 Places Service unavailable | Log warning; proceed without place context | Availability returned without location enrichment |
| Invalid query parameters (dates, service ID) | Return HTTP 422 | No availability computed |

## Sequence Diagram

```
Caller -> botsApiResourcesComponent: GET /merchants/{id}/availability
botsApiResourcesComponent -> botsApiDomainServicesComponent: Compute availability
botsApiDomainServicesComponent -> botsApiPersistenceComponent: Load availability windows and bookings
botsApiPersistenceComponent -> continuumBotsMysql: SELECT availability, bookings
continuumBotsMysql --> botsApiPersistenceComponent: Availability windows and booking records
botsApiDomainServicesComponent -> botsApiIntegrationClientsComponent: Fetch place/location context
botsApiIntegrationClientsComponent -> continuumM3PlacesService: GET place details
continuumM3PlacesService --> botsApiIntegrationClientsComponent: Place metadata
botsApiDomainServicesComponent --> botsApiDomainServicesComponent: Compute open slots
botsApiResourcesComponent --> Caller: HTTP 200 Available slots
```

## Related

- Architecture dynamic view: `dynamic-bots-booking-request-flow`
- Related flows: [Booking Creation and Confirmation](booking-creation-and-confirmation.md)
