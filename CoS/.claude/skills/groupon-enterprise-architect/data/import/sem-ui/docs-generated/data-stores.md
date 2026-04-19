---
service: "sem-ui"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. SEM Admin UI acts purely as a proxy layer — keyword data is owned by SEM Keywords Service, denylist data is owned by SEM Blacklist Service (`continuumSemBlacklistService`), and attribution data is owned by GPN Data API. No in-process caches or session stores are maintained.

## Stores

> Not applicable

## Caches

> Not applicable

## Data Flows

All data originates from and is persisted to downstream services. The UI layer only transforms API responses for browser rendering.
