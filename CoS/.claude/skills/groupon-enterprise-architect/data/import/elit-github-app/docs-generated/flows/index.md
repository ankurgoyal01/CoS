---
service: "elit-github-app"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for the ELIT GitHub App.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Webhook Signature Validation](webhook-signature-validation.md) | synchronous | GitHub webhook POST to `/elit-github-app/webhook` | Validates the HMAC-SHA256 signature on every inbound webhook before processing |
| [Check Suite Requested — Create Check Run](check-suite-requested.md) | synchronous | GitHub `check_suite.requested` or `check_suite.rerequested` webhook event | Receives a new or re-requested check suite event and creates a corresponding GitHub Check run |
| [PR Diff ELIT Scan](pr-diff-elit-scan.md) | event-driven (async) | GitHub `check_run.created` webhook event | Fetches the PR diff, loads ELIT rules, scans inserted lines for violations, and posts the check result with annotations |
| [ELIT Rule File Loading](elit-rule-file-loading.md) | synchronous | Invoked as part of the PR Diff ELIT Scan flow | Reads and merges the default ELIT rules with any per-repo `.elit.yml` rule extensions |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 0 |
| Sub-flow (synchronous, called from async) | 1 |

## Cross-Service Flows

All flows in this service span the `continuumElitGithubAppService` container and the external `githubEnterprise` system:

- GitHub Enterprise initiates all flows by delivering webhook events.
- The service calls back to GitHub Enterprise for all data fetching (diffs, rule files) and result reporting (check run creation, annotation, conclusion).

See [Architecture Context](../architecture-context.md) for the full relationship table.
