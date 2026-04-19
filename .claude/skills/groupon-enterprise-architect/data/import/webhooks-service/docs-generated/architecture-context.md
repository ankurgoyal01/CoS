---
service: "webhooks-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: ["continuumWebhooksService"]
---

# Architecture Context

## System Context

The Mobile Webhooks Service sits within the Continuum platform as a backend automation bridge for engineering workflows. GitHub Enterprise delivers all repository events to the service's `/uber` HTTP endpoint. The service reads per-repository `.webhooks.yml` configuration from GitHub, routes events to enabled hook implementations, and fans out to Slack (for notifications), Jira Cloud (for issue transitions and links), and Jenkins CI (for build triggering and artifact reporting). The service has no persistent data store and holds no user-facing state — all durable state lives in GitHub, Jira, and Slack.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Webhooks Service | `continuumWebhooksService` | Backend | Node.js, TypeScript | 14.13.1 | Receives GitHub webhook events and executes configured automations for PR workflows, CI actions, Slack notifications, and Jira updates. |

## Components by Container

### Webhooks Service (`continuumWebhooksService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| HTTP Listener (`webhookSvc_httpEndpoint`) | Accepts inbound GitHub webhook requests on `/uber`; verifies HMAC signatures before dispatch; serves `/heartbeat` for health checks | Node.js HTTP Server, `@octokit/webhooks` |
| Webhook Router (`webhookSvc_router`) | Builds event-to-hook mapping at startup; dispatches enabled hooks for each incoming event type; runs all matching hooks concurrently via `Promise.allSettled` | TypeScript Router |
| Config Resolver (`webhookSvc_configLoader`) | Loads and parses `.webhooks.yml` from the triggering ref, the default branch, or the org-level `{org}/.webhooks` repository as fallback | `js-yaml`, `io-ts` Config Utility |
| Hook Executor (`webhookSvc_hookExecutor`) | Runs configured hook implementations; aggregates and logs errors; ensures a single hook failure does not prevent other hooks from running | Hook Runtime |
| GitHub Client (`webhookSvc_githubClient`) | Wraps GitHub Enterprise API operations: PRs, labels, branches, comments, statuses, teams, users | `@octokit/rest` with paginate and retry plugins |
| Slack Client (`webhookSvc_slackClient`) | Resolves GitHub usernames to Slack user IDs via email; sends direct messages and room notifications | `@slack/web-api` |
| Jira Client (`webhookSvc_jiraClient`) | Queries issue state and sprint data; transitions issues; posts comments and remote links | `axios` against Jira REST API v2 |
| CI Client (`webhookSvc_ciClient`) | Triggers Jenkins build jobs with parameters; polls for matching build execution; retrieves build JSON status | `axios` against Jenkins JSON API |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `webhookSvc_httpEndpoint` | `webhookSvc_router` | Forwards validated webhook payloads | Internal TypeScript call |
| `webhookSvc_router` | `webhookSvc_configLoader` | Loads per-repository hook configuration | Internal TypeScript call |
| `webhookSvc_router` | `webhookSvc_hookExecutor` | Invokes enabled hooks for the event | Internal TypeScript call |
| `webhookSvc_hookExecutor` | `webhookSvc_githubClient` | Calls GitHub APIs for PR/repo workflows | GitHub REST API via Octokit |
| `webhookSvc_hookExecutor` | `webhookSvc_slackClient` | Publishes user and room notifications | Slack Web API (HTTPS) |
| `webhookSvc_hookExecutor` | `webhookSvc_jiraClient` | Reads and updates Jira issues | Jira REST API v2 (HTTPS) |
| `webhookSvc_hookExecutor` | `webhookSvc_ciClient` | Triggers builds and retrieves build metadata | Jenkins JSON API (HTTP) |
| `webhookSvc_configLoader` | `webhookSvc_githubClient` | Reads `.webhooks.yml` content from repositories | GitHub REST API via Octokit |
| `continuumWebhooksService` | `slack` | Sends direct messages and channel notifications | Slack Web API |

## Architecture Diagram References

- Container: `containers-continuum`
- Component: `components-continuum-webhooks-service-components`
