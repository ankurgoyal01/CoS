---
service: "optimus-prime-ui"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

Optimus Prime UI is a stateless single-page application. It does not own or directly connect to any database, cache, or persistent storage system. All domain data (jobs, connections, workspaces, runs, datafetchers, dataloaders) is fetched from and written to the `optimus-prime-api` backend via HTTPS/JSON calls. State persists only in-memory within the Pinia stores for the lifetime of the browser session.

> This service is stateless and does not own any data stores.

## Stores

> Not applicable. No data stores are owned or directly accessed by this service.

## Caches

> Not applicable. No caching layer is used. Browser-standard HTTP caching is configured via nginx `Cache-Control` headers:
> - Static assets (CSS, JS, PNG, ICO, TXT, SVG, GIF): `Cache-Control: public, max-age=31536000, immutable`
> - HTML files: `Cache-Control: no-cache`

## Data Flows

All data flows pass through the `optimus-prime-api` backend service. The UI reads and writes data exclusively via the API Client Layer (`continuumOptimusPrimeUiApiClient`). The backend owns all persistence, ETL execution state, and connection credential storage.

Connection credentials entered by users in the UI (for MySQL, Teradata, SFTP, PostgreSQL, Hive, etc.) are transmitted to `optimus-prime-api` and stored there — never persisted client-side.
