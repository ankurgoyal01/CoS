---
service: "bookingtool"
title: "API Request Lifecycle"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "api-request-lifecycle"
flow_type: synchronous
trigger: "Any inbound HTTP request routed via ?api_screen= query parameter"
participants:
  - "API Consumer (browser / service)"
  - "continuumBookingToolApp"
  - "btControllers"
  - "btDomainServices"
  - "btRepositories"
  - "btIntegrationClients"
  - "continuumBookingToolMySql"
architecture_ref: "dynamic-bookingtool"
---

# API Request Lifecycle

## Summary

This flow documents the canonical request-handling lifecycle for all 84 API endpoints exposed by the Booking Tool. Every request enters the Apache + PHP-FPM stack and is routed to the correct handler by the `?api_screen=` query parameter. The request traverses the component layers — HTTP Controllers, Domain Services, Repositories, and Integration Clients — before a response is returned. This flow describes the cross-cutting concerns (authentication, routing, error handling, metrics) that apply to every endpoint.

## Trigger

- **Type**: api-call
- **Source**: Any consumer (browser UI, internal Continuum service, or integration partner) sending an HTTP request to the Booking Tool base URL
- **Frequency**: Per-request — every API call follows this lifecycle

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Consumer (browser / service) | Initiates HTTP request with `?api_screen=<operation>` | — |
| Booking Tool Application | Receives request via Apache; PHP-FPM processes it | `continuumBookingToolApp` |
| HTTP Controllers | Resolves `api_screen` parameter; validates session/JWT; dispatches to domain handler | `btControllers` |
| Domain Services | Executes business logic; orchestrates repositories and integration clients | `btDomainServices` |
| Repositories | Reads from and writes to MySQL | `btRepositories` |
| Integration Clients | Makes outbound calls to internal and external services as required | `btIntegrationClients` (via `btDomainServices`) |
| Booking Tool MySQL | Provides persistent storage for domain entities | `continuumBookingToolMySql` |

## Steps

1. **Receives HTTP request**: Apache receives inbound HTTP/HTTPS request; PHP-FPM worker is assigned.
   - From: `API Consumer`
   - To: `continuumBookingToolApp`
   - Protocol: HTTPS/REST

2. **Validates authentication**: HTTP Controllers check session token (browser flows) or JWT (service-to-service flows). Okta token validation applied for admin routes.
   - From: `btControllers`
   - To: `btControllers`
   - Protocol: direct

3. **Resolves api_screen parameter**: Controllers read the `?api_screen=` query parameter and select the appropriate request handler class.
   - From: `btControllers`
   - To: `btControllers`
   - Protocol: direct

4. **Invokes domain logic**: Controllers call the relevant Domain Service method, passing validated request parameters.
   - From: `btControllers`
   - To: `btDomainServices`
   - Protocol: direct

5. **Executes business rules**: Domain Services apply domain-specific validation and business logic (availability checks, booking eligibility, etc.).
   - From: `btDomainServices`
   - To: `btDomainServices`
   - Protocol: direct

6. **Queries or writes persistence layer**: Domain Services call Repositories for all MySQL interactions.
   - From: `btDomainServices`
   - To: `btRepositories`
   - Protocol: direct

7. **Executes SQL via Doctrine DBAL**: Repositories execute SQL queries against MySQL.
   - From: `btRepositories`
   - To: `continuumBookingToolMySql`
   - Protocol: SQL/TCP

8. **Calls external/internal services** (if required): Integration Clients perform outbound HTTP calls to Salesforce, Voucher Inventory, Rocketman V2, etc. as the specific use case demands.
   - From: `btIntegrationClients`
   - To: `External / Internal Services`
   - Protocol: HTTPS/REST

9. **Emits metrics**: Domain Services emit operation metrics to InfluxDB via `influxdb-php` (booking counts, latency).
   - From: `btDomainServices`
   - To: `InfluxDB`
   - Protocol: UDP/HTTP

10. **Writes application log**: Monolog writes structured log entries for the request operation.
    - From: `continuumBookingToolApp`
    - To: Log output (stdout / file)
    - Protocol: direct

11. **Returns HTTP response**: Controller serializes the domain result and returns the HTTP response to the caller.
    - From: `btControllers`
    - To: `API Consumer`
    - Protocol: HTTPS/REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unauthenticated request | Controller rejects before dispatching | HTTP 401 |
| Unknown `api_screen` value | Controller returns not-found | HTTP 404 |
| Domain validation failure | Domain Service throws validation exception | HTTP 400 with error detail |
| MySQL connection failure | Repository exception propagates | HTTP 500; error logged via Monolog |
| Upstream service timeout | Guzzle timeout exception caught by Integration Client | HTTP 503 or domain-specific error response |
| Unhandled exception | Global exception handler catches; logs via Monolog | HTTP 500 with generic error message |

## Sequence Diagram

```
APIConsumer -> continuumBookingToolApp: HTTP request ?api_screen=<operation>
continuumBookingToolApp -> btControllers: Dispatch to PHP handler
btControllers -> btControllers: Validate session/JWT auth
btControllers -> btDomainServices: Invoke use case
btDomainServices -> btRepositories: Query / persist domain data
btRepositories -> continuumBookingToolMySql: SQL query (SQL/TCP)
continuumBookingToolMySql --> btRepositories: Result set
btRepositories --> btDomainServices: Domain objects
btDomainServices -> btIntegrationClients: Call external service [if needed]
btIntegrationClients -> ExternalService: HTTPS/REST call
ExternalService --> btIntegrationClients: Response
btIntegrationClients --> btDomainServices: Result
btDomainServices -> InfluxDB: Emit metrics (UDP)
btDomainServices --> btControllers: Domain result
btControllers --> continuumBookingToolApp: Serialized response
continuumBookingToolApp --> APIConsumer: HTTP response
```

## Related

- Architecture dynamic view: `dynamic-bookingtool`
- Related flows: [Customer Book Appointment](customer-book-appointment.md), [Customer Cancel or Reschedule](customer-cancel-reschedule.md), [Merchant Setup Availability](merchant-setup-availability.md), [Admin Authentication via Okta](admin-authentication-okta.md)
