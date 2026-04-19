---
service: "proxykong"
title: "Add Route Request"
generated: "2026-03-03"
type: flow
flow_name: "add-route-request"
flow_type: synchronous
trigger: "Engineer submits a new route request via the ProxyKong UI"
participants:
  - "proxykongWebUi"
  - "routeManagementController"
  - "authBridge"
  - "routeConfigGateway"
  - "pullRequestAutomation"
  - "issueTrackerGateway"
  - "scmGateway"
  - "continuumApiProxyConfigBundle"
  - "continuumJiraService"
  - "githubEnterprise"
architecture_ref: "dynamic-route-change-request-flow"
---

# Add Route Request

## Summary

This flow handles the end-to-end process of adding new routes to the API proxy configuration. An authenticated engineer fills out the route request form in the ProxyKong UI, specifying destination, environment, region, routing paths, HTTP methods, and compliance metadata. ProxyKong creates one Jira issue per route in the GAPI project and submits a GitHub pull request to `groupon-api/api-proxy-config` containing the configuration change. Human reviewers then merge the PR to apply the route.

## Trigger

- **Type**: user-action
- **Source**: Engineer submits the "API Proxy Route Request" form in the ProxyKong UI at `/proxykong`
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| ProxyKong UI Module | Collects route request form data and calls `/proxyRouteDo` | `proxykongWebUi` |
| Route Management Controller | Receives POST request, validates auth, delegates to Pull Request Automation | `routeManagementController` |
| Authentication Bridge | Resolves caller identity from Okta headers/cookies; blocks unauthenticated requests | `authBridge` |
| Route Config Gateway | Reads existing config via `config_tools` scripts to support validation steps | `routeConfigGateway` |
| Pull Request Automation | Orchestrates Jira ticket and GitHub PR creation | `pullRequestAutomation` |
| Issue Tracker Gateway | Creates Jira issues in project GAPI (ID `11500`, type `10700`) | `issueTrackerGateway` |
| Source Control Gateway | Creates branch, commits mutations, opens pull request | `scmGateway` |
| API Proxy Config Bundle | Source of truth for route configuration; receives the committed changes | `continuumApiProxyConfigBundle` |
| Jira | Persists route request issues | `continuumJiraService` |
| GitHub Enterprise | Persists branch and pull request | `githubEnterprise` |

## Steps

1. **Submit route request**: Engineer selects "API Proxy Route Request" in the UI, fills in destination name, destination VIP(s), environment, region, routing paths, HTTP methods, port/timeout values, and compliance links. The UI POSTs the payload to `/proxyRouteDo`.
   - From: `proxykongWebUi`
   - To: `routeManagementController`
   - Protocol: REST/JSON (HTTPS)

2. **Authenticate caller**: The Route Management Controller calls `authBridge.failWhenUnauthenticatedOrElse`. The bridge reads `x-grpn-email` from the request headers (or `proxyKong_email` cookie). If absent, returns HTTP 401.
   - From: `routeManagementController`
   - To: `authBridge`
   - Protocol: direct

3. **Resolve caller username**: The authenticated username is extracted from `x-grpn-username` (or cookie) and passed as `reporter` to the Pull Request Automation.
   - From: `routeManagementController`
   - To: `pullRequestAutomation`
   - Protocol: direct

4. **Validate destination VIP**: Before calling `PullRequestBuilder.createTicketAndPRForAddRoutes`, the UI optionally calls `/doesDestinationVipExist` and `/doesDestinationExist` to pre-validate the destination. The `routeConfigGateway` reads the local `api-proxy-config` clone for these checks.
   - From: `proxykongWebUi`
   - To: `routeManagementController` → `routeConfigGateway` → `continuumApiProxyConfigBundle`
   - Protocol: REST/JSON, then Filesystem

5. **Create Jira issue(s)**: For each route in the request, `PullRequestBuilder.createTicketAndPRForAddRoute` calls `jiraHelper.createIssue` with routing metadata (region, environment, namespace, method, path, timeout values, ORR/GEARS compliance links, data classification). The issue is created in project GAPI (`11500`), issue type `10700`.
   - From: `pullRequestAutomation` → `issueTrackerGateway`
   - To: `continuumJiraService`
   - Protocol: HTTPS REST

6. **Copy config repo to temp directory**: `PrHelper.copyGitFolderIntoTemporaryFolder` copies `/api-proxy-config` to a new temp directory (prefixed `proxykong_api-proxy-config_`) to isolate mutations.
   - From: `scmGateway`
   - To: local filesystem
   - Protocol: Filesystem

7. **Create feature branch**: `PrHelper.newBranch` checks out master, resets hard, pulls latest, and creates a new branch named `proxykong-{JIRA_KEY}`.
   - From: `scmGateway`
   - To: `continuumApiProxyConfigBundle` (via git)
   - Protocol: Git

8. **Apply route config mutation**: `addNewRouteRequest` from `api-proxy-config/config_tools` writes the new route configuration into the temp directory.
   - From: `pullRequestAutomation` → `routeConfigGateway`
   - To: `continuumApiProxyConfigBundle` (temp copy)
   - Protocol: Filesystem

9. **Commit and push branch**: `PrHelper.commitAndPush` stages all changes, commits with a message including the Jira key and destination name, and pushes the branch to `github.groupondev.com/groupon-api/api-proxy-config`.
   - From: `scmGateway`
   - To: `githubEnterprise`
   - Protocol: HTTPS (Git push)

10. **Create pull request**: `PrHelper.createPullRequest` opens a PR against `master` with title `[{ENV}] [{REGION}] [{INFRA}] New route requested for destination: {destinationName} via ProxyKong` and body containing the Jira issue URL(s).
    - From: `scmGateway`
    - To: `githubEnterprise`
    - Protocol: HTTPS REST (GitHub API v3)

11. **Return result to UI**: The PR number, Jira issue key(s), and success/failure status are returned as JSON to the browser.
    - From: `routeManagementController`
    - To: `proxykongWebUi`
    - Protocol: REST/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing Okta authentication | `authBridge` returns HTTP 401 immediately | UI displays authentication error; no Jira or PR created |
| Jira issue creation fails | `handleIssueAndPRPromises` catches exception; PR creation is skipped | Error returned to UI; no partial state left |
| GitHub PR creation fails | `handleIssueAndPRPromises` catches exception; Jira issue(s) may already be created | Error returned to UI; orphaned Jira issues may exist |
| No changes to commit | `PrHelper.commitAndPush` throws "No changes to commit" | Error returned to UI |
| Destination VIP validation fails | UI disables submission until VIP is confirmed reachable | No Jira or PR created |

## Sequence Diagram

```
ProxyKong UI -> Route Management Controller: POST /proxyRouteDo {routes, destination, env, region, ...}
Route Management Controller -> Auth Bridge: failWhenUnauthenticatedOrElse()
Auth Bridge --> Route Management Controller: caller identity (reporter=username)
Route Management Controller -> Pull Request Automation: createTicketAndPRForAddRoutes(body, reporter)
Pull Request Automation -> Issue Tracker Gateway: createIssue({summary, routing metadata, compliance links})
Issue Tracker Gateway -> Jira: POST /rest/api/2/issue
Jira --> Issue Tracker Gateway: {id, key, self}
Pull Request Automation -> Source Control Gateway: copyGitFolderIntoTemporaryFolder + newBranch
Source Control Gateway -> api-proxy-config (filesystem): git checkout master, git pull, git branch
Pull Request Automation -> Route Config Gateway: addNewRouteRequest(requestBody, tempDir)
Route Config Gateway -> api-proxy-config (filesystem): write route config files
Pull Request Automation -> Source Control Gateway: commitAndPush(branchName, commitMsg)
Source Control Gateway -> GitHub Enterprise: git push origin {branchName}
Pull Request Automation -> Source Control Gateway: createPullRequest({owner, repo, title, body})
Source Control Gateway -> GitHub Enterprise: POST /api/v3/repos/groupon-api/api-proxy-config/pulls
GitHub Enterprise --> Source Control Gateway: {number, html_url}
Pull Request Automation --> Route Management Controller: {isSuccess, newIssueIds, pullRequestId}
Route Management Controller --> ProxyKong UI: JSON response
```

## Related

- Architecture dynamic view: `dynamic-route-change-request-flow`
- Related flows: [Promote Route](promote-route.md), [Remove Route](remove-route.md), [Delete Experiments](delete-experiments.md)
