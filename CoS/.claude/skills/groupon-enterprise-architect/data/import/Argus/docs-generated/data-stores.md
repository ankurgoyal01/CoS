---
service: "argus"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

Argus is stateless and does not own any data stores. All persistent state lives in two places: the YAML alert definition files checked into this Git repository (`src/main/resources/alerts/`), which serve as the source of truth, and the Wavefront SaaS platform, which holds the live alert and dashboard objects that Argus synchronizes to.

## Stores

> This service is stateless and does not own any data stores.

The only "storage" Argus uses is:

| Storage | Type | Role |
|---------|------|------|
| Git repository (`src/main/resources/alerts/**/*.yml`) | File system (YAML) | Source of truth for all alert definitions; read at job runtime |
| Wavefront SaaS (`https://groupon.wavefront.com`) | External SaaS | Live store of alerts and dashboards; read and written via REST API |

## Caches

> No evidence found in codebase. Argus performs no local caching.

## Data Flows

On each CI-triggered run, Argus reads YAML from the local file system, renders it in memory, then pushes the result directly to Wavefront. There is no intermediate storage, no database, and no cache layer.
