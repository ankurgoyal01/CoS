---
service: "cloud-ui"
title: "Deployment Status Polling Flow"
generated: "2026-03-03"
type: flow
flow_name: "deployment-status-polling"
flow_type: synchronous
trigger: "Cloud UI polls the status endpoint periodically after a GitOps sync is triggered"
participants:
  - "continuumCloudUi"
  - "continuumCloudBackendApi"
  - "continuumCloudBackendPostgres"
  - "jenkinsController"
architecture_ref: "dynamic-gitops-deployment-flow"
---

# Deployment Status Polling Flow

## Summary

After triggering a GitOps sync, the Cloud UI periodically calls the deployment status endpoint to track progress through the lifecycle phases (`queued` → `syncing` → `synced` → `building` → `ready_to_deploy`). The backend enriches the status response by actively polling Jenkins for build information when the deployment is in the `synced` or `building` phase. When the build succeeds, the backend constructs a Deploybot URL and returns it to the frontend for the engineer to initiate the final Kubernetes deployment.

## Trigger

- **Type**: api-call (timer-driven from frontend)
- **Source**: `cloudUiPages` component in `continuumCloudUi` polls on a regular interval after triggering a sync
- **Frequency**: Per-request (on-demand polling loop in the UI)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cloud UI Web App | Polls status endpoint; renders phase progress bar and Deploybot link | `continuumCloudUi` |
| Cloud Backend API | Retrieves deployment record; conditionally polls Jenkins; updates phase; constructs Deploybot URL | `continuumCloudBackendApi` |
| Cloud Backend PostgreSQL | Stores and returns current deployment phase, status, and Jenkins metadata | `continuumCloudBackendPostgres` |
| Jenkins | Source of build status for `synced` and `building` phase transitions | `jenkinsController` |

## Steps

1. **UI Requests Status**: Frontend calls `GET /cloud-backend/deployments/:deploymentId/status`.
   - From: `continuumCloudUi`
   - To: `continuumCloudBackendApi` (`backendDeploymentStatusApi`)
   - Protocol: HTTPS/JSON

2. **Load Deployment Record**: Backend queries the `deployments` table for the current `phase`, `status`, `error_message`, `git_commit_hash`, `jenkins_build_number`, `jenkins_build_url`, and `updated_at`.
   - From: `backendDeploymentStatusApi`
   - To: `continuumCloudBackendPostgres`
   - Protocol: SQL

3. **Conditional Jenkins Poll** (only when `phase = synced` or `phase = building`):

   3a. **Load Application Context**: Backend fetches the application to retrieve `organizationId` for constructing the Jenkins job path.
   - From: `backendDeploymentStatusApi` → `backendApplicationsApi`
   - To: `continuumCloudBackendPostgres`
   - Protocol: SQL

   3b. **Find Jenkins Build by Commit Hash**: Backend calls `jenkinsClient.FindBuildByCommit(ctx, orgId, appName, commitHash)`. Falls back to `GetLastBuildInfo` if no commit-specific build is found.
   - From: `backendJenkinsClient`
   - To: `jenkinsController` (`https://cloud-jenkins.groupondev.com`)
   - Protocol: HTTPS/Jenkins API

   3c. **Evaluate Build State**: Backend calls `jenkinsClient.IsBuildComplete(buildInfo)`:
   - Still building → phase remains `building`, status `in_progress`
   - Completed with `SUCCESS` → phase transitions to `ready_to_deploy`, status `completed`
   - Completed with failure → phase remains `building`, status `failed`

   3d. **Persist Phase Update**: Backend writes updated `phase`, `status`, `jenkins_build_number`, `jenkins_build_url`, and `jenkins_last_checked_at` to the `deployments` row.
   - From: `backendDeploymentStatusApi`
   - To: `continuumCloudBackendPostgres`
   - Protocol: SQL

4. **Construct Deploybot URL** (only when `phase = ready_to_deploy`): Backend builds `https://deploybot.groupondev.com/{organizationId}/{applicationId}` and includes it in the response.
   - From: `backendDeploymentStatusApi`
   - To: (in-process)
   - Protocol: In-process

5. **Return Status Response**: Backend returns `{ id, phase, status, gitCommitHash, jenkinsBuildNumber, jenkinsBuildUrl, deploybotUrl, message, updatedAt }`.
   - From: `continuumCloudBackendApi`
   - To: `continuumCloudUi`
   - Protocol: HTTPS/JSON

6. **UI Displays Phase**: Frontend renders the deployment phase message and, if `ready_to_deploy`, displays the Deploybot link for the engineer.
   - From: `cloudUiPages`
   - To: Engineer (browser)
   - Protocol: UI rendering

## Phase Messages

| Phase | Status | Message Shown |
|-------|--------|---------------|
| `queued` | any | "Deployment queued, waiting to sync configuration to git" |
| `syncing` | in_progress | "Syncing configuration to git repository" |
| `syncing` | failed | "Failed to sync configuration to git" |
| `synced` | in_progress | "Configuration synced to git. Waiting for Jenkins to start build..." |
| `synced` | failed | "Jenkins job not found or unreachable. Check that the Jenkins job exists." |
| `building` | in_progress | "Jenkins is building and publishing the artifact" |
| `building` | failed | "Jenkins build failed" |
| `ready_to_deploy` | completed | "Build successful! Click below to deploy via Deploybot" |
| `no_changes` | any | "No configuration changes detected - deployment already up to date" |

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deployment ID not found | Returns `not_found` error | UI shows error; polling stops |
| Jenkins unreachable during `synced` phase | Error is logged; phase not advanced; polling continues | UI continues polling |
| Stuck in `synced` for > 5 minutes | Backend marks `status: failed` with Jenkins error message | UI shows failure; engineer must investigate Jenkins |
| Organization or application not found during Deploybot URL construction | URL is omitted from response | `ready_to_deploy` phase reached but no Deploybot link shown |

## Sequence Diagram

```
CloudUI -> CloudBackendAPI: GET /deployments/:deploymentId/status
CloudBackendAPI -> PostgreSQL: SELECT phase, status, git_commit_hash, jenkins_* FROM deployments
PostgreSQL --> CloudBackendAPI: { phase: "synced", git_commit_hash: "abc123" }
CloudBackendAPI -> PostgreSQL: SELECT organization_id FROM applications WHERE id = app_id
CloudBackendAPI -> Jenkins: FindBuildByCommit(orgId, appName, "abc123")
Jenkins --> CloudBackendAPI: { building: true, number: 42, url: "https://..." }
CloudBackendAPI -> PostgreSQL: UPDATE deployments SET phase="building", jenkins_build_number=42
CloudBackendAPI --> CloudUI: { phase: "building", jenkinsBuildNumber: 42, message: "Jenkins is building..." }
[... next poll ...]
CloudUI -> CloudBackendAPI: GET /deployments/:deploymentId/status
CloudBackendAPI -> Jenkins: IsBuildComplete({ result: "SUCCESS" })
CloudBackendAPI -> PostgreSQL: UPDATE deployments SET phase="ready_to_deploy", status="completed"
CloudBackendAPI --> CloudUI: { phase: "ready_to_deploy", deploybotUrl: "https://deploybot.groupondev.com/org/app", message: "Build successful!" }
```

## Related

- Architecture dynamic view: `dynamic-gitops-deployment-flow`
- Related flows: [GitOps Deployment](gitops-deployment.md)
