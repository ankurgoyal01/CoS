---
service: "autocomplete"
title: "Health Check Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "health-check-flow"
flow_type: synchronous
trigger: "HTTP GET /healthcheck/client/databreakers from monitoring or load balancer"
participants:
  - "continuumAutocompleteService"
  - "healthCheckResource"
  - "dataBreakersServiceClient"
  - "dataBreakers"
architecture_ref: "autocompleteRequestRuntimeFlow"
---

# Health Check Flow

## Summary

This flow handles requests to `GET /healthcheck/client/databreakers`, which validates that the autocomplete service can reach its most critical external dependency — DataBreakers. The endpoint is intended for use by monitoring infrastructure and load balancer health probes. The response indicates whether the DataBreakers client is healthy or degraded.

## Trigger

- **Type**: api-call
- **Source**: Monitoring infrastructure, load balancer health probe, or operator
- **Frequency**: Periodic (interval driven by external monitoring configuration)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Autocomplete Service | Container hosting the health check endpoint | `continuumAutocompleteService` |
| HealthCheckResource | Receives the health check HTTP request and returns status | `healthCheckResource` |
| DataBreakersServiceClient | Performs the connectivity probe against DataBreakers | `dataBreakersServiceClient` |
| DataBreakers | External dependency being health-checked | `dataBreakers` (stub) |

## Steps

1. **Receives health check request**: Monitoring agent or load balancer sends `GET /healthcheck/client/databreakers`.
   - From: Monitoring / load balancer
   - To: `healthCheckResource`
   - Protocol: HTTP

2. **Probes DataBreakers connectivity**: `HealthCheckResource` invokes `DataBreakersServiceClient` to test connectivity and response validity.
   - From: `healthCheckResource`
   - To: `dataBreakersServiceClient`
   - Protocol: direct (in-process)

3. **Calls DataBreakers**: `DataBreakersServiceClient` performs an outbound HTTPS probe to the DataBreakers API endpoint.
   - From: `dataBreakersServiceClient`
   - To: `dataBreakers`
   - Protocol: HTTPS

4. **Returns health status**: `HealthCheckResource` returns HTTP 200 (healthy) or a non-2xx status (unhealthy) based on the DataBreakers probe result.
   - From: `healthCheckResource`
   - To: Monitoring / load balancer
   - Protocol: HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| DataBreakers unreachable | `DataBreakersServiceClient` catches exception | Health check returns unhealthy status; monitoring alert fires |
| DataBreakers returns error response | Treated as unhealthy | Health check returns unhealthy status |

## Sequence Diagram

```
Monitoring -> HealthCheckResource: GET /healthcheck/client/databreakers
HealthCheckResource -> DataBreakersServiceClient: probe()
DataBreakersServiceClient -> DataBreakers: HTTPS health probe
DataBreakers --> DataBreakersServiceClient: response
DataBreakersServiceClient --> HealthCheckResource: healthy / unhealthy
HealthCheckResource --> Monitoring: HTTP 200 OK (healthy) or 5xx (unhealthy)
```

## Related

- Architecture dynamic view: `autocompleteRequestRuntimeFlow`
- Related flows: [Autocomplete Search Request](autocomplete-search-request.md)
