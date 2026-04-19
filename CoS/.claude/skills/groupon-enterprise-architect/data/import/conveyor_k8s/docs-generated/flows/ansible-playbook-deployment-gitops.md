---
service: "conveyor_k8s"
title: "Ansible Playbook Deployment (GitOps)"
generated: "2026-03-03"
type: flow
flow_name: "ansible-playbook-deployment-gitops"
flow_type: event-driven
trigger: "GitHub pull request opened/synchronized (dev), or version tag push `v*.*.*` (stable/production), or manual workflow_dispatch (hotfix/rollback)"
participants:
  - "conveyorK8sPipelines"
  - "conveyorK8sAnsiblePlaybooks"
  - "gcp"
  - "kubernetesClusters"
architecture_ref: "dynamic-conveyorK8s"
---

# Ansible Playbook Deployment (GitOps)

## Summary

This is the primary GitOps workflow for delivering Kubernetes cluster configuration changes to all environments. When a pull request modifies `conveyor_provisioning_playbook/**`, GitHub Actions detects which Ansible playbooks have changed (by diffing the PR branch or comparing version tags), runs those playbooks against the target cluster(s), and — for dev deployments — automatically rolls back to master once the PR run completes. Production deployments require a manual approval gate before execution.

## Trigger

- **Type**: event (push / tag / manual)
- **Source**: GitHub repository events — PR open/sync (`apply-ansible-playbook-dev.yml`), tag push `v*.*.*` (`apply-ansible-playbook-stable.yml`, `apply-ansible-playbook-production.yml`), or `workflow_dispatch` (`apply-ansible-playbook-manual.yml`)
- **Frequency**: Per pull request, per version release, or on-demand for manual hotfix/rollback

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GitHub Actions | Orchestrates all workflow steps | `conveyorK8sPipelines` |
| detect-playbooks action | Diffs git history to determine which playbooks changed | `conveyorK8sPipelines` |
| run-playbooks action | Executes `ansible-playbook` for each changed playbook | `conveyorK8sAnsiblePlaybooks` |
| rollback-playbooks action | Re-applies master playbooks to restore dev cluster state (dev only) | `conveyorK8sAnsiblePlaybooks` |
| GCP Service Account | Authenticates to GCP for cluster access | `gcp` (external stub) |
| GKE Cluster (US/EU) | Target Kubernetes cluster for Ansible configuration | `kubernetesClusters` (external stub) |

## Steps

1. **Checkout repository**: Full depth fetch including all tags is required for tag diffing.
   - From: `conveyorK8sPipelines`
   - To: GitHub (actions/checkout@v4)
   - Protocol: Git (HTTPS)

2. **Authenticate to GCP**: The `conveyor-cloud/conveyor-gh-shared-actions/.github/actions/gcp-auth@main` action activates the GCP Service Account using `GCP_SERVICE_ACCOUNT_JSON` secret.
   - From: `conveyorK8sPipelines`
   - To: `gcp`
   - Protocol: GCP API (service account key)

3. **Detect changed playbooks**: The `detect-playbooks` composite action runs in two modes:
   - **PR mode** (`MODE: pr`): Fetches `BASE_REF` and diffs `git diff --name-only FETCH_HEAD` against `conveyor_provisioning_playbook/`. Maps changed roles/files to their `install_*.yml` playbooks.
   - **Tag mode** (`MODE: tag`): Fetches the previous SemVer tag and diffs it against `CURRENT_TAG` to find changed playbooks between releases.
   - Outputs a space-separated `playbooks` list and an initial deployment summary.
   - From: `conveyorK8sPipelines`
   - To: local git history
   - Protocol: git CLI

4. **Run playbooks**: The `run-playbooks` composite action iterates over detected playbooks and runs `ansible-playbook --user svc_conveyor -i inventory/gcp_grpn.py --limit <cluster> <playbook>` for each. Uses `VAULT_PASSPHRASE` for Ansible Vault-encrypted variables. US and EU clusters run as separate parallel GitHub Actions jobs.
   - From: `conveyorK8sAnsiblePlaybooks`
   - To: `kubernetesClusters`
   - Protocol: Ansible / Kubernetes API

5. **Rollback playbooks** (dev environment only): After the PR run, the `rollback-playbooks` action checks out master branch for `conveyor_provisioning_playbook/` and re-runs the same playbooks against the dev cluster, restoring it to the known-good master state.
   - From: `conveyorK8sAnsiblePlaybooks`
   - To: `kubernetesClusters`
   - Protocol: Ansible / Kubernetes API

6. **Publish job summary**: The `publish-job-summary` composite action writes the accumulated deployment summary (playbook names, success/failure status) to the GitHub Actions job summary page.
   - From: `conveyorK8sPipelines`
   - To: GitHub Actions summary API
   - Protocol: GitHub Actions output

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No playbooks detected (empty diff) | `detect-playbooks` outputs empty list; `run-playbooks` is skipped | Job completes successfully; no-op |
| Ansible playbook fails (non-zero exit) | `run-playbooks` writes failure to summary file, exits non-zero | Job fails; dev rollback still runs after failure |
| GCP authentication fails | Workflow step fails immediately | No Ansible execution; operator checks `GCP_SERVICE_ACCOUNT_JSON` secret |
| Production deployment without approval | GitHub Actions environment protection blocks execution | Deployment waits for manual approval in GitHub environment settings |
| Rollback playbook fails (dev) | `rollback-playbooks` logs failure in summary; exits non-zero | Cluster may be in partial state; manual intervention required |

## Sequence Diagram

```
GitHub -> GitHubActions: PR opened/sync OR tag push OR workflow_dispatch
GitHubActions -> GCP: Authenticate (gcp-auth action, GCP_SERVICE_ACCOUNT_JSON)
GCP --> GitHubActions: Authenticated

GitHubActions -> detect_playbooks: Detect changed playbooks (MODE: pr | tag | manual)
detect_playbooks -> GitRepo: git diff --name-only
GitRepo --> detect_playbooks: Changed files list
detect_playbooks --> GitHubActions: playbooks=[install_X.yml, install_Y.yml]

GitHubActions -> run_playbooks (US job): ansible-playbook --limit GCP_CLUSTER_NAME_US install_X.yml
run_playbooks -> GKE_US: Apply Kubernetes configuration changes
GKE_US --> run_playbooks: Configuration applied
run_playbooks --> GitHubActions: Result (success/failure per playbook)

GitHubActions -> run_playbooks (EU job): ansible-playbook --limit GCP_CLUSTER_NAME_EU install_X.yml
run_playbooks -> GKE_EU: Apply Kubernetes configuration changes
GKE_EU --> run_playbooks: Configuration applied
run_playbooks --> GitHubActions: Result

GitHubActions -> rollback_playbooks (dev only): git checkout origin/master -- conveyor_provisioning_playbook/
rollback_playbooks -> GKE_US: ansible-playbook (master version)
GKE_US --> rollback_playbooks: Rollback applied
rollback_playbooks --> GitHubActions: Rollback summary

GitHubActions -> publish_summary: Write deployment summary to job page
publish_summary --> GitHubActions: Summary published
```

## Related

- Architecture dynamic view: `dynamic-conveyorK8s`
- Related flows: [Cluster Creation (GKE)](cluster-creation-gke.md) — initial playbook application during cluster creation
