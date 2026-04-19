---
service: "webhooks-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Developer Tooling / Mobile Engineering"
platform: "Continuum"
team: "iOS Platform and Performance"
status: active
tech_stack:
  language: "TypeScript"
  language_version: "4.2.4"
  framework: "Node.js native HTTP"
  framework_version: "14.13.1"
  runtime: "Node.js"
  runtime_version: "14.13.1"
  build_tool: "npm + tsc"
  package_manager: "npm"
---

# Mobile Webhooks Service Overview

## Purpose

The Mobile Webhooks Service receives GitHub Enterprise webhook events and executes per-repository automation workflows configured in `.webhooks.yml` files. It bridges GitHub Enterprise, Slack, Jira, and Jenkins CI to automate repetitive development tasks such as PR label management, branch auto-merge, Jira issue transitions, and Slack notifications. The service removes the need for engineers to manually perform recurring PR and CI operations by reacting to GitHub events in real time.

## Scope

### In scope

- Receiving and verifying inbound GitHub webhook payloads at the `/uber` endpoint
- Loading per-repository `.webhooks.yml` configuration from the triggering repository (or org-level fallback)
- Routing GitHub events (`pull_request`, `status`, `issue_comment`, `push`, etc.) to registered hook implementations
- Executing hook implementations in parallel with isolated failure handling
- Slack direct messages and channel notifications for PR reviews, mentions, and build statuses
- Jira issue state transitions triggered by PR lifecycle events (open, merge, close)
- Jenkins CI job triggering via labels or PR events, and posting build artifact links back to PRs
- GitHub PR management: auto-merge, auto-create back-merge PRs, branch deletion after merge, label management, path monitoring, and target branch validation

### Out of scope

- Storing persistent state or data (the service is stateless)
- Authentication / authorization of Groupon engineers (handled by GitHub Enterprise)
- Managing GitHub webhook configuration on repositories or organizations (manual setup by repo owners)
- CI job orchestration beyond triggering and status reporting

## Domain Context

- **Business domain**: Developer Tooling / Mobile Engineering
- **Platform**: Continuum
- **Upstream consumers**: GitHub Enterprise (delivers webhook payloads); configured as `http://webhook-vip.snc1/uber`
- **Downstream dependencies**: GitHub Enterprise REST API, Slack Web API, Jira REST API (`rest/api/2`), Jenkins CI (DotCI and Cloud Jenkins)

## Stakeholders

| Role | Description |
|------|-------------|
| iOS Platform and Performance Team | Service owners; develop and maintain hook implementations |
| Mobile Repository Owners | Configure `.webhooks.yml` to enable automations for their repos |
| Mobile Release Engineering | On-call for alerting; paged via PagerDuty on infrastructure issues |
| da-alerts@groupon.com | SRE alert notification list |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | TypeScript | 4.2.4 | `webhooks/package.json` devDependencies |
| Runtime | Node.js | 14.13.1-alpine3.11 | `Dockerfile` FROM line |
| HTTP server | Node.js native `http` module | 14.x | `webhooks/src/hookListener/index.ts` |
| Build tool | npm + tsc | — | `Dockerfile` RUN commands |
| Package manager | npm | — | `webhooks/package-lock.json` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `@octokit/rest` | ^18.10.0 | http-client | GitHub Enterprise REST API client |
| `@octokit/webhooks` | ^9.15.1 | http-framework | Webhook signature verification and event dispatch |
| `@octokit/plugin-paginate-rest` | ^2.16.0 | http-client | Auto-pagination for GitHub list endpoints |
| `@octokit/plugin-retry` | ^3.0.9 | http-client | Automatic retry for transient GitHub API errors |
| `@slack/web-api` | ^5.11.0 | message-client | Slack Web API for DM and channel notifications |
| `axios` | ^0.20.0 | http-client | HTTP client for Jira REST API and Jenkins CI API |
| `js-yaml` | ^3.14.0 | serialization | Parsing `.webhooks.yml` configuration files |
| `io-ts` | ^2.2.10 | validation | Runtime type validation of hook configuration shapes |
| `fp-ts` | ^2.8.2 | validation | Functional helpers for io-ts decode pipelines |
| `lodash` | ^4.17.20 | utility | Deep get, filter, and collection utilities throughout |
| `moment-timezone` | ^0.5.31 | utility | Timezone-aware timestamps appended to edited comments |
| `picomatch` | ^2.2.2 | utility | Glob path matching for `pr_path_monitor` hook |
| `groupon-steno` | ^3.6.0 | logging | Structured event logging (Steno format) |
| `itier-instrumentation` | ^9.8.1 | metrics | Metrics and instrumentation reporting |
| `dotenv` | ^8.2.0 | config | Loading `.env` files in local development |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `webhooks/package.json` for a full list.
