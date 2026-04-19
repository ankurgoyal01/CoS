---
service: "elit-github-app"
title: "Check Suite Requested — Create Check Run"
generated: "2026-03-03"
type: flow
flow_name: "check-suite-requested"
flow_type: synchronous
trigger: "GitHub check_suite.requested or check_suite.rerequested webhook event, or check_run.rerequested event"
participants:
  - "githubEnterprise"
  - "continuumElitGithubAppService"
  - "webhookResource"
  - "actionHandler"
  - "githubClient"
architecture_ref: "components-elitGithubAppService"
---

# Check Suite Requested — Create Check Run

## Summary

When a pull request is opened or updated in a repository where the GitHub App is installed, GitHub triggers a `check_suite` event with action `requested`. This flow handles that event by authenticating as the specific GitHub App installation, retrieving the target repository, and creating a new GitHub Check run for the head commit SHA of the check suite. The same flow handles `rerequested` events for both check suites and individual check runs, allowing developers to manually re-trigger a scan.

## Trigger

- **Type**: event
- **Source**: GitHub Enterprise — `check_suite` webhook event with action `requested` or `rerequested`; also `check_run` with action `rerequested`
- **Frequency**: On every new or updated pull request in an installed repository; also on manual re-request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GitHub Enterprise | Sends `check_suite.requested` / `rerequested` webhook event | `githubEnterprise` |
| GitHub Webhook Resource | Receives authenticated webhook payload and delegates to action handler | `webhookResource` |
| Check Action Handler | Routes the event to `CreateCheckActionHandler` based on action type and payload shape | `actionHandler` |
| GitHub App Client | Authenticates as the installation and calls GitHub API to create the check run | `githubClient` |
| GitHub Enterprise | Receives the check run creation request and registers the pending check | `githubEnterprise` |

## Steps

1. **Receive webhook event**: The `GitHubAppResource` receives the validated POST at `/elit-github-app/webhook`. The payload contains a `check_suite` (or `check_run` for rerequested) object with `head_sha` and the `installation.id`.
   - From: `githubEnterprise`
   - To: `webhookResource`
   - Protocol: HTTPS (already validated by `messageAuthFilter`)

2. **Dispatch to action handler**: `GitHubAppResource.onEvent` calls `CheckActionHandler.onEvent(github, event)`.
   - From: `webhookResource`
   - To: `actionHandler`
   - Protocol: direct (in-process)

3. **Route to CreateCheckActionHandler**: `CheckActionHandler` (which extends `GitHubActionHandlers`) evaluates each registered handler. `CreateCheckActionHandler.accepts()` returns `true` when:
   - `check_suite` is present and action is `requested` or `rerequested`, OR
   - `check_run` is present and action is `rerequested`.
   - From: `actionHandler`
   - To: `CreateCheckActionHandler` (in-process)
   - Protocol: direct

4. **Authenticate as installation**: `CreateCheckActionHandler` calls `github.asInstallation(installation.getId())` via the `GitHubAppService`. This exchanges the GitHub App JWT for an installation access token scoped to the installation.
   - From: `githubClient`
   - To: `githubEnterprise` (GitHub App token endpoint)
   - Protocol: HTTPS REST

5. **Fetch repository**: Using the installation-scoped token, the handler calls `gh.getRepositoryById(repository.getId())` to get a reference to the target repository.
   - From: `githubClient`
   - To: `githubEnterprise` (GitHub API)
   - Protocol: HTTPS REST

6. **Create check run**: Calls `repository.createCheckRun(check.getLabel(), checkSuite.getHeadSha()).create()` to register a new check run in GitHub for the head commit of the PR.
   - From: `githubClient`
   - To: `githubEnterprise` (GitHub Checks API)
   - Protocol: HTTPS REST

7. **Return success**: `GitHubAppResource` returns HTTP 200 OK to GitHub Enterprise. GitHub then delivers a `check_run.created` event, which triggers the [PR Diff ELIT Scan](pr-diff-elit-scan.md) flow.
   - From: `webhookResource`
   - To: `githubEnterprise`
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No repository in payload | `ifPresent` guard — creation is skipped silently | No check run created; no error returned |
| GitHub API error during check run creation | Exception propagated to `GitHubAppResource.onEvent` catch block | HTTP 500 returned to GitHub; logged via Steno |
| Installation token exchange failure | Exception propagated up the call stack | HTTP 500 returned to GitHub |

## Sequence Diagram

```
GitHub Enterprise -> GitHubAppResource: POST /elit-github-app/webhook (check_suite.requested)
GitHubAppResource -> CheckActionHandler: onEvent(github, action)
CheckActionHandler -> CreateCheckActionHandler: accepts() == true; onEvent(app, action)
CreateCheckActionHandler -> GitHubAppClient: asInstallation(installationId)
GitHubAppClient -> GitHub Enterprise: Exchange JWT for installation token
GitHub Enterprise --> GitHubAppClient: Installation access token
GitHubAppClient -> GitHub Enterprise: getRepositoryById(repositoryId)
GitHub Enterprise --> GitHubAppClient: Repository reference
GitHubAppClient -> GitHub Enterprise: createCheckRun(label, headSha)
GitHub Enterprise --> GitHubAppClient: Check run created
GitHubAppResource --> GitHub Enterprise: HTTP 200 OK
```

## Related

- Architecture dynamic view: `components-elitGithubAppService`
- Related flows: [Webhook Signature Validation](webhook-signature-validation.md), [PR Diff ELIT Scan](pr-diff-elit-scan.md)
