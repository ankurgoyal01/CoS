---
service: "authoring2"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 1
---

# Integrations

## Overview

Authoring2 has one outbound service integration: it calls `continuumTaxonomyService` via HTTP PUT to activate snapshot content into the live serving tier. All other interactions are with owned infrastructure (PostgreSQL database and ActiveMQ sidecar). Upstream consumers are internal taxonomy content authors using the bundled Ember.js UI.

## External Dependencies

> No evidence found in codebase. No external third-party API integrations are present.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `continuumTaxonomyService` | HTTP PUT | Activate full or partial snapshots into the live taxonomy serving tier | `continuumTaxonomyService` (stub) |

### continuumTaxonomyService Detail

- **Protocol**: HTTP
- **Base URL (full snapshot activation)**: `deploy.live.activation_ep` = `http://taxonomyv2.production.service/snapshots/activate` (from `deploy.production.properties`)
- **Base URL (partial snapshot activation)**: `pt_deploy.live.activation_ep` = `http://taxonomyv2.production.service/partialsnapshots/liveactivate` (from `deploy.production.properties`)
- **Auth**: No explicit auth mechanism found in codebase (plain HTTP client via Apache HttpComponents)
- **Purpose**: When a snapshot is certified and ready for live deployment, Authoring2 sends an HTTP PUT request carrying the snapshot UUID. TaxonomyV2 loads that snapshot into its RaaS serving database.
- **Failure mode**: If the activation call returns a non-200 status, Authoring2 returns HTTP 500 to the calling user and does not update the snapshot deploy status. No retry logic is implemented.
- **Circuit breaker**: No evidence found in codebase.

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Taxonomy content authors (Ember.js UI) | HTTP/REST (browser) | Day-to-day taxonomy management via the authoring tool at `https://taxonomy-authoringv2.groupondev.com` |

> Upstream consumers are tracked in the central architecture model. GAPI and LPAPI consume taxonomy data indirectly via `continuumTaxonomyService`, not directly from Authoring2.

## Dependency Health

- **continuumTaxonomyService**: Checked implicitly by the HTTP response code of the activation PUT call. No dedicated health probe or circuit breaker is configured. If TaxonomyV2 is unavailable at deploy time, the deploy attempt fails with an error response; the snapshot remains in its current deploy status and can be retried manually.
- **PostgreSQL (DaaS)**: The application's readiness probe (`GET /props`) exercises the Tomcat application context. No explicit DB health check endpoint is configured in code; DB availability is a hard dependency — all API endpoints will fail if the DB is unreachable.
- **ActiveMQ sidecar**: ActiveMQ readiness is probed via a TCP socket check on port 61616 with a 180-second initial delay (defined in `.meta/deployment/cloud/components/app/common.yml`).
