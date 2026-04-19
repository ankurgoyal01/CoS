---
service: "mailman"
title: "Health Check Actuator"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "health-check-actuator"
flow_type: synchronous
trigger: "HTTP GET to /manage/info"
participants:
  - "continuumMailmanApiController"
  - "mailmanPostgres"
architecture_ref: "dynamic-mail-processing-flow"
---

# Health Check Actuator

## Summary

This flow handles health and service information requests via the Spring Boot Actuator endpoint at `GET /manage/info`. Load balancers, monitoring systems, and operators use this endpoint to verify that the Mailman service is alive and ready to process requests. The endpoint is provided out of the box by `spring-boot-starter-actuator` and reports service build metadata and connectivity state.

## Trigger

- **Type**: api-call
- **Source**: Load balancer health probe, monitoring system, or operator
- **Frequency**: Periodic (health polling interval determined by infrastructure configuration)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Load balancer / monitoring system / operator | Initiates the health check request | — |
| `continuumMailmanApiController` | Spring Boot Actuator endpoint handles the request | `continuumMailmanApiController` |
| `mailmanPostgres` | Optionally probed for connectivity as part of Actuator health indicators | `mailmanPostgres` |

## Steps

1. **Sends health check request**: Monitoring system or load balancer sends `GET /manage/info`.
   - From: Load balancer / monitoring
   - To: `continuumMailmanService` (Spring Boot Actuator)
   - Protocol: REST/HTTP

2. **Collects health indicators**: Spring Boot Actuator aggregates health indicators — includes build info, and optionally database (`mailmanPostgres`) connectivity status.
   - From: Spring Boot Actuator (internal)
   - To: `mailmanPostgres` (JDBC ping, if DataSource health indicator is enabled)
   - Protocol: JDBC

3. **Returns health response**: Actuator returns a JSON response with service info and health status.
   - From: `continuumMailmanService` (Spring Boot Actuator)
   - To: Load balancer / monitoring
   - Protocol: REST/HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `mailmanPostgres` unreachable | DataSource health indicator reports DOWN | Actuator returns degraded/DOWN status; load balancer may remove instance from rotation |
| Service process unresponsive | No HTTP response | Load balancer marks instance as unhealthy after timeout |

## Sequence Diagram

```
LoadBalancer -> continuumMailmanService: GET /manage/info
continuumMailmanService -> mailmanPostgres: JDBC ping (DataSource health indicator)
mailmanPostgres --> continuumMailmanService: Connection OK
continuumMailmanService --> LoadBalancer: HTTP 200 (health: UP, build info)
```

## Related

- Architecture dynamic view: `dynamic-mail-processing-flow`
- Related flows: [Submit Transactional Email](submit-transactional-email.md)
- Runbook: [Runbook](../runbook.md)
