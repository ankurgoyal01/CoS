---
service: "par-automation"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

PAR Automation is a stateless service. It does not own or manage any database, cache, or persistent storage. All state produced during a PAR request is written to external systems owned by other services:

- **Jira** — PAR and GPROD tickets are created in the `continuumJiraService`; this is the durable record of every request.
- **Hybrid Boundary** — Authorization policy entries are written to `continuumHybridBoundaryLambdaApi`; this is the effective access control state.
- **GCP Secret Manager** — Credentials are read (not written) from `cloudPlatform`.

## Stores

> This service is stateless and does not own any data stores.

## Caches

> No evidence found in codebase. No in-process or external caching is used.

## Data Flows

All data produced by this service flows outbound to external systems:

1. Service metadata is read from Service Portal on every request and held only in memory for the duration of the HTTP handler.
2. PAR and GPROD ticket identifiers received from Jira are returned to the caller in the HTTP response.
3. Authorization policy updates are written directly to Hybrid Boundary; no local copy is retained.
