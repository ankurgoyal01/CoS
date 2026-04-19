---
service: "service-portal"
title: "GitHub Repository Validation and Sync"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "github-repository-validation-and-sync"
flow_type: event-driven
trigger: "GitHub Enterprise webhook event (push or pull_request) delivered to POST /processor"
participants:
  - "continuumServicePortalWeb"
  - "continuumServicePortalWorker"
  - "continuumServicePortalDb"
  - "continuumServicePortalRedis"
  - "GitHub Enterprise"
---

# GitHub Repository Validation and Sync

## Summary

When a push or pull_request event occurs in GitHub Enterprise, a webhook is delivered to the Service Portal `/processor` endpoint. The web process verifies the HMAC signature, identifies the relevant service record, and enqueues a `GitHubSyncWorker` job. The worker then fetches updated repository metadata from the GitHub Enterprise REST API and syncs it to the MySQL service catalog. This flow also underpins the `service.yml` validation capability used by CI pipelines.

## Trigger

- **Type**: event (inbound webhook)
- **Source**: GitHub Enterprise (push or pull_request event delivered to `/processor`)
- **Frequency**: On each push or pull_request event in a linked repository

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GitHub Enterprise | Delivers webhook event; provides REST API for repo metadata | external system |
| Rails Web App | Receives webhook; verifies HMAC; enqueues sync job | `continuumServicePortalWeb` |
| Redis | Holds the enqueued GitHubSyncWorker job | `continuumServicePortalRedis` |
| Sidekiq Worker | Dequeues sync job; fetches repo metadata; updates catalog | `continuumServicePortalWorker` |
| MySQL Database | Target for updated repository metadata | `continuumServicePortalDb` |

## Steps

1. **Receive webhook event**: GitHub Enterprise delivers a `push` or `pull_request` event as an HTTP POST to `/processor`.
   - From: GitHub Enterprise
   - To: `continuumServicePortalWeb`
   - Protocol: HTTPS (GitHub webhook)

2. **Verify HMAC signature**: Web app extracts the `X-Hub-Signature-256` header and verifies it against the `GITHUB_WEBHOOK_SECRET`. Requests failing verification are rejected.
   - From: `continuumServicePortalWeb`
   - To: `continuumServicePortalWeb` (internal HMAC check)
   - Protocol: direct

3. **Parse event payload**: Web app extracts repository name, branch, and event type from the webhook JSON payload.
   - From: `continuumServicePortalWeb`
   - To: `continuumServicePortalWeb`
   - Protocol: direct

4. **Resolve service record**: Web app queries `continuumServicePortalDb` to find the service record associated with the repository.
   - From: `continuumServicePortalWeb`
   - To: `continuumServicePortalDb`
   - Protocol: MySQL (ActiveRecord)

5. **Enqueue sync job**: Web app enqueues a `GitHubSyncWorker` job with the repository identifier and event context.
   - From: `continuumServicePortalWeb`
   - To: `continuumServicePortalRedis`
   - Protocol: Redis protocol (Sidekiq client)

6. **Return 200 acknowledgement**: Web app responds HTTP 200 to GitHub Enterprise to acknowledge receipt.
   - From: `continuumServicePortalWeb`
   - To: GitHub Enterprise
   - Protocol: HTTPS

7. **Dequeue sync job**: Sidekiq worker dequeues the `GitHubSyncWorker` job.
   - From: `continuumServicePortalRedis`
   - To: `continuumServicePortalWorker`
   - Protocol: Redis protocol

8. **Fetch repository metadata from GitHub API**: Worker calls the GitHub Enterprise REST API to retrieve current repository metadata (branch protection rules, CI status, contributors, repository settings).
   - From: `continuumServicePortalWorker`
   - To: GitHub Enterprise
   - Protocol: HTTPS REST via Faraday (authenticated with `GITHUB_API_TOKEN`)

9. **Update service catalog**: Worker writes updated repository metadata to the relevant tables in `continuumServicePortalDb` (upsert semantics).
   - From: `continuumServicePortalWorker`
   - To: `continuumServicePortalDb`
   - Protocol: MySQL (ActiveRecord)

### service.yml Validation (CI pipeline variant)

CI pipelines may call `POST /validation/service.yml/validate` directly (not via webhook) to validate a `service.yml` file before merging. The web app parses the uploaded file and returns validation pass/fail without persisting data.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid HMAC signature | Request rejected immediately | HTTP 401; webhook delivery logged as failed in GitHub |
| Service record not found for repository | Web app logs warning; no sync job enqueued | HTTP 200 (acknowledged to GitHub); catalog not updated |
| GitHub API rate limit exceeded | Faraday receives 429; Sidekiq job retried with backoff | Sync delayed until rate limit window resets |
| GitHub API unavailable | Faraday timeout/error; Sidekiq job fails | Job retried; stale metadata persists until sync succeeds |
| MySQL write failure during sync | Sidekiq job fails; retried | Sync delayed; no partial writes assumed |

## Sequence Diagram

```
GitHub Enterprise -> continuumServicePortalWeb: POST /processor (push event + X-Hub-Signature-256)
continuumServicePortalWeb -> continuumServicePortalWeb: verify HMAC signature
continuumServicePortalWeb -> continuumServicePortalDb: SELECT service WHERE repo = {repo_name}
continuumServicePortalDb --> continuumServicePortalWeb: service record
continuumServicePortalWeb -> continuumServicePortalRedis: LPUSH GitHubSyncWorker job
continuumServicePortalRedis --> continuumServicePortalWeb: job enqueued
continuumServicePortalWeb --> GitHub Enterprise: 200 OK
continuumServicePortalRedis -> continuumServicePortalWorker: dequeue GitHubSyncWorker
continuumServicePortalWorker -> GitHub Enterprise: GET /repos/{owner}/{repo} (REST API)
GitHub Enterprise --> continuumServicePortalWorker: repository metadata
continuumServicePortalWorker -> continuumServicePortalDb: UPSERT service metadata
continuumServicePortalDb --> continuumServicePortalWorker: metadata updated
```

## Related

- Architecture dynamic view: `dynamic-github-sync`
- Related flows: [Service Registration and Metadata Sync](service-registration-and-metadata-sync.md), [Scheduled Service Checks Execution](scheduled-service-checks-execution.md)
