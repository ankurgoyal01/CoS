---
service: "proxykong"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for ProxyKong.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Add Route Request](add-route-request.md) | synchronous | Engineer submits route add form in UI | Creates Jira issue and GitHub PR to add new routes to `api-proxy-config` |
| [Promote Route](promote-route.md) | synchronous | Engineer submits route promote form in UI | Creates Jira issue and GitHub PR to promote staging routes to production |
| [Remove Route](remove-route.md) | synchronous | Engineer submits route delete form in UI | Creates Jira issue and GitHub PR to remove routes from `api-proxy-config` |
| [Delete Experiments](delete-experiments.md) | synchronous | Engineer submits experiment delete form in UI | Creates a GitHub PR to remove experiment configuration entries |
| [Config Refresh](config-refresh.md) | scheduled | Cron job every 10 minutes | Pulls latest master branch of `api-proxy-config` into the container to keep route query data current |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

The route mutation flows (add, promote, delete) all span multiple systems:

- `continuumProxykongService` coordinates `continuumJiraService` (ticket creation) and `githubEnterprise` (PR creation).
- The architecture dynamic view `dynamic-route-change-request-flow` documents the canonical cross-service sequence.
- Route configuration ultimately reaches the API proxy (Kong) infrastructure only after the pull request is merged and deployed by the `api-proxy-config` owners.
