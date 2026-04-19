---
service: "hybrid-boundary-ui"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

Hybrid Boundary UI is a browser-delivered single-page application. It does not expose an HTTP API surface of its own — it is a pure consumer of downstream APIs (Hybrid Boundary API at `/release/v1` and PAR Automation API at `/release/par`). The Nginx server delivers the compiled Angular application assets to browsers.

> Not applicable — this service exposes no API endpoints. It is a UI that calls external APIs.

## Endpoints

> Not applicable.

## Request/Response Patterns

> Not applicable.

## Rate Limits

> No rate limiting configured.

## Versioning

> Not applicable — versioning is managed by the downstream APIs this UI consumes.

## OpenAPI / Schema References

> Not applicable — see the Hybrid Boundary API and PAR Automation API documentation for their API schemas.
