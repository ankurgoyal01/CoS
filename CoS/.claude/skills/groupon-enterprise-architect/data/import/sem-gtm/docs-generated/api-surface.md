---
service: "sem-gtm"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [http]
auth_mechanisms: [container-config-token]
---

# API Surface

## Overview

Both the tagging server and the preview server expose HTTP endpoints on port 8080. The API surface is defined by Google's GTM server-side container runtime — Groupon does not write custom application routes. Clients (browsers, apps) send tag data to the tagging server endpoint; the preview server endpoint is used exclusively by the GTM UI for configuration debugging. The `CONTAINER_CONFIG` environment variable binds each server instance to the correct GTM workspace and authorization credentials.

## Endpoints

### Health / Infrastructure

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/healthz` | Kubernetes liveness and readiness probe | None (internal cluster) |

### Tagging Server (production)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST/GET | `/*` (GTM-defined routes) | Receive tag event data from web/app clients; process via configured GTM tags and triggers | GTM container authentication via `CONTAINER_CONFIG` |

### Preview Server (debug)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET/POST | `/*` (GTM-defined routes) | Accept preview/debug sessions from GTM UI for tag configuration validation | GTM container authentication via `CONTAINER_CONFIG` |

> The specific GTM tag routing paths are defined by the GTM workspace configuration loaded at startup via `CONTAINER_CONFIG` and are not statically enumerable from this repository. See the [Google Tag Manager server-side documentation](https://developers.google.com/tag-platform/tag-manager/server-side/manual-setup-guide) for the full routing specification.

## Request/Response Patterns

### Common headers

> No evidence found in codebase of custom Groupon-defined headers. Standard GTM server-side HTTP headers apply as per Google documentation.

### Error format

> No evidence found in codebase. Error responses follow the GTM cloud image defaults.

### Pagination

> Not applicable — tag requests are single-event, stateless HTTP calls with no pagination.

## Rate Limits

> No rate limiting configured at the application layer. Kubernetes HPA controls scale-out under load (tagging server: min 3, max 6 replicas; preview server: min 1, max 1 replica).

## Versioning

The GTM server-side image is pinned to the `stable` tag (`gcr.io/cloud-tagging-10302018/gtm-cloud-image:stable`). GTM workspace configuration versioning is managed in the Google Tag Manager UI, not in this repository.

## OpenAPI / Schema References

> No evidence found in codebase. This service does not expose or own an OpenAPI/proto schema — the API contract is defined by Google's GTM server-side specification.
