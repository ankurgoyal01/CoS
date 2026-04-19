---
service: "mobilebot"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumMobilebotRedis"
    type: "redis"
    purpose: "Conversation state, release branch cache, multi-turn dialog pairing"
---

# Data Stores

## Overview

Mobilebot uses a single external Redis instance (`continuumMobilebotRedis`) as its only persistent store. Redis provides two primary capabilities: caching the current iOS release branch name (avoiding repeated GitHub API calls) and storing multi-turn conversation state for interactive dialog commands (`mobtool`). There is no relational database or object store.

## Stores

### Mobilebot Redis Cache (`continuumMobilebotRedis`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `continuumMobilebotRedis` |
| Purpose | Conversation state cache and release branch pairing data |
| Ownership | owned |
| Migrations path | Not applicable — schema-less key-value store |

#### Key Entities

| Key | Purpose | Key Fields |
|-----|---------|-----------|
| `mobilebot:internal:ios:current_release_branch` | Caches the most recent iOS release branch name resolved from GitHub Enterprise | String value, e.g. `release/22.12` |
| `hubot-conversation:*` | Multi-turn dialog state managed by `hubot-conversation` library for interactive commands | Conversation context, dialog state |

#### Access Patterns

- **Read**: `store.get(key)` — used by `current_release_branch.js` to check if a branch is already cached before hitting the GitHub API
- **Write**: `store.set(key, value)` — written on branch-cut chat announcements, on `release_branch set`, and after a fresh GitHub API fetch
- **Delete**: `store.remove(key)` — executed on `release_branch reset` to force a GitHub re-fetch
- **Indexes**: Not applicable — flat key-value store

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `mobilebot:internal:ios:current_release_branch` | Redis | Caches current iOS release branch to reduce GitHub API calls | No TTL configured — invalidated by explicit `release_branch reset` command or overwritten by branch-cut events |

## Data Flows

Redis is read and written directly by the `mobilebot_conversationStateStore` component within `continuumMobilebotService`. The Redis connection is established at service startup using the `REDIS_URL` environment variable (on non-macOS hosts). On macOS (local development), `redis.createClient()` connects to the default localhost instance.

There is no CDC, ETL, or replication configured. Redis data is ephemeral relative to service restarts; the release branch key persists across restarts as long as the Redis instance is running.
