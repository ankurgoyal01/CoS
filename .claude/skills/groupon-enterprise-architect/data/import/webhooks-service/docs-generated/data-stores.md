---
service: "webhooks-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. All durable state is held in the downstream systems the service integrates with: GitHub Enterprise (repository and PR state), Jira Cloud (issue state and sprint data), Slack (message history), and Jenkins CI (build records). The `OWNERS_MANUAL.md` explicitly confirms: "No data storage for this service."

## Stores

> No evidence found in codebase. No databases, object storage, or persistent stores are owned or managed by this service.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| In-process request context | in-memory | AsyncLocalStorage context holding GitHub event metadata (event ID, event name, repo owner/repo, PR number) for structured log correlation within a single request | Request lifetime only |

The `OWNERS_MANUAL.md` confirms: "This service does not cache any information" in the external sense. The only in-memory state is the per-request logging context implemented via Node.js `AsyncLocalStorage` in `webhooks/src/utils/req-ctx.ts`.

## Data Flows

Data flows through this service in a single-request pipeline:

1. GitHub Enterprise delivers a webhook payload over HTTP POST
2. The service reads `.webhooks.yml` configuration from GitHub (in-request, not cached across requests)
3. Hook implementations read additional data from GitHub, Jira, or CI as needed
4. Hook implementations write outputs to GitHub (comments, labels, statuses, branches), Slack (messages), Jira (transitions, links, comments), or Jenkins (build triggers)
5. No data is persisted within the service between requests
