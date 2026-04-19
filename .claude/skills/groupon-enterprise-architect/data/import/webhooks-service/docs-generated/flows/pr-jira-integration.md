---
service: "webhooks-service"
title: "PR Jira Integration"
generated: "2026-03-03"
type: flow
flow_name: "pr-jira-integration"
flow_type: synchronous
trigger: "pull_request event (actions: opened, reopened, closed, merged)"
participants:
  - "continuumWebhooksService"
  - "webhookSvc_hookExecutor"
  - "webhookSvc_jiraClient"
  - "webhookSvc_githubClient"
architecture_ref: "components-continuum-webhooks-service-components"
---

# PR Jira Integration

## Summary

The `pr_jira_integration` hook connects GitHub pull requests to Jira issues. When a PR is opened, merged, or closed, the hook parses Jira issue keys from the PR title and commit messages, then transitions those Jira issues to the configured workflow state. It also posts the PR link as a remote link on the Jira issue. This hook can be configured multiple times to manage multiple Jira projects from a single repository.

## Trigger

- **Type**: event
- **Source**: GitHub Enterprise `pull_request` webhook event with actions `opened`, `reopened`, `closed` (merged), or `closed` (not merged)
- **Frequency**: On every pull request lifecycle event in repositories with `pr_jira_integration` enabled in `.webhooks.yml`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GitHub Enterprise | Delivers `pull_request` event payload | External |
| Hook Executor | Runs `PRJiraIntegrationHook` | `webhookSvc_hookExecutor` |
| Jira Client | Validates issue existence; performs transitions; posts links and comments | `webhookSvc_jiraClient` |
| GitHub Client | Reads PR commits to extract issue keys from commit messages | `webhookSvc_githubClient` |

## Steps

1. **Receive `pull_request` event**: The Webhook Router dispatches the event to `PRJiraIntegrationHook` via the standard ingestion flow.
   - From: `webhookSvc_router`
   - To: `webhookSvc_hookExecutor` (`PRJiraIntegrationHook`)
   - Protocol: Direct TypeScript async call

2. **Validate hook configuration**: The hook reads `jira_project`, `opened`, `reopened`, `merged`, and `closed_but_not_merged` from the `.webhooks.yml` hook config using `io-ts` validation.
   - From: `webhookSvc_hookExecutor`
   - To: in-process
   - Protocol: Direct TypeScript call

3. **Extract Jira issue keys from PR title**: The Jira client's `findIssues(text, project)` method applies a regex pattern to the PR title to find issue keys matching the configured `jira_project` prefix.
   - From: `webhookSvc_hookExecutor`
   - To: `webhookSvc_jiraClient` (in-process)
   - Protocol: Direct TypeScript call

4. **Extract Jira issue keys from commit messages**: Fetches all commits on the PR from GitHub, then applies `findIssues` to each commit message.
   - From: `webhookSvc_hookExecutor`
   - To: `webhookSvc_githubClient` -> GitHub Enterprise REST API (`pulls.listCommits`)
   - Protocol: HTTPS

5. **Validate each issue exists**: For each unique issue key found, calls `JIRA.issueExists(issueKey)` to confirm the issue exists in Jira before attempting any transitions.
   - From: `webhookSvc_hookExecutor`
   - To: `webhookSvc_jiraClient` -> Jira REST API (`GET /issue/{key}`)
   - Protocol: HTTPS

6. **Determine target state**: Maps the GitHub PR action to the configured Jira transition state from `.webhooks.yml` (e.g., `opened` -> `"code review"`, `merged` -> `"resolved"`, `closed_but_not_merged` -> `"in progress"`).
   - From: `webhookSvc_hookExecutor`
   - To: in-process
   - Protocol: Direct TypeScript logic

7. **Transition Jira issue**: Calls `JIRA.updateStatus(issueKey, targetState)`. This first fetches available transitions (`GET /issue/{key}/transitions`), finds the matching transition by name, then posts the transition (`POST /issue/{key}/transitions`).
   - From: `webhookSvc_hookExecutor`
   - To: `webhookSvc_jiraClient` -> Jira REST API
   - Protocol: HTTPS

8. **Post PR remote link to Jira issue**: Calls `JIRA.postLink(issueKey, prUrl, prTitle)` to attach the GitHub PR URL as a remote link on the Jira issue. Skips if the link already exists.
   - From: `webhookSvc_hookExecutor`
   - To: `webhookSvc_jiraClient` -> Jira REST API (`POST /issue/{key}/remotelink`)
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `jira_project` config missing or invalid | `configOrNull` returns null; hook exits early | No-op; logged |
| Issue key not found in Jira | `issueExists` returns false; hook skips that issue | Remaining issues still processed |
| Jira transition name not matching workflow | `updateStatus` returns false; skips | Logged as info |
| Jira API unreachable | axios call returns null; error logged | Hook fails; other hooks continue |
| Config has `optional: true` | If issue does not exist, it is skipped without error | Permissive behavior for optional Jira projects |

## Sequence Diagram

```
Webhook Router -> PRJiraIntegrationHook: do(event, config, github, slack)
PRJiraIntegrationHook -> PRJiraIntegrationHook: validateConfig(hookConfig)
PRJiraIntegrationHook -> JIRA Client: findIssues(prTitle, jiraProject)
PRJiraIntegrationHook -> GitHub Client: getPRCommits(prNumber)
GitHub Client -> GitHub Enterprise API: GET /repos/{owner}/{repo}/pulls/{n}/commits
GitHub Enterprise API --> GitHub Client: commits array
PRJiraIntegrationHook -> JIRA Client: findIssues(commitMsg, jiraProject) [per commit]
PRJiraIntegrationHook -> JIRA Client: issueExists(issueKey) [per unique key]
JIRA Client -> Jira REST API: GET /rest/api/2/issue/{key}
Jira REST API --> JIRA Client: issue JSON
PRJiraIntegrationHook -> JIRA Client: updateStatus(issueKey, targetState)
JIRA Client -> Jira REST API: GET /rest/api/2/issue/{key}/transitions
JIRA Client -> Jira REST API: POST /rest/api/2/issue/{key}/transitions
PRJiraIntegrationHook -> JIRA Client: postLink(issueKey, prUrl, prTitle)
JIRA Client -> Jira REST API: POST /rest/api/2/issue/{key}/remotelink
```

## Related

- Architecture dynamic view: `components-continuum-webhooks-service-components`
- Related flows: [Webhook Ingestion and Dispatch](webhook-ingestion-dispatch.md)
