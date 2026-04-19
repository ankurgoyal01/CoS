---
service: "calendar-service"
title: "Availability Query and Caching"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "availability-query-caching"
flow_type: synchronous
trigger: "Inbound GET /v1/services/availability API call"
participants:
  - "continuumCalendarServiceCalSer"
  - "continuumCalendarRedis"
  - "continuumCalendarMySql"
architecture_ref: "calendarServiceComponents"
---

# Availability Query and Caching

## Summary

This flow handles requests from booking surfaces and internal consumers to retrieve compiled availability windows for one or more services. The `availabilityCore` component first checks Redis for a cached result; on a cache hit the response is returned immediately. On a cache miss, `availabilityCore` queries the MySQL availability engine, caches the result, and returns it to the caller. This two-tier read strategy keeps latency low under peak booking load.

## Trigger

- **Type**: api-call
- **Source**: Upstream booking surface or Continuum service calling `GET /v1/services/availability`
- **Frequency**: On-demand; high frequency during peak consumer booking hours

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Calendar Service API Hosts | Receives and dispatches the availability query | `continuumCalendarServiceCalSer` |
| API Resources | Routes the HTTP request to availability application logic | `apiResourcesCalSer` |
| Availability Core | Executes availability search, cache lookup, and time-range compilation | `availabilityCore` |
| Persistence Layer | Queries MySQL availability records when cache misses | `dataAccessCalSer` |
| Calendar Service Redis Cache | Serves cached availability windows; stores newly compiled results | `continuumCalendarRedis` |
| Availability Engine MySQL DaaS | Source of truth for compiled availability records | `continuumCalendarMySql` |

## Steps

1. **Receive availability request**: Caller sends `GET /v1/services/availability` with service ID(s) and date range parameters.
   - From: upstream caller
   - To: `apiResourcesCalSer`
   - Protocol: REST

2. **Dispatch to Availability Core**: `apiResourcesCalSer` delegates the query to `availabilityCore` for resolution.
   - From: `apiResourcesCalSer`
   - To: `availabilityCore`
   - Protocol: direct

3. **Check Redis cache**: `availabilityCore` constructs a cache key from service ID and date range; queries `continuumCalendarRedis`.
   - From: `availabilityCore`
   - To: `continuumCalendarRedis`
   - Protocol: Redis protocol

4. **Cache hit path — return cached response**: If the cache contains a valid entry, `availabilityCore` returns the cached availability windows directly to `apiResourcesCalSer`, which serializes and returns the HTTP response.
   - From: `continuumCalendarRedis`
   - To: `availabilityCore` → `apiResourcesCalSer` → caller
   - Protocol: Redis protocol / REST

5. **Cache miss path — query MySQL**: `availabilityCore` instructs `dataAccessCalSer` to query `continuumCalendarMySql` for compiled availability records matching the requested service ID(s) and date range.
   - From: `availabilityCore`
   - To: `dataAccessCalSer` → `continuumCalendarMySql`
   - Protocol: JDBC / MySQL

6. **Populate cache**: `availabilityCore` writes the query result to `continuumCalendarRedis` for subsequent requests.
   - From: `availabilityCore`
   - To: `continuumCalendarRedis`
   - Protocol: Redis protocol

7. **Return response**: `availabilityCore` returns compiled availability windows to `apiResourcesCalSer`, which serializes and returns the HTTP 200 response to the caller.
   - From: `availabilityCore`
   - To: `apiResourcesCalSer` → caller
   - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis unavailable | `availabilityCore` falls back directly to MySQL query; Redis error is logged | Request succeeds; performance impact under load |
| MySQL query returns no records | Return empty availability windows with HTTP 200 | Caller receives empty result; no error |
| MySQL unavailable | Return HTTP 503; circuit breaker may trip if sustained | Caller receives error; must retry |
| Invalid date range parameters | `apiResourcesCalSer` validates input and returns HTTP 400 | Caller receives validation error immediately |

## Sequence Diagram

```
Caller -> apiResourcesCalSer: GET /v1/services/availability?serviceId=X&from=...&to=...
apiResourcesCalSer -> availabilityCore: queryAvailability(serviceId, dateRange)
availabilityCore -> continuumCalendarRedis: GET cache key
alt Cache hit
  continuumCalendarRedis --> availabilityCore: cached availability windows
else Cache miss
  availabilityCore -> dataAccessCalSer: findAvailabilityRecords(serviceId, dateRange)
  dataAccessCalSer -> continuumCalendarMySql: SELECT availability_records WHERE ...
  continuumCalendarMySql --> dataAccessCalSer: availability records
  dataAccessCalSer --> availabilityCore: availability windows
  availabilityCore -> continuumCalendarRedis: SET cache key = availability windows
end
availabilityCore --> apiResourcesCalSer: availability windows
apiResourcesCalSer --> Caller: HTTP 200 { availabilityWindows: [...] }
```

## Related

- Architecture dynamic view: `calendarServiceComponents`
- Related flows: [Availability Ingestion and Compilation](availability-ingestion-compilation.md), [Event Consumption Worker](event-consumption-worker.md)
