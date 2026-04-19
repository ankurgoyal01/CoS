---
service: "mygroupons"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. My Groupons holds no persistent state. All data — orders, vouchers, deal metadata, user details — is fetched on demand from downstream Continuum services on each request and is not cached or persisted locally.

## Stores

> Not applicable

## Caches

> No evidence found. No local in-memory or distributed cache is configured in the service.

## Data Flows

> Not applicable. Data flows entirely through synchronous HTTP request orchestration; no ETL, CDC, or replication patterns apply.
