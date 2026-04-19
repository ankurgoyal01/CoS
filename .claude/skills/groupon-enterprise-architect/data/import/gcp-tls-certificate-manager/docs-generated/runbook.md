---
service: "gcp-tls-certificate-manager"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

> No evidence found in codebase.

This service has no persistent process and therefore no HTTP health endpoint. Pipeline health is assessed by monitoring Jenkins build status and DeployBot deployment results. The success of a deployment is confirmed by checking the DeployBot deployment log for the expected certificate creation output.

| Mechanism | Type | How to Check |
|-----------|------|-------------|
| Jenkins build status | CI | Check [gcp-tls-certificate-manager Jenkins job](https://cloud-jenkins.groupondev.com/job/dnd-gcp-migration-infra/job/gcp-tls-certificate-manager/) |
| DeployBot deployment status | Deployment | Check [DeployBot](https://deploybot.groupondev.com/dnd-gcp-migration-infra/gcp-tls-certificate-manager) for deployment log |
| GCP Secret Manager secret existence | Data verification | Run `gcloud secrets describe tls--{org}-{service} --project={project_id}` |

## Monitoring

### Metrics

> No evidence found in codebase.

No application metrics are emitted. Operational health is monitored through CI/CD tooling rather than metrics dashboards.

### Dashboards

> No evidence found in codebase.

| Dashboard | Tool | Link |
|-----------|------|------|
| Jenkins pipeline runs | Jenkins | [gcp-tls-certificate-manager](https://cloud-jenkins.groupondev.com/job/dnd-gcp-migration-infra/job/gcp-tls-certificate-manager/) |
| DeployBot deployments | DeployBot | [gcp-tls-certificate-manager deployments](https://deploybot.groupondev.com/dnd-gcp-migration-infra/gcp-tls-certificate-manager) |
| Service Portal | Groupon Services Portal | [gcp-tls-certificate-manager](https://services.groupondev.com/services/gcp-tls-certificate-manager) |

### Alerts

> No evidence found in codebase.

No automated alerting is configured in this repository. Jenkins build failure notifications are sent to the Slack channel `google-groupon-pipelines-pod` for dev/staging environments and `asadauskas` for production (via DeployBot's `notify_events: start, complete, override` setting).

## Common Operations

### Trigger a New Certificate Deployment

1. Create or modify a JSON request file in `requests/{org}/{service}.json` following the format in `README.md`.
2. Raise a Pull Request against the `main` branch and get it approved.
3. Merge the PR — this triggers the Jenkins pipeline via GitHub push event.
4. Monitor the Jenkins build at [Jenkins](https://cloud-jenkins.groupondev.com/job/dnd-gcp-migration-infra/job/gcp-tls-certificate-manager/).
5. Authorize the `dev-gcp` deployment in [ARQ](https://arq.groupondev.com/ra/ad_subservices/gcp-tls-certificate-manager) or [DeployBot](https://deploybot.groupondev.com/dnd-gcp-migration-infra/gcp-tls-certificate-manager).
6. Once dev succeeds, promote to `staging-gcp`, then to `production-gcp` (requires GPROD ticket for production).

### Trigger a Manual Certificate Refresh

1. Navigate to [DeployBot](https://deploybot.groupondev.com/dnd-gcp-migration-infra/gcp-tls-certificate-manager).
2. Trigger a deployment to the `dev-gcp-refresh` target manually.
3. Monitor deployment log and promote to `staging-gcp-refresh` and `production-gcp-refresh`.
4. Notify the `gcp-groupon-migration-factory` Google Chat room before running refresh in production.

### Add a New Service Certificate Request

1. Create a new directory under `requests/` named for the organization if it does not exist.
2. Create a JSON file following the request file format from `README.md`.
3. Fill in `org`, `service`, `environments` (with `project_id` and `accessors` for each of dev, staging, production).
4. Optionally add `cntype: "legacy"` if a legacy mTLS certificate is required.
5. Set `seq: 1` (or any integer) to identify the initial version.
6. Raise a PR and notify in the `gcp-groupon-migration-factory` Google Chat room.

### Remove a Certificate

1. Delete the corresponding JSON request file from `requests/`.
2. Raise a PR and merge to `main`.
3. The pipeline detects the Delete action and removes both the GCP Secret Manager secret and the cert-manager resources in Conveyor Cloud.

### Scale Up / Down

> Not applicable — this service has no long-running process to scale.

### Database Operations

> Not applicable — this service owns no database.

## Troubleshooting

### Missing `tls-certificate-cicd-sa-key` Kubernetes secret

- **Symptoms**: DeployBot deployment fails with `Error from server (NotFound): secrets "tls-certificate-cicd-sa-key" not found`
- **Cause**: The GCP service account JSON key has not been loaded into the Conveyor Cloud namespace as a Kubernetes secret
- **Resolution**: Acquire the SA JSON key for the environment, save it as `tls-manager-cicd`, then run `kubectl create secret generic tls-certificate-cicd-sa-key --from-file=./tls-manager-cicd` in the appropriate namespace (`gcp-tls-certificate-manager-{env}`)

### GCP Secret Not Created After Successful Deployment

- **Symptoms**: DeployBot log shows deployment completed but the `tls--{org}-{service}` secret does not appear in GCP Secret Manager
- **Cause**: Incorrect `project_id` in the request file, or the deploybot log did not show an action line for the request file
- **Resolution**: Verify `project_id` in the request file matches the expected GCP project. Check DeployBot logs for a line starting with `Certificate request:` and confirm action (`A`/`M`/`D`) was processed. Re-examine for errors such as missing permissions or invalid project.

### TLS Certificate Chain Validation Error

- **Symptoms**: Downstream service reports TLS chain error or certificate validation failure when using the provisioned certificate
- **Cause**: The Groupon root CA certificate is missing from the `certificate_chain` field in the GCP secret. It should be dynamically appended during certificate creation.
- **Resolution**: Inspect the secret value JSON; verify `certificate_chain` contains at least two certificates and the last one matches the Groupon root CA at `https://raw.github.groupondev.com/ApplicationSecurity/certrotate/master/GrouponRootCA.pem`. A debugging session in the deploybot image may be needed to diagnose why the root CA was not appended.

### Kubernetes ServiceUnavailable During Certificate Patch

- **Symptoms**: Deployment fails with `Error from server (ServiceUnavailable): error when applying patch` on a cert-manager Certificate resource
- **Cause**: Transient Kubernetes API server unavailability — typically a timing issue with the Conveyor Cloud control plane
- **Resolution**: Retry the deployment via DeployBot. No other action required.

### Pipeline Does Not Trigger on Push

- **Symptoms**: A PR is merged with `requests/` changes but no Jenkins pipeline runs (or the pipeline runs but `DeployNewUpdated` stage is skipped)
- **Cause**: Either the pipeline was not triggered by a GitHub push event (`isTriggeredByPushEvent` is false), or `has-cert-requests.sh` did not detect changes (no diff under `requests/` in the merge commit)
- **Resolution**: Verify that the push event was received by Jenkins (check build causes). Verify that the changed files are under `requests/` (not in other directories). For complex git operations (renames, copies), the current implementation may not detect them — simplify the change and re-commit.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | All certificate refreshes failing; downstream GCP services lose Hybrid Boundary access as certificates expire | Immediate | dnd-gcp-migration-infra team; notify `gcp-groupon-migration-factory` |
| P2 | Single service certificate deployment failing; one team's GCP workload unable to reach internal services | 30 min | dnd-gcp-migration-infra team |
| P3 | Monthly refresh delayed; certificates remain valid for 60+ days | Next business day | dnd-gcp-migration-infra team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| GitHub Enterprise | Check repository accessibility via `git ls-remote` | None; pipeline cannot proceed without repository access |
| Conveyor Cloud Kubernetes | Run `kubectl get pods -n gcp-tls-certificate-manager-{env}` | Retry deployment after cluster stabilizes |
| GCP Secret Manager | Run `gcloud secrets list --project={project_id}` | None; TLS material cannot be stored without Secret Manager access |
| DeployBot | Check [DeployBot status](https://deploybot.groupondev.com) | Manual certificate provisioning via direct kubectl/gcloud commands |
| cert-manager | Check cert-manager controller pods in Conveyor Cloud | Retry; contact Conveyor Cloud platform team if persistent |
