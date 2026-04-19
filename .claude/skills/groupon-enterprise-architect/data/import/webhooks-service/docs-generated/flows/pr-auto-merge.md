---
service: "webhooks-service"
title: "PR Auto-Merge"
generated: "2026-03-03"
type: flow
flow_name: "pr-auto-merge"
flow_type: synchronous
trigger: "status event — all commit statuses on a PR's head SHA transition to green"
participants:
  - "continuumWebhooksService"
  - "webhookSvc_hookExecutor"
  - "webhookSvc_githubClient"
architecture_ref: "components-continuum-webhooks-service-components"
---

# PR Auto-Merge

## Summary

The `pr_auto_merge` hook automatically merges a pull request when all CI build statuses for its head commit turn green, provided a trigger label (`auto merge when green`, `auto squash and merge when green`, or `auto rebase and merge when green`) is present on the PR. This removes the need for engineers to manually merge after CI passes. If the build fails, the trigger label is automatically removed to prevent future auto-merge attempts. This hook requires write access for the `svc-github-webhook` bot user and is not available for SOX in-scope repositories.

## Trigger

- **Type**: event
- **Source**: GitHub Enterprise `status` event (fired when a CI system posts a commit status update)
- **Frequency**: On every CI status update for repositories with `pr_auto_merge` enabled in `.webhooks.yml`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GitHub Enterprise | Delivers `status` event; stores PR and commit state | External |
| Hook Executor | Runs `PRAutoMergeHook` | `webhookSvc_hookExecutor` |
| GitHub Client | Reads PR labels, combined status, PR data; merges PR; removes labels | `webhookSvc_githubClient` |

## Steps

1. **Receive `status` event**: The Webhook Router dispatches the `status` event to `PRAutoMergeHook`.
   - From: `webhookSvc_router`
   - To: `webhookSvc_hookExecutor` (`PRAutoMergeHook`)
   - Protocol: Direct TypeScript async call

2. **Validate hook configuration**: Reads `merge_trigger_label`, `squash_and_merge_trigger_label`, and `rebase_and_merge_trigger_label` from `.webhooks.yml` config. Defaults are used if not set.
   - From: `webhookSvc_hookExecutor`
   - To: in-process
   - Protocol: Direct TypeScript call

3. **Extract SHA from status payload**: Reads the commit SHA from the `status` event payload to identify which commit's status changed.
   - From: `webhookSvc_hookExecutor`
   - To: in-process (payload)
   - Protocol: Direct TypeScript object access

4. **Find open PRs for this SHA**: Searches GitHub for open PRs whose head SHA matches the status event SHA.
   - From: `webhookSvc_hookExecutor`
   - To: `webhookSvc_githubClient` -> GitHub Enterprise REST API (`pulls.list`)
   - Protocol: HTTPS

5. **Check trigger label presence**: For each matching PR, reads the PR's current labels via `getPRLabels`. Checks if one of the three trigger labels is present.
   - From: `webhookSvc_hookExecutor`
   - To: `webhookSvc_githubClient` -> GitHub Enterprise REST API (`issues.listLabelsOnIssue`)
   - Protocol: HTTPS

6. **Check combined build status**: Calls `getCombinedStatus(sha)` to determine if all commit statuses are `success`. If the combined state is not `success`, the flow checks if the state is `failure`.
   - From: `webhookSvc_hookExecutor`
   - To: `webhookSvc_githubClient` -> GitHub Enterprise REST API (`repos.getCombinedStatusForRef`)
   - Protocol: HTTPS

7. **Remove trigger label on failure**: If the combined status is `failure` and a trigger label is present, removes the trigger label from the PR to prevent auto-merge on next green status.
   - From: `webhookSvc_hookExecutor`
   - To: `webhookSvc_githubClient` -> GitHub Enterprise REST API (`issues.removeLabel`)
   - Protocol: HTTPS

8. **Merge PR**: If all statuses are green and the trigger label is present, calls `mergePR(prNumber, sha, method)` using the merge method corresponding to the trigger label (`merge`, `squash`, or `rebase`).
   - From: `webhookSvc_hookExecutor`
   - To: `webhookSvc_githubClient` -> GitHub Enterprise REST API (`pulls.merge`)
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No matching open PRs for SHA | Exits early | No-op |
| Trigger label not present | Exits early for that PR | No-op |
| Combined status not yet success | Exits early; waits for next status event | No-op |
| Build failed | Removes trigger label | PR will not auto-merge on next green; engineer must re-label |
| Merge fails (e.g., conflicts) | `mergePR` returns `merged: false` with message | Logged; PR not merged |
| Hook requires write access | GitHub API returns 403 | Error logged; hook fails |

## Sequence Diagram

```
GitHub Enterprise -> Webhook Router: status event (sha, state)
Webhook Router -> PRAutoMergeHook: do(event, config, github, slack)
PRAutoMergeHook -> GitHub Client: searchPRs(branch, 'open')
GitHub Client -> GitHub Enterprise API: GET /repos/{owner}/{repo}/pulls?head={sha}
GitHub Enterprise API --> GitHub Client: open PRs list
PRAutoMergeHook -> GitHub Client: getPRLabels(prNumber)
GitHub Client -> GitHub Enterprise API: GET /repos/{owner}/{repo}/issues/{n}/labels
GitHub Enterprise API --> GitHub Client: labels list
PRAutoMergeHook -> GitHub Client: getCombinedStatus(sha)
GitHub Client -> GitHub Enterprise API: GET /repos/{owner}/{repo}/commits/{sha}/status
GitHub Enterprise API --> GitHub Client: combined status
PRAutoMergeHook -> GitHub Client: mergePR(prNumber, sha, method) [if all green + label present]
GitHub Client -> GitHub Enterprise API: PUT /repos/{owner}/{repo}/pulls/{n}/merge
GitHub Enterprise API --> GitHub Client: merge result
```

## Related

- Architecture dynamic view: `components-continuum-webhooks-service-components`
- Related flows: [Webhook Ingestion and Dispatch](webhook-ingestion-dispatch.md), [Build Status Notifier](build-status-notifier.md)
