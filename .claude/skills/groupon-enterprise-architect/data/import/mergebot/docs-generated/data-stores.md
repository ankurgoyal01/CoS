---
service: "mergebot"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

Mergebot is a stateless service and does not own any persistent data stores. All state required for merge decisions — PR metadata, review counts, commit statuses, committer identities, and repository configuration — is fetched live from the GitHub Enterprise API on each webhook event. Repository-level configuration is read from `.ghe-bot.yml` on the repository's default branch via the GitHub API and cached in-process for the lifetime of a single request.

## Stores

> This service is stateless and does not own any data stores.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `@configs` (in-memory) | in-memory Ruby Hash | Per-request cache of fetched `.ghe-bot.yml` configuration, keyed by `repo_name`. Avoids redundant GitHub API calls within a single webhook processing cycle. | Request lifetime only (not persisted across requests) |

## Data Flows

All data flows are pull-based and initiated per-webhook event:

1. Mergebot receives a GitHub webhook POST.
2. `mergebot_repoConfigLoader` fetches `.ghe-bot.yml` from the repository's default branch via `GithubApi::Client.contents`.
3. `mergebot_githubClientAdapter` fetches the PR object, commit list, commit statuses, issue comments, and PR reviews from GitHub Enterprise API.
4. All data is evaluated in-process and discarded after the response is returned.
5. No data is written to any Mergebot-owned store. The only write operations are GitHub API calls (merge PR, delete branch ref) and Slack API calls (post message).
