---
service: "mobilebot"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [http, hubot-chat-adapter]
auth_mechanisms: [internal-room-acl]
---

# API Surface

## Overview

Mobilebot does not expose a public or service-to-service HTTP API. Its interaction surface is entirely chat-command-driven via the Hubot framework, connected to Slack (via the Hubot Slack adapter) and Google Chat (via `@grpn/hubot-gchat-adapter`). Engineers address commands to `@mobilebot` in authorised chat rooms.

One internal HTTP endpoint (`/heartbeat`) is exposed for Kubernetes health-check polling; this is not a consumer-facing API.

## Endpoints

### Health / Liveness

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/heartbeat` | Kubernetes liveness and readiness probe | None (internal cluster only) |

The heartbeat server is started by `scripts/helpers/startup.js` and listens on port 80. It writes a `app.heartbeat` structured log event on each request and returns HTTP 200 with no body.

### Admin Port

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| — | port 8081 | Admin/metrics sidecar port (exposed via Kubernetes service) | None (internal cluster only) |

## Chat Command Surface

Mobilebot's primary interface is chat commands. The following commands are registered via Hubot `robot.respond` and `robot.hear` listeners.

| Command Pattern | Script | Room Restriction | Description |
|----------------|--------|-----------------|-------------|
| `@mobilebot upload {branch}` | `upload_app.js` | `#mobile-ios-release` (iOS) or `#mobile-and-release` (Android) | Triggers CI build and upload to App Store or Play Store |
| `@mobilebot gprod {ios\|android} {Major.Minor[.Patch]} {BuildNumber}` | `gprod_creation.js` | None | Creates a GPROD Jira release ticket |
| `@mobilebot mobtool` | `mobtool.js` | None | Interactive Jira MOBTOOL ticket creation (multi-turn dialog) |
| `@mobilebot oncall` | `oncall.js` | None | Returns both iOS and Android on-call engineers |
| `@mobilebot oncall ios` | `oncall.js` | None | Returns iOS primary on-call engineer from PagerDuty |
| `@mobilebot oncall android` | `oncall.js` | None | Returns Android primary on-call engineer from PagerDuty |
| `@mobilebot appstore_status [groupon\|ls]` | `appstore_status.js` | None | Queries App Store Connect for current iOS app version and status |
| `@mobilebot playstore_status` | `playstore_status.js` | None | Queries Google Play for current Android app version and rollout |
| `@mobilebot release_branch` | `current_release_branch.js` | None | Returns the current cached iOS release branch name |
| `@mobilebot release_branch reset` | `current_release_branch.js` | None | Clears cache and re-fetches from GitHub Enterprise |
| `@mobilebot release_branch set {branch}` | `current_release_branch.js` | None | Manually overrides the cached release branch value |
| `@mobilebot create_patch_from_branch release/{Major.Minor[.Patch]}` | `create_patch_branch.js` | `#mobile-ios-release` only | Triggers Jenkins job to create a patch branch |
| `@mobilebot pick {a},{b},...` | `pick.js` | None | Randomly picks one item from a comma-separated list |
| `@mobilebot help` / `@mobilebot manual` | `help.js` | None | Returns link to Confluence documentation |
| `ship it` (passive hear) | `shipit.js` | None | Posts a random motivational squirrel image (not in thread context) |
| `HURRAY.. New release branch "{branch}" has been cut` (passive hear) | `current_release_branch.js` | None | Automatically updates cached release branch on branch-cut event |

## Request/Response Patterns

### Common headers

> Not applicable — mobilebot communicates through chat adapters, not HTTP request/response cycles.

### Error format

Command errors are returned as inline chat replies using Hubot's `res.reply()`. Error responses include context (e.g., branch name, operation type) and a human-readable description. Errors are also written to the structured log as `app.error` events via `groupon-steno`.

### Pagination

> Not applicable.

## Rate Limits

No rate limiting is configured on mobilebot's command handlers. Upstream rate limits apply at the external API level (Jenkins, Jira, GitHub, PagerDuty).

## Versioning

> Not applicable — mobilebot has no versioned external API.

## OpenAPI / Schema References

From `.service.yml`: `schema: disabled` — no OpenAPI schema is defined or published. All interface contracts are defined by Hubot command regex patterns in the individual script files under `scripts/`.
