---
service: "doorman"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["rest", "saml2", "form-post"]
auth_mechanisms: ["saml2", "api-key"]
---

# API Surface

## Overview

Doorman exposes a small set of HTTP endpoints that implement the SAML 2.0 Service Provider flow. Internal tool users arrive via browser redirect, complete Okta authentication, and Doorman delivers a signed token to the destination tool via HTTP form POST. The API is not a general-purpose REST API — it is purpose-built for the SAML SSO browser flow. All endpoints serve HTTP on port 3180.

## Endpoints

### Authentication

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/authentication/initiation/:destination_id` | Initiates SAML authentication for the given registered destination; validates that `destination_id` is in the configured destinations registry, then redirects to Okta SAML SSO URL with a RelayState carrying the destination context | None (browser redirect) |
| `POST` | `/okta/saml/sso` | SAML Assertion Consumer Service (ACS) endpoint; receives Okta callback with `SAMLResponse` and `RelayState`; calls Users Service to validate the SAML assertion and obtain a token; renders an auto-submitting HTML form that POSTs the token to the destination tool | Validated by Okta SAML response |

### Status and Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/grpn/healthcheck` | Load balancer health check; returns `200` if `heartbeat.txt` exists on disk, `503` otherwise | None |
| `GET` | `/ping` | Simple liveness check; returns `{"reply":"ack"}` | None |
| `GET` | `/status` | Runtime status; returns JSON with `bootedAt`, `environment`, `serverTime`, `sha`, `version` | None |
| `GET` | `/status.json` | Alias for `/status` | None |

### Test Destination (all environments)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/test_destination` | Redirects to `/authentication/initiation/test-destination`; used for local and staging flow verification | None |
| `POST` | `/test_destination` | Receives a token or error from the SSO postback; displays result for verification | Doorman-issued token |

## Request/Response Patterns

### Common headers

- Outbound requests to Users Service include `X-Api-Key` (configured per environment) and `User-Agent: Doorman`.
- SAML SSO callback from Okta: `Content-Type: application/x-www-form-urlencoded` with `SAMLResponse` (Base64-encoded XML) and `RelayState` (JSON string containing `destinationId` and optional `destinationPath`).

### Error format

- `GET /authentication/initiation/:destination_id` with an unregistered `destination_id`: returns `404 not found` (plain text).
- `POST /okta/saml/sso` with missing `SAMLResponse` or `RelayState`: returns `400 bad request` (plain text).
- Authentication failures (Users Service returns non-200): Doorman renders the SSO postback form with an HTML-escaped error message in the `error` hidden field instead of a `token`.
- Unhandled exceptions are caught by the `LastChanceForRescue` middleware.

### Pagination

> Not applicable. Doorman has no paginated endpoints.

## Rate Limits

> No rate limiting configured.

## Versioning

Doorman does not use API versioning. The authentication flow is a single-version browser-driven SAML exchange. The token format supports versions `0` and `1`; all newly issued tokens use version `1`.

## OpenAPI / Schema References

The `.service.yml` references `doc/openapi.yml` as the OpenAPI schema path, but no `doc/openapi.yml` file was found in the repository. No formal OpenAPI specification is available.
