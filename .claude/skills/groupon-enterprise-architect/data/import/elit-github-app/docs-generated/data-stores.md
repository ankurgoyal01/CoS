---
service: "elit-github-app"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. There is no database, cache, or object storage. All state is held transiently in memory during a single webhook event processing cycle. Scan results are written back to GitHub via the GitHub API (as Check annotations) and are not persisted locally.

## Stores

> No evidence found in codebase. No database, cache, or storage dependencies identified.

## Caches

> No evidence found in codebase. No in-memory or external cache is used.

## Data Flows

Scan results flow exclusively outbound to GitHub Enterprise:

1. Service reads PR diff content from GitHub Enterprise API (per-request, ephemeral).
2. Service reads ELIT rule files from GitHub Enterprise API (per-request, ephemeral).
3. Service writes check run annotations to GitHub Enterprise API (per-request, ephemeral).

No data is persisted by this service.
