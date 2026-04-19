---
service: "calendar-service"
title: "Place Service Config Sync"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "place-service-config-sync"
flow_type: synchronous
trigger: "POST /v1/merchants/{id}/places/{id}/sync API call"
participants:
  - "continuumCalendarServiceCalSer"
  - "continuumCalendarPostgres"
  - "continuumCalendarRedis"
architecture_ref: "calendarServiceComponents"
---

# Place Service Config Sync

## Summary

This flow allows merchant place configuration — including open hours and place metadata — to be synchronized from M3 Place into Calendar Service's local data store. When `POST /v1/merchants/{id}/places/{id}/sync` is called, `availabilityCore` fetches the current place data from M3 Place Service via `calendarService_externalClients`, persists the updated configuration in `continuumCalendarPostgres`, and invalidates any Redis cache entries that depended on that place's open-hours data. Subsequent availability compilations for the merchant's services will pick up the refreshed configuration.

## Trigger

- **Type**: api-call
- **Source**: Merchant management tooling or an internal sync orchestrator calling `POST /v1/merchants/{id}/places/{id}/sync`
- **Frequency**: On-demand; triggered when place configuration changes in M3 Place or when an operator forces a sync

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Calendar Service API Hosts | Receives and executes the place sync request | `continuumCalendarServiceCalSer` |
| API Resources | Routes the sync request to availability and booking orchestration | `apiResourcesCalSer` |
| Availability Core | Fetches and processes M3 Place data; drives persistence | `availabilityCore` |
| External Client Adapters | Calls M3 Place Service REST API | `calendarService_externalClients` |
| Persistence Layer | Writes updated place configuration to Postgres | `dataAccessCalSer` |
| Calendar Service Postgres DaaS | Stores place configuration and merchant open-hours data | `continuumCalendarPostgres` |
| Calendar Service Redis Cache | Stale cache entries for the place are invalidated | `continuumCalendarRedis` |

> Note: M3 Place Service (`m3PlaceService`) is an external dependency referenced as a validation stub in the federated DSL. It is not yet in the central federated architecture model.

## Steps

1. **Receive place sync request**: Caller sends `POST /v1/merchants/{merchantId}/places/{placeId}/sync`.
   - From: merchant management tooling or internal orchestrator
   - To: `apiResourcesCalSer`
   - Protocol: REST

2. **Dispatch to Availability Core**: `apiResourcesCalSer` routes the sync operation to `availabilityCore` (place configuration is an input to availability compilation).
   - From: `apiResourcesCalSer`
   - To: `availabilityCore`
   - Protocol: direct

3. **Fetch place metadata from M3**: `availabilityCore` calls `calendarService_externalClients` to retrieve the current place metadata and open hours from M3 Place Service.
   - From: `availabilityCore`
   - To: `calendarService_externalClients` → `m3PlaceService`
   - Protocol: REST

4. **Persist updated place configuration**: `availabilityCore` via `dataAccessCalSer` upserts the place metadata and open-hours configuration in `continuumCalendarPostgres`.
   - From: `availabilityCore` → `dataAccessCalSer`
   - To: `continuumCalendarPostgres`
   - Protocol: JDBC / PostgreSQL

5. **Invalidate Redis cache**: Cache keys for availability data associated with this place (merchant/service open-hours lookups) are deleted from `continuumCalendarRedis`.
   - From: `availabilityCore`
   - To: `continuumCalendarRedis`
   - Protocol: Redis protocol

6. **Return sync result**: `apiResourcesCalSer` returns HTTP 200 to the caller with a sync confirmation.
   - From: `apiResourcesCalSer`
   - To: caller
   - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| M3 Place Service unavailable | Circuit breaker via `jtier-resilience4j` trips; HTTP 503 returned to caller | Place configuration not updated; caller must retry after M3 Place recovers |
| M3 Place returns 404 for place ID | `calendarService_externalClients` propagates 404; HTTP 404 returned to caller | No state change; caller should verify place ID |
| Postgres write failure | Transaction rolled back; HTTP 500 returned | Place configuration not updated; caller must retry |
| Redis invalidation failure | Logged; stale cache expires on TTL | Temporary stale open-hours data used in availability compilation until TTL expiry |

## Sequence Diagram

```
Caller -> apiResourcesCalSer: POST /v1/merchants/{merchantId}/places/{placeId}/sync
apiResourcesCalSer -> availabilityCore: syncPlaceConfig(merchantId, placeId)
availabilityCore -> calendarService_externalClients: fetchPlaceMetadata(merchantId, placeId)
calendarService_externalClients -> m3PlaceService: GET /places/{placeId}?merchantId={merchantId}
m3PlaceService --> calendarService_externalClients: place metadata + open hours
calendarService_externalClients --> availabilityCore: place config
availabilityCore -> dataAccessCalSer: upsertPlaceConfig(placeId, merchantId, config)
dataAccessCalSer -> continuumCalendarPostgres: UPSERT place_config ...
continuumCalendarPostgres --> dataAccessCalSer: persisted
availabilityCore -> continuumCalendarRedis: DEL cache keys for place
apiResourcesCalSer --> Caller: HTTP 200 { synced: true }
```

## Related

- Architecture dynamic view: `calendarServiceComponents`
- Related flows: [Availability Ingestion and Compilation](availability-ingestion-compilation.md), [Availability Query and Caching](availability-query-caching.md)
