---
service: "wolf-hound"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores: []
---

# Data Stores

## Overview

Wolfhound Editor UI is stateless and does not own any data stores. All editorial content, scheduling entries, template definitions, taxonomy records, and user/group data are persisted by downstream services — primarily `continuumWolfhoundApi`. This service acts purely as a BFF layer that reads from and writes to those services over HTTP.

## Stores

> This service is stateless and does not own any data stores.

## Caches

> No evidence found for any caching layer (Redis, Memcached, or in-memory) within this service.

## Data Flows

All data originates from or is written to downstream services:

- **Editorial pages and templates** — read and written via `continuumWolfhoundApi`
- **User and group data** — read from `continuumWhUsersApi`
- **LPAPI rules and pages** — read and written via `continuumLpapiService`
- **Image and tag metadata** — read from `continuumMarketingEditorialContentService`
- **Deal divisions and details** — read from `continuumMarketingDealService`
- **Cluster rules and content** — read from `continuumDealsClusterService`
- **Relevance search results** — read from `continuumRelevanceApi`
- **Geoplace division metadata** — read from `continuumBhuvanService`
