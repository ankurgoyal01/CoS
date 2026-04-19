---
service: "online_booking_3rd_party"
title: "Sanity Check"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "sanity-check"
flow_type: synchronous
trigger: "Manual invocation or monitoring system health probe"
participants:
  - "continuumOnlineBooking3rdPartyApi"
  - "continuumOnlineBooking3rdPartyMysql"
  - "continuumOnlineBooking3rdPartyRedis"
  - "continuumAppointmentsEngine"
  - "continuumAvailabilityEngine"
architecture_ref: "dynamic-merchant-mapping-request-flow"
---

# Sanity Check

## Summary

The sanity check flow is a smoke-test mechanism that verifies the end-to-end integration health of the `online_booking_3rd_party` service. When `GET /v3/smoke_tests` is called, the API performs lightweight checks against all critical dependencies — MySQL, Redis, and key downstream services — and returns a structured health summary. This is used by monitoring systems and operators to confirm the service is operational before or after deployments.

## Trigger

- **Type**: api-call / manual
- **Source**: Monitoring system or operator calling `GET /v3/smoke_tests`
- **Frequency**: On-demand (ad-hoc or as part of a monitoring probe schedule)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Public API Endpoints | Receives smoke test request and orchestrates checks | `continuumOnlineBooking3rdPartyApi` / `apiPublicEndpoints` |
| MySQL | Checked for connectivity and responsiveness | `continuumOnlineBooking3rdPartyMysql` |
| Redis | Checked for connectivity and responsiveness | `continuumOnlineBooking3rdPartyRedis` |
| Appointments Engine | Checked for API reachability | `continuumAppointmentsEngine` |
| Availability Engine | Checked for API reachability | `continuumAvailabilityEngine` |

## Steps

1. **Receive Smoke Test Request**: Monitoring system or operator calls `GET /v3/smoke_tests`
   - From: Caller (monitoring system / operator)
   - To: `continuumOnlineBooking3rdPartyApi` / `apiPublicEndpoints`
   - Protocol: HTTP/JSON

2. **Check MySQL Connectivity**: Executes a lightweight query (e.g., `SELECT 1`) against the primary database
   - From: `apiPublicEndpoints`
   - To: `continuumOnlineBooking3rdPartyMysql`
   - Protocol: ActiveRecord/MySQL

3. **Check Redis Connectivity**: Executes a Redis PING to verify Resque queue backend is reachable
   - From: `apiPublicEndpoints`
   - To: `continuumOnlineBooking3rdPartyRedis`
   - Protocol: Redis

4. **Check Appointments Engine Reachability**: Makes a lightweight GET to verify Appointments Engine API is accessible
   - From: `apiPublicEndpoints`
   - To: `continuumAppointmentsEngine`
   - Protocol: HTTP/JSON

5. **Check Availability Engine Reachability**: Makes a lightweight GET to verify Availability Engine API is accessible
   - From: `apiPublicEndpoints`
   - To: `continuumAvailabilityEngine`
   - Protocol: HTTP/JSON

6. **Return Health Summary**: Aggregates check results and returns HTTP 200 (all healthy) or HTTP 500 (one or more checks failed)
   - From: `continuumOnlineBooking3rdPartyApi`
   - To: Caller
   - Protocol: HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MySQL unreachable | Check marked failed | HTTP 500 with MySQL failure in response body |
| Redis unreachable | Check marked failed | HTTP 500 with Redis failure in response body |
| Downstream service timeout | Check marked failed | HTTP 500 with service name in failure details |
| Partial failure | All checks run regardless; failures aggregated | HTTP 500 with list of failed checks |

## Sequence Diagram

```
Caller -> apiPublicEndpoints: GET /v3/smoke_tests
apiPublicEndpoints -> continuumOnlineBooking3rdPartyMysql: SELECT 1 (connectivity check)
continuumOnlineBooking3rdPartyMysql --> apiPublicEndpoints: OK / Error
apiPublicEndpoints -> continuumOnlineBooking3rdPartyRedis: PING
continuumOnlineBooking3rdPartyRedis --> apiPublicEndpoints: PONG / Error
apiPublicEndpoints -> continuumAppointmentsEngine: GET health check endpoint
continuumAppointmentsEngine --> apiPublicEndpoints: OK / Error
apiPublicEndpoints -> continuumAvailabilityEngine: GET health check endpoint
continuumAvailabilityEngine --> apiPublicEndpoints: OK / Error
apiPublicEndpoints --> Caller: HTTP 200 (all healthy) or HTTP 500 (failures listed)
```

## Related

- Related flows: [Authorization Flow](authorization-flow.md), [Service Mapping Lifecycle](service-mapping-lifecycle.md)
