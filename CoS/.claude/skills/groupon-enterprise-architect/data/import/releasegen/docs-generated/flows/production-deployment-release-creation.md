---
service: "releasegen"
title: "Production Deployment Release Creation"
generated: "2026-03-03"
type: flow
flow_name: "production-deployment-release-creation"
flow_type: synchronous
trigger: "POST /deployment/{org}/{repo}/{id} or background polling worker"
participants:
  - "deploymentResource"
  - "deploymentService"
  - "deploybotClient"
  - "releasegen_gitHubService"
  - "releasegen_jiraService"
  - "deploybotSystem_7f4e"
  - "githubSystem_3a1b"
  - "jiraSystem_9c2d"
architecture_ref: "components-releasegen-service"
---

# Production Deployment Release Creation

## Summary

When a service is deployed to a production environment, Releasegen creates or updates a GitHub release tagged to the deployed Git SHA. It generates release notes from the PR history since the previous release, records a GitHub Deployment and DeploymentStatus for environment tracking, and links all referenced JIRA tickets to the release. This flow is the core value proposition of Releasegen.

## Trigger

- **Type**: api-call (or event-driven via worker)
- **Source**: `POST /deployment/{org}/{repo}/{id}` called by Deploybot or the background polling worker after resolving a JIRA RE-project ticket to a Deploybot deployment ID
- **Frequency**: Per production deployment event

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deployment Resource | Receives the HTTP request and delegates to the Deployment Service | `deploymentResource` |
| Deployment Service | Orchestrates all downstream calls; decides between release creation (production) and status-only (non-production) | `deploymentService` |
| Deploybot Service | Retrieves the full `DeploymentId` record from Deploybot | `deploybotClient` |
| GitHub Service | Creates/updates the release, generates release notes, creates Deployment and DeploymentStatus | `releasegen_gitHubService` |
| Jira Service | Labels JIRA tickets with `releasegen`; adds remote links to the GitHub release | `releasegen_jiraService` |
| Deploybot | Authoritative source of deployment metadata (SHA, environment, region, JIRA ticket, logbook ticket) | `deploybotSystem_7f4e` |
| GitHub Enterprise | Hosts releases, deployment records, and deployment statuses | `githubSystem_3a1b` |
| JIRA | Holds RE-project release tickets; receives labels and remote links | `jiraSystem_9c2d` |

## Steps

1. **Receive deployment publication request**: The `Deployment Resource` receives `POST /deployment/{org}/{repo}/{id}`.
   - From: caller (Deploybot or background worker)
   - To: `deploymentResource`
   - Protocol: REST

2. **Fetch Deploybot deployment record**: The `Deployment Service` calls the Deploybot Service to retrieve the full `DeploymentId` by org, repo, and ID.
   - From: `deploymentService`
   - To: `deploybotClient` -> Deploybot `GET /v1/deployments/{org}/{name}`
   - Protocol: REST (Retrofit)

3. **Determine environment type**: The `Deployment Service` inspects `DeploymentId.isProduction()`. For production deployments, proceeds to release creation. For non-production, skips to step 6 (see [Non-Production Deployment Status Recording](non-production-deployment-status.md)).
   - From: `deploymentService`
   - To: in-process decision

4. **Find or create GitHub release**: The GitHub Service looks up existing releases for the SHA. If no release exists, it creates one using the SHA's commit date as the release tag (format: `rg.<timestamp>`). If a release already exists, it preserves any user-edited preamble above the "What's Changed" section.
   - From: `releasegen_gitHubService`
   - To: GitHub Enterprise (`POST /repos/{org}/{repo}/releases` or existing release lookup)
   - Protocol: GitHub REST API

5. **Generate release notes**: Calls `POST /repos/{org}/{repo}/releases/generate-notes` to produce PR-based release notes since the previous release tag.
   - From: `releasegen_gitHubService`
   - To: GitHub Enterprise
   - Protocol: GitHub REST API

6. **Record GitHub Deployment and DeploymentStatus**: Creates a `GitHub Deployment` linked to the SHA and the environment (e.g., `production-us-west-1`). Sets `DeploymentStatus` to the Deploybot status with the logbook ticket URL and JIRA/logbook metadata as payload.
   - From: `releasegen_gitHubService`
   - To: GitHub Enterprise
   - Protocol: GitHub REST API

7. **Update release body with deployment status**: Annotates the release body's "## Deployments" section with the environment, status, and log URL. This step makes deployment status visible directly in the GitHub release view (GitHub does not show deployment status on releases natively).
   - From: `releasegen_gitHubService`
   - To: GitHub Enterprise (PATCH release)
   - Protocol: GitHub REST API

8. **Retrieve JIRA `Done` timestamp**: For each JIRA ticket referenced in the release notes, fetches the issue changelog to find the exact timestamp when the ticket transitioned to `Done`. Uses this as the deployment timestamp.
   - From: `releasegen_jiraService`
   - To: JIRA (`GET /issue/{issue}/changelog`)
   - Protocol: REST (Retrofit)

9. **Label JIRA ticket**: Adds the `releasegen` label to the JIRA RE-project ticket to prevent it from being re-processed by future worker polls.
   - From: `releasegen_jiraService`
   - To: JIRA (`PUT /issue/{issue}`)
   - Protocol: REST (Retrofit)

10. **Add remote link from JIRA to GitHub release**: Creates a remote link on each JIRA ticket referenced in the release notes, pointing to the GitHub release URL.
    - From: `releasegen_jiraService`
    - To: JIRA (`POST /issue/{issue}/remotelink`)
    - Protocol: REST (Retrofit)

11. **Return DeploymentStatusInfo**: Returns the composed `DeploymentStatusInfo` (GitHub deployment status ID, state, and release metadata) to the caller.
    - From: `deploymentResource`
    - To: caller
    - Protocol: REST (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deploybot deployment ID not found | Throws `DeploymentNotFoundException` | HTTP 404 returned to caller; no GitHub or JIRA changes |
| GitHub API call fails | Exception propagates from `GitHubRepoService` | HTTP 500 returned to caller; partial state possible if release was created before the error |
| JIRA label/link call fails | Exception propagates from `JiraService` | HTTP 500 returned; GitHub release may already be created/updated |
| SHA has no commits since last release | GitHub `generate-notes` returns empty diff | Release created with empty "What's Changed" section |
| Release already exists for SHA | Existing release found; preamble is preserved; deployments section and changes section are updated | Idempotent update |

## Sequence Diagram

```
Caller -> DeploymentResource: POST /deployment/{org}/{repo}/{id}
DeploymentResource -> DeploymentService: publishDeployment(org, repo, id)
DeploymentService -> DeploybotService: getById(org, repo, id)
DeploybotService -> Deploybot: GET /v1/deployments/{org}/{name}
Deploybot --> DeploybotService: DeploymentId
DeploybotService --> DeploymentService: DeploymentId
DeploymentService -> GitHubService: buildRelease().releaseSha(sha).build()
GitHubService -> GitHub: find or create release for SHA
GitHub --> GitHubService: ReleaseInfo
GitHubService -> GitHub: POST /repos/{org}/{repo}/releases/generate-notes
GitHub --> GitHubService: GeneratedNotesInfo
GitHubService -> GitHub: create Deployment + DeploymentStatus
GitHub --> GitHubService: DeploymentStatusInfo
GitHubService --> DeploymentService: DeploymentStatusInfo (with ReleaseInfo)
DeploymentService -> JiraService: getDoneAt(jiraTicket)
JiraService -> JIRA: GET /issue/{issue}/changelog
JIRA --> JiraService: IssueChanges
JiraService --> DeploymentService: doneAt timestamp
DeploymentService -> JiraService: addLabels(jiraTicket, "releasegen")
JiraService -> JIRA: PUT /issue/{issue}
DeploymentService -> JiraService: linkRelease(fixedIssues, releaseName, releaseUrl)
JiraService -> JIRA: POST /issue/{issue}/remotelink
DeploymentService --> DeploymentResource: DeploymentStatusInfo
DeploymentResource --> Caller: 200 OK DeploymentStatusInfo JSON
```

## Related

- Architecture component view: `components-releasegen-service`
- Related flows: [Non-Production Deployment Status Recording](non-production-deployment-status.md), [Release Note Generation and JIRA Enrichment](release-note-generation.md), [Background Polling Worker](background-polling-worker.md)
