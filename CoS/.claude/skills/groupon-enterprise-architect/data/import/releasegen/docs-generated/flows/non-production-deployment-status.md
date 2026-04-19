---
service: "releasegen"
title: "Non-Production Deployment Status Recording"
generated: "2026-03-03"
type: flow
flow_name: "non-production-deployment-status"
flow_type: synchronous
trigger: "POST /deployment/{org}/{repo}/{id} with a non-production DeploymentId"
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

# Non-Production Deployment Status Recording

## Summary

When a service is deployed to a non-production environment (staging, RDE dev, etc.), Releasegen does not create a GitHub release. Instead, it records a GitHub Deployment and DeploymentStatus directly against the SHA. For branches marked as releasable, this causes the deployment status to appear on the Pull Request status page in GitHub, providing developers with real-time visibility into where their branch is deployed.

## Trigger

- **Type**: api-call (or event-driven via worker)
- **Source**: `POST /deployment/{org}/{repo}/{id}` where the resolved `DeploymentId.isProduction()` returns `false`
- **Frequency**: Per non-production deployment event (staging deploy, RDE deploy, etc.)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deployment Resource | Receives the HTTP request and delegates to the Deployment Service | `deploymentResource` |
| Deployment Service | Orchestrates downstream calls; detects non-production and skips release creation | `deploymentService` |
| Deploybot Service | Retrieves the full `DeploymentId` record from Deploybot | `deploybotClient` |
| GitHub Service | Creates a GitHub Deployment and DeploymentStatus without creating a release | `releasegen_gitHubService` |
| Jira Service | Retrieves the JIRA ticket `Done` timestamp for use as the deployment timestamp | `releasegen_jiraService` |
| Deploybot | Source of deployment metadata | `deploybotSystem_7f4e` |
| GitHub Enterprise | Records the Deployment and DeploymentStatus | `githubSystem_3a1b` |
| JIRA | Provides the `Done` transition timestamp | `jiraSystem_9c2d` |

## Steps

1. **Receive deployment publication request**: The `Deployment Resource` receives `POST /deployment/{org}/{repo}/{id}`.
   - From: caller (Deploybot or background worker)
   - To: `deploymentResource`
   - Protocol: REST

2. **Fetch Deploybot deployment record**: The `Deployment Service` calls the Deploybot Service to retrieve the full `DeploymentId`.
   - From: `deploymentService`
   - To: `deploybotClient` -> Deploybot `GET /v1/deployments/{org}/{name}`
   - Protocol: REST (Retrofit)

3. **Detect non-production environment**: `DeploymentId.isProduction()` returns `false`. The Deployment Service sets `release = Optional.empty()` and skips all GitHub release creation steps.
   - From: `deploymentService`
   - To: in-process decision

4. **Retrieve JIRA `Done` timestamp**: Fetches the JIRA issue changelog for the associated RE-project ticket to determine when it was marked `Done`. Used as the `deployedAt` field in the GitHub DeploymentStatus payload.
   - From: `releasegen_jiraService`
   - To: JIRA (`GET /issue/{issue}/changelog`)
   - Protocol: REST (Retrofit)

5. **Create GitHub Deployment linked to SHA**: Creates a GitHub Deployment record for the environment (e.g., `staging-us-west-1`) associated directly with the deployed SHA. Includes JIRA ticket, logbook ticket, deployer, and pusher in the payload.
   - From: `releasegen_gitHubService`
   - To: GitHub Enterprise
   - Protocol: GitHub REST API

6. **Set GitHub DeploymentStatus**: Creates a `DeploymentStatus` for the new Deployment record. Sets the state, log URL, and metadata. This populates the Environments tab in the GitHub repository and, for releasable branches, the Pull Request status page.
   - From: `releasegen_gitHubService`
   - To: GitHub Enterprise
   - Protocol: GitHub REST API

7. **Return DeploymentStatusInfo**: Returns the `DeploymentStatusInfo` (no `release` field since this is non-production) to the caller.
   - From: `deploymentResource`
   - To: caller
   - Protocol: REST (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deploybot deployment ID not found | Throws `DeploymentNotFoundException` | HTTP 404 returned; no GitHub changes |
| GitHub Deployment creation fails | Exception propagates | HTTP 500 returned to caller |
| JIRA changelog unavailable | `getDoneAt` returns `Optional.empty()`; falls back to `DeploymentId.getCreatedAt()` | GitHub DeploymentStatus is recorded with the Deploybot creation time as `deployedAt` |

## Sequence Diagram

```
Caller -> DeploymentResource: POST /deployment/{org}/{repo}/{id}
DeploymentResource -> DeploymentService: publishDeployment(org, repo, id)
DeploymentService -> DeploybotService: getById(org, repo, id)
DeploybotService -> Deploybot: GET /v1/deployments/{org}/{name}
Deploybot --> DeploybotService: DeploymentId (non-production)
DeploybotService --> DeploymentService: DeploymentId
note over DeploymentService: isProduction() == false; skip release creation
DeploymentService -> JiraService: getDoneAt(jiraTicket)
JiraService -> JIRA: GET /issue/{issue}/changelog
JIRA --> JiraService: IssueChanges
JiraService --> DeploymentService: doneAt (or createdAt fallback)
DeploymentService -> GitHubService: deployRelease(sha).environment(...).status(...).deploy()
GitHubService -> GitHub: create Deployment for SHA + environment
GitHub --> GitHubService: DeploymentInfo
GitHubService -> GitHub: create DeploymentStatus
GitHub --> GitHubService: DeploymentStatusInfo
DeploymentService --> DeploymentResource: DeploymentStatusInfo (no release)
DeploymentResource --> Caller: 200 OK DeploymentStatusInfo JSON
```

## Related

- Architecture component view: `components-releasegen-service`
- Related flows: [Production Deployment Release Creation](production-deployment-release-creation.md), [Background Polling Worker](background-polling-worker.md)
