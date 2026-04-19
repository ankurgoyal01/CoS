---
service: "proximity-ui"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. Proximity UI is a pure UI and proxy layer. All hotzone, campaign, category, and user data is owned and persisted by `continuumProximityHotzoneApi`. The Node.js/Express server holds no local database connections, no caches, and no file-based storage.

## Stores

> No evidence found in codebase. This service is stateless and does not own any data stores.

## Caches

> No evidence found in codebase.

## Data Flows

All data flows pass through the Express proxy layer to `continuumProximityHotzoneApi`. The proxy layer reads request bodies from the browser, forwards them to the upstream API, and returns the upstream response. No data is stored or transformed locally.
