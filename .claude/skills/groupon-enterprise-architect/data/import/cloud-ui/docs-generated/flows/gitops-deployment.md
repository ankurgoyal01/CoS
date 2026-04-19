---
service: "cloud-ui"
title: "GitOps Deployment Flow"
generated: "2026-03-03"
type: flow
flow_name: "gitops-deployment"
flow_type: synchronous
trigger: "User clicks 'Deploy' on the application detail page and selects environment and region"
participants:
  - "continuumCloudUi"
  - "continuumCloudBackendApi"
  - "continuumCloudBackendPostgres"
  - "gitRepositorySystem"
  - "jenkinsController"
  - "deploybotSystem"
architecture_ref: "dynamic-gitops-deployment-flow"
---

# GitOps Deployment Flow

## Summary

The GitOps Deployment flow is the end-to-end process by which a configuration change is committed to a Git repository and driven through Jenkins to a Deploybot-ready artifact. The user initiates the flow from the Cloud UI by creating a deployment record and triggering a Git sync. The Cloud Backend renders Helm values for each component, commits generated YAML files to the application's Git repository, then polls Jenkins until the build succeeds — at which point a Deploybot URL is surfaced to the engineer for final deployment.

## Trigger

- **Type**: user-action
- **Source**: Engineer clicks the deploy action on the application detail page in `continuumCloudUi`
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cloud UI Web App | Initiates deployment and Git sync; polls status; displays phase progression | `continuumCloudUi` |
| Cloud Backend API | Orchestrates all backend steps: persists deployment, acquires sync lock, renders Helm values, commits to Git, polls Jenkins | `continuumCloudBackendApi` |
| Cloud Backend PostgreSQL | Stores deployment record and phase transitions; holds sync lock state | `continuumCloudBackendPostgres` |
| Git Repository | Receives committed Helm values YAML files via SSH push | (stub) `gitRepositorySystem` |
| Jenkins | Detects the commit, builds and publishes the artifact; polled by backend for status | `jenkinsController` |
| Deploybot | Provides final deployment execution; URL is constructed by the backend and surfaced in the UI | (stub) `deploybotSystem` |

## Steps

1. **Create Deployment Record**: User triggers deployment from Cloud UI; frontend calls `POST /cloud-backend/applications/:appId/deployments`.
   - From: `continuumCloudUi`
   - To: `continuumCloudBackendApi` (`backendApplicationsApi`)
   - Protocol: HTTPS/JSON

2. **Persist Deployment**: Backend inserts deployment row with `phase: queued`, `status: pending`.
   - From: `continuumCloudBackendApi`
   - To: `continuumCloudBackendPostgres`
   - Protocol: SQL

3. **Trigger Git Sync**: Frontend calls `POST /cloud-backend/applications/:id/sync-to-git` with `environment` and `region`.
   - From: `continuumCloudUi`
   - To: `continuumCloudBackendApi` (`backendGitSyncApi`)
   - Protocol: HTTPS/JSON

4. **Acquire Sync Lock**: Backend sets `sync_in_progress = TRUE` on the application record to prevent concurrent syncs.
   - From: `continuumCloudBackendApi`
   - To: `continuumCloudBackendPostgres`
   - Protocol: SQL

5. **Advance to Syncing Phase**: Backend updates deployment phase to `syncing`.
   - From: `continuumCloudBackendApi`
   - To: `continuumCloudBackendPostgres`
   - Protocol: SQL

6. **Render Helm Values**: Backend calls `backendHelmAdapter` to map each component's configuration to Helm values YAML for the target environment and region.
   - From: `backendGitSyncApi`
   - To: `backendHelmAdapter`
   - Protocol: In-process

7. **Clone Git Repository**: Backend clones the application's `mainRepoUrl` via SSH using the `CloudBackendGitSSHKey` secret.
   - From: `continuumCloudBackendApi`
   - To: `gitRepositorySystem`
   - Protocol: SSH Git

8. **Commit and Push Config**: Backend writes generated Helm values YAML files to the repository, creates a Git commit, and pushes to the remote.
   - From: `continuumCloudBackendApi`
   - To: `gitRepositorySystem`
   - Protocol: SSH Git

9. **Advance to Synced Phase**: Backend stores the Git commit hash and updates deployment phase to `synced`.
   - From: `continuumCloudBackendApi`
   - To: `continuumCloudBackendPostgres`
   - Protocol: SQL

10. **Release Sync Lock**: Backend sets `sync_in_progress = FALSE` on the application record.
    - From: `continuumCloudBackendApi`
    - To: `continuumCloudBackendPostgres`
    - Protocol: SQL

11. **UI Polls Deployment Status**: Frontend begins polling `GET /cloud-backend/deployments/:deploymentId/status`.
    - From: `continuumCloudUi`
    - To: `continuumCloudBackendApi` (`backendDeploymentStatusApi`)
    - Protocol: HTTPS/JSON

12. **Poll Jenkins for Build**: On each status poll where phase is `synced` or `building`, backend queries Jenkins by commit hash via `FindBuildByCommit`; falls back to `GetLastBuildInfo`.
    - From: `continuumCloudBackendApi` (`backendJenkinsClient`)
    - To: `jenkinsController`
    - Protocol: HTTPS/Jenkins API

13. **Advance to Building Phase**: When Jenkins build is found and in progress, backend updates phase to `building`, stores `jenkins_build_number` and `jenkins_build_url`.
    - From: `continuumCloudBackendApi`
    - To: `continuumCloudBackendPostgres`
    - Protocol: SQL

14. **Advance to Ready to Deploy**: When Jenkins build completes successfully, backend updates phase to `ready_to_deploy`, status to `completed`; constructs Deploybot URL (`https://deploybot.groupondev.com/{orgId}/{appId}`).
    - From: `continuumCloudBackendApi`
    - To: `continuumCloudBackendPostgres` + response to `continuumCloudUi`
    - Protocol: SQL + HTTPS/JSON

15. **Engineer Deploys via Deploybot**: UI displays Deploybot URL; engineer navigates to it to trigger final Kubernetes deployment.
    - From: Engineer (browser)
    - To: `deploybotSystem`
    - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Application has no `mainRepoUrl` configured | `SyncToGit` returns early with `success: false` message | Deployment phase not advanced; no Git operations attempted |
| Another sync is already in progress (`sync_in_progress = TRUE`) | Backend returns conflict error | Frontend receives error; user must wait for lock to clear |
| Git clone or push fails | Exception caught; sync lock released; phase set to `synced`/`failed` | Deployment shows failed state; user must investigate Git repository access |
| Jenkins build not found after 5 minutes in `synced` phase | Backend marks deployment `status: failed`, error message set | User must verify Jenkins job exists and retry |
| Jenkins build fails (`result != SUCCESS`) | Phase stays `building`, status set to `failed` | UI shows failure; user must investigate Jenkins build logs |
| No Git changes detected | Sync succeeds with `hasChanges: false`; phase advances to `no_changes` | UI shows no-changes state; Deploybot URL not surfaced |

## Sequence Diagram

```
CloudUI -> CloudBackendAPI: POST /applications/:appId/deployments
CloudBackendAPI -> PostgreSQL: INSERT deployment (phase=queued)
CloudUI -> CloudBackendAPI: POST /applications/:id/sync-to-git
CloudBackendAPI -> PostgreSQL: SET sync_in_progress=TRUE, UPDATE phase=syncing
CloudBackendAPI -> HelmAdapter: Render Helm values for components
CloudBackendAPI -> GitRepository: Clone via SSH, commit Helm values YAML, push
CloudBackendAPI -> PostgreSQL: UPDATE phase=synced, git_commit_hash=<hash>
CloudBackendAPI -> PostgreSQL: SET sync_in_progress=FALSE
CloudUI -> CloudBackendAPI: GET /deployments/:id/status (polling)
CloudBackendAPI -> Jenkins: FindBuildByCommit(org, app, commitHash)
CloudBackendAPI -> PostgreSQL: UPDATE phase=building, jenkins_build_number, jenkins_build_url
CloudUI -> CloudBackendAPI: GET /deployments/:id/status (polling continues)
CloudBackendAPI -> Jenkins: IsBuildComplete(buildInfo)
CloudBackendAPI -> PostgreSQL: UPDATE phase=ready_to_deploy, status=completed
CloudBackendAPI --> CloudUI: { phase: ready_to_deploy, deploybotUrl: "https://deploybot.groupondev.com/..." }
```

## Related

- Architecture dynamic view: `dynamic-gitops-deployment-flow`
- Related flows: [Deployment Status Polling](deployment-status-polling.md), [Application Creation](application-creation.md)
