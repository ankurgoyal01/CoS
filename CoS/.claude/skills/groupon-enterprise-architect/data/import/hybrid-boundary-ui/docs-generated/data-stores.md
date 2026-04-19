---
service: "hybrid-boundary-ui"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores: []
---

# Data Stores

## Overview

> This service is stateless and does not own any data stores. Hybrid Boundary UI is a browser-side Angular SPA delivered by Nginx. All persistent state — service configuration, endpoint registrations, policies, permissions, and PAR requests — is owned and stored by the downstream Hybrid Boundary API and PAR Automation API services.

## Stores

> Not applicable.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Browser session storage | in-memory (browser) | OIDC tokens and session state managed by `angular-oauth2-oidc` | Session-lifetime |

## Data Flows

All data displayed in the UI is fetched on-demand from the Hybrid Boundary API (`/release/v1`) or PAR Automation API (`/release/par`) over HTTPS/JSON. No client-side persistence beyond the current browser session is used.
