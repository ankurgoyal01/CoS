---
service: "releasegen"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

Releasegen is stateless and does not own any data stores. All persistent state is held in the three external systems it integrates with:

- **Deploybot** — authoritative source of deployment records (org, project, SHA, environment, region, timestamps, JIRA ticket references)
- **GitHub** — stores GitHub releases, release bodies, deployment records, and deployment statuses
- **JIRA** — stores RE-project release issue tickets, labels, and remote links to GitHub releases

The service uses no local database, no cache, and no object storage. The background worker maintains only in-memory cursor state (the `since` timestamp used in JIRA polling) that resets on restart.

## Stores

> This service is stateless and does not own any data stores. See [Integrations](integrations.md) for details on the external systems that hold state.

## Caches

> No evidence found in codebase. No caching layer is used.

## Data Flows

- Deploybot deployment records flow into Releasegen via REST API polling and on-demand lookup.
- GitHub release bodies are read, updated, and written by Releasegen on each deployment publication.
- JIRA RE-project tickets are read via JQL search, their labels are updated to `releasegen`, and remote links to GitHub releases are added.
