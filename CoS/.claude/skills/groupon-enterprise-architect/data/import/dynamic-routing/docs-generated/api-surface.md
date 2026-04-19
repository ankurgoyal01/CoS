---
service: "dynamic-routing"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest, http]
auth_mechanisms: [spring-security, form-login, http-basic]
---

# API Surface

## Overview

The dynamic-routing service exposes a small REST API via Spring MVC, mounted under the Camel servlet context. The API is consumed by internal tooling and health check systems. The primary operator interface is the JSF admin UI. All REST endpoints return JSON (`application/json`). Spring Security protects the application using form-based login for the UI and HTTP Basic for the REST endpoints; credentials are configured via `app.admin.username` and `app.admin.password` properties.

## Endpoints

### Status

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/status` | Returns service health status, application version, and mbus-client version | Spring Security (configurable) |

### Broker Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/brokers` | Returns a map of all registered brokers with their IDs and metadata | Spring Security |
| `GET` | `/brokers/{brokerId}` | Returns metadata for a single broker by ID | Spring Security |
| `PUT` | `/brokers/{brokerId}` | Registers a new broker entry (create-only; update is rejected with 409 Conflict) | Spring Security |

## Request/Response Patterns

### Common headers
- `Content-Type: application/json` is required on `PUT /brokers/{brokerId}`
- `Accept: application/json` is expected; all endpoints produce `application/json`

### Error format
- `409 Conflict` is returned by `PUT /brokers/{brokerId}` when a broker with the given ID already exists. The response body is a plain string: `"Update operation is not allowed. Broker under submitted ID already exists."`
- Standard Spring MVC error responses are returned for 400/404/500 conditions.

### Pagination
> Not applicable. The broker listing returns all registered brokers in a single response.

## Status Response Shape

```json
{
  "status": "up",
  "version": "<app.version property>",
  "mbusClientVersion": "<mbus-client library version>"
}
```

## Broker Object Shape

```json
{
  "name": "Dublin MasterBroker",
  "address": "10.12.252.57",
  "jolokiaPort": 11200,
  "jolokiaUser": "",
  "jolokiaPassword": "",
  "clientType": "mbus"
}
```

`clientType` values: `"mbus"` (MessageBus/Stomp protocol) or `"jms"` (native JMS/HornetQ or Artemis JMS acceptor).

## Rate Limits

> No rate limiting configured.

## Versioning

No URL-versioning scheme is applied. The single version of the API is determined by the deployed artifact version (`major-minor` is `3.12` as of the reviewed codebase).

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or formal schema files exist in the repository. The REST API is defined entirely by the Spring MVC controller source files:
> - `src/main/java/de/groupon/jms/rest/StatusController.java`
> - `src/main/java/de/groupon/jms/rest/BrokersController.java`
