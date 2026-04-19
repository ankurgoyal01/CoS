---
service: "mbus-sigint-frontend"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. It holds no database connections, no persistent cache, and no file storage. All state — including MessageBus configuration, change requests, cluster data, and deploy schedules — is owned and persisted by the `mbus-sigint-config` backend service. The frontend server acts purely as an API proxy and SPA host.

## Stores

> Not applicable. This service owns no data stores.

## Caches

> No evidence found in codebase.

## Data Flows

All data that appears in the UI originates from and is persisted to `mbus-sigint-config` via HTTPS API calls. No ETL, CDC, or replication pipelines exist within this service.
