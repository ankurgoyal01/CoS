---
service: "seer-frontend"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. Seer Frontend is a pure browser SPA — it fetches data at runtime from the `seer-service` backend API and renders it into charts. No database connections, cache clients, or file-system writes are performed by this application.

## Stores

> Not applicable. No data stores are owned or accessed directly by this service.

## Caches

> Not applicable. No server-side caching layer is present. The browser may cache HTTP responses according to standard HTTP cache-control headers set by the backend, but this is not managed by the frontend.

## Data Flows

All metric data is sourced on demand from the `seer-service` backend via `/api/*` REST calls at page load and on user filter interaction. No ETL, CDC, or replication processes exist at the frontend layer.
