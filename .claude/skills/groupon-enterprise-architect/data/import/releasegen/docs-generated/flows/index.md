---
service: "releasegen"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Releasegen.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Production Deployment Release Creation](production-deployment-release-creation.md) | synchronous | `POST /deployment/{org}/{repo}/{id}` or background worker | Receives a production Deploybot deployment, finds or creates the GitHub release for the SHA, generates release notes, records deployment status, and links JIRA tickets |
| [Non-Production Deployment Status Recording](non-production-deployment-status.md) | synchronous | `POST /deployment/{org}/{repo}/{id}` or background worker | Receives a non-production deployment, records a GitHub Deployment and DeploymentStatus on the SHA without creating a release |
| [Background Polling Worker](background-polling-worker.md) | scheduled | Worker auto-start at boot; `POST /worker` to trigger manually | Periodically polls JIRA for unprocessed RE-project release tickets, resolves them to Deploybot records, and publishes each deployment |
| [Admin Deployment Reprocessing](admin-deployment-reprocessing.md) | synchronous | Operator action via admin UI or direct API call | Allows operators to manually look up a Deploybot record and reprocess it to backfill or fix existing GitHub releases |
| [Release Note Generation and JIRA Enrichment](release-note-generation.md) | synchronous | Part of production deployment release creation | Generates PR-based release notes, rewrites JIRA ticket references as hyperlinks, and enriches JIRA tickets with labels and remote links |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |
| Composite (scheduled + synchronous) | 1 |

## Cross-Service Flows

The production deployment flow spans Deploybot, Releasegen, GitHub Enterprise, and JIRA. The complete sequence is described in [Production Deployment Release Creation](production-deployment-release-creation.md). The architecture DSL captures the component-level interactions in `components-releasegen-service`.
