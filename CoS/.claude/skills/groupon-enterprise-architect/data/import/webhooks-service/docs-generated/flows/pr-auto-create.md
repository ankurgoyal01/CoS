---
service: "webhooks-service"
title: "PR Auto-Create Back-Merge"
generated: "2026-03-03"
type: flow
flow_name: "pr-auto-create"
flow_type: synchronous
trigger: "pull_request closed (merged) into a branch matching compare_branch or compare_branch_prefix"
participants:
  - "continuumWebhooksService"
  - "webhookSvc_hookExecutor"
  - "webhookSvc_githubClient"
architecture_ref: "components-continuum-webhooks-service-components"
---

# PR Auto-Create Back-Merge

## Summary

The `pr_auto_create` hook automatically creates back-merge pull requests after code is merged into a release branch. When a PR merges into (for example) `release/1.0`, the hook checks for newer protected release branches (e.g., `release/1.1`) and creates a temporary branch plus a PR to propagate the change forward. If no newer branch exists, the PR targets the configured `base_branch` (typically `main`). Optional labels (such as `auto merge when green`) can be added to the auto-created PR to chain it with the auto-merge hook. This hook requires write access for the `svc-github-webhook` bot user.

## Trigger

- **Type**: event
- **Source**: GitHub Enterprise `pull_request` event with action `closed` where `pull_request.merged` is `true`
- **Frequency**: On every merged PR in repositories with `pr_auto_create` enabled in `.webhooks.yml`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GitHub Enterprise | Delivers `pull_request` (closed + merged) event; stores branch and PR state | External |
| Hook Executor | Runs `PRAutoCreateHook` | `webhookSvc_hookExecutor` |
| GitHub Client | Reads branches by prefix, protected branch status; creates temporary branch and new PR; adds labels | `webhookSvc_githubClient` |

## Steps

1. **Receive merged `pull_request` event**: The Webhook Router dispatches the closed+merged PR event to `PRAutoCreateHook`.
   - From: `webhookSvc_router`
   - To: `webhookSvc_hookExecutor` (`PRAutoCreateHook`)
   - Protocol: Direct TypeScript async call

2. **Validate hook configuration**: Reads `base_branch`, `compare_branch`, `compare_branch_prefix`, and `labels` from `.webhooks.yml`. Validates that exactly one of `compare_branch` or `compare_branch_prefix` is set.
   - From: `webhookSvc_hookExecutor`
   - To: in-process
   - Protocol: Direct TypeScript call

3. **Check if PR was merged into a matching branch**: Verifies the PR's `base.ref` matches the configured `compare_branch` exactly, or starts with the configured `compare_branch_prefix` (e.g., `release/`).
   - From: `webhookSvc_hookExecutor`
   - To: in-process (payload)
   - Protocol: Direct TypeScript object access

4. **Find all branches matching the prefix**: Calls `getBranchesByPrefix(compare_branch_prefix)` to retrieve all protected branches with the same prefix, then version-sorts them to find newer branches.
   - From: `webhookSvc_hookExecutor`
   - To: `webhookSvc_githubClient` -> GitHub Enterprise REST API (`git.listMatchingRefs`)
   - Protocol: HTTPS

5. **Determine target branch**: If a newer protected branch exists (e.g., `release/1.1` when merging into `release/1.0`), it becomes the target. Otherwise, `base_branch` (e.g., `main`) is used.
   - From: `webhookSvc_hookExecutor`
   - To: in-process
   - Protocol: Direct TypeScript version-sort logic

6. **Create temporary branch**: Creates a new branch from the merged PR's head SHA with the naming pattern `zi/auto-merge-{source-branch}` to use as the PR head.
   - From: `webhookSvc_hookExecutor`
   - To: `webhookSvc_githubClient` -> GitHub Enterprise REST API (`git.createRef`)
   - Protocol: HTTPS

7. **Create back-merge PR**: Calls `createPR(targetBranch, tempBranch, title, body)` to open the back-merge PR from the temporary branch into the target branch.
   - From: `webhookSvc_hookExecutor`
   - To: `webhookSvc_githubClient` -> GitHub Enterprise REST API (`pulls.create`)
   - Protocol: HTTPS

8. **Add configured labels**: If labels are specified in `.webhooks.yml` (e.g., `auto merge when green`), adds them to the newly created PR.
   - From: `webhookSvc_hookExecutor`
   - To: `webhookSvc_githubClient` -> GitHub Enterprise REST API (`issues.addLabels`)
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| PR not merged (only closed) | Exits early | No-op |
| Merge target does not match configured branch/prefix | Exits early | No-op |
| Branch creation fails | Error logged; PR creation skipped | Back-merge PR not created |
| PR already exists for the branch pair | `createPR` may return 422; logged | Hook fails; engineer must create manually |
| Protected branch detection fails | Falls back to `base_branch` target | PR created against main/base |

## Sequence Diagram

```
GitHub Enterprise -> Webhook Router: pull_request (closed, merged, base=release/1.0)
Webhook Router -> PRAutoCreateHook: do(event, config, github, slack)
PRAutoCreateHook -> PRAutoCreateHook: validateConfig; check base.ref matches prefix
PRAutoCreateHook -> GitHub Client: getBranchesByPrefix('release/')
GitHub Client -> GitHub Enterprise API: GET /repos/{owner}/{repo}/git/matching-refs/heads/release/
GitHub Enterprise API --> GitHub Client: branches list
PRAutoCreateHook -> PRAutoCreateHook: version-sort; find target branch
PRAutoCreateHook -> GitHub Client: createBranch(sha, 'zi/auto-merge-release-1.0')
GitHub Client -> GitHub Enterprise API: POST /repos/{owner}/{repo}/git/refs
PRAutoCreateHook -> GitHub Client: createPR(targetBranch, tempBranch, title, body)
GitHub Client -> GitHub Enterprise API: POST /repos/{owner}/{repo}/pulls
GitHub Enterprise API --> GitHub Client: PR object
PRAutoCreateHook -> GitHub Client: addLabels(prNumber, ['auto merge when green'])
GitHub Client -> GitHub Enterprise API: POST /repos/{owner}/{repo}/issues/{n}/labels
```

## Related

- Architecture dynamic view: `components-continuum-webhooks-service-components`
- Related flows: [Webhook Ingestion and Dispatch](webhook-ingestion-dispatch.md), [PR Auto-Merge](pr-auto-merge.md)
