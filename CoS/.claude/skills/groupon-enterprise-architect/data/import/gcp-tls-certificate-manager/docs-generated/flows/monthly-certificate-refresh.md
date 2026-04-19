---
service: "gcp-tls-certificate-manager"
title: "Monthly Certificate Refresh"
generated: "2026-03-03"
type: flow
flow_name: "monthly-certificate-refresh"
flow_type: scheduled
trigger: "Jenkins cron schedule: H 12 1-7 * 1 (first Monday of each month, ~noon UTC)"
participants:
  - "gcpTlsCertificateManagerPipeline"
  - "jenkins_a2feef"
  - "deployBot_2e6910"
  - "githubEnterprise"
  - "conveyorCloudKubernetes_449f0f"
  - "certManager_8a8826"
  - "gcpSecretManager_cc4b72"
  - "gcpIamServiceAccounts_18e576"
architecture_ref: "dynamic-gcpTlsCertificateManager-refresh"
---

# Monthly Certificate Refresh

## Summary

All certificates managed by this service have a 90-day expiry period from the issuing CA. To ensure downstream services always have a certificate valid for at least 60 days (providing a 30-day buffer for a single refresh failure), all certificates are renewed on the first Monday of each month via a Jenkins cron trigger. When `CERTIFICATE_REFRESH=1` is set, the deploybot image processes every request file regardless of git change status, re-issuing all cert-manager Certificate resources and pushing new versions to all GCP Secret Manager secrets. The refresh follows the same environment promotion path as provisioning: dev → staging → production, with manual approval required for production.

## Trigger

- **Type**: schedule
- **Source**: Jenkins cron expression `H 12 1-7 * 1` (first Monday of each month, at a randomized minute around noon UTC)
- **Frequency**: Monthly (first Monday of each month)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Jenkins | Fires the scheduled cron trigger; sets `isTriggeredByTimer=true` | `jenkins_a2feef` |
| GCP TLS Certificate Manager Pipeline | Jenkinsfile detects timer trigger; invokes `deploybotDeploy()` for `dev-gcp-refresh` | `gcpTlsCertificateManagerPipeline` |
| DeployBot | Runs deploybot image with `CERTIFICATE_REFRESH=1`; processes all request files | `deployBot_2e6910` |
| GitHub Enterprise | Source of all request files (cloned at HEAD SHA) | `githubEnterprise` |
| Conveyor Cloud Kubernetes | Hosts cert-manager namespaces; receives updated Certificate resources for all services | `conveyorCloudKubernetes_449f0f` |
| cert-manager | Re-issues TLS certificates for all registered Certificate resources | `certManager_8a8826` |
| GCP IAM Service Accounts | Provides authentication credentials for GCP API calls | `gcpIamServiceAccounts_18e576` |
| GCP Secret Manager | Receives new TLS material versions for all `tls--{org}-{service}` secrets | `gcpSecretManager_cc4b72` |

## Steps

1. **Jenkins cron fires**: On the first Monday of the month at approximately noon UTC, the Jenkins timer trigger fires the pipeline; `isTriggeredByTimer=true`.
   - From: Jenkins scheduler
   - To: `jenkins_a2feef`
   - Protocol: Jenkins TimerTrigger

2. **Pipeline Init stage runs**: Pipeline evaluates `isTriggeredByTimer=true`; change detection via `has-cert-requests.sh` is still run but `DeployRefresh` stage does not require `hasRequests=true`.
   - From: `jenkins_a2feef`
   - To: `gcpTlsCertificateManagerPipeline`
   - Protocol: Jenkins pipeline execution

3. **Validate Deploy Config stage runs**: `deploybotValidate()` validates `.deploy_bot.yml`.
   - From: `gcpTlsCertificateManagerPipeline`
   - To: `jenkins_a2feef`
   - Protocol: Conveyor CI utility

4. **DeployRefresh stage invokes DeployBot**: Jenkins calls `deploybotDeploy()` targeting `dev-gcp-refresh` (which has `CERTIFICATE_REFRESH=1` and `KUBERNETES_NAMESPACE=gcp-tls-certificate-manager-dev`).
   - From: `gcpTlsCertificateManagerPipeline`
   - To: `deployBot_2e6910`
   - Protocol: Conveyor CI deploybotDeploy API

5. **DeployBot clones repository**: DeployBot clones repo at HEAD SHA from GitHub Enterprise.
   - From: `deployBot_2e6910`
   - To: `githubEnterprise`
   - Protocol: git (SSH)

6. **DeployBot activates GCP credentials**: Reads `tls-certificate-cicd-sa-key` Kubernetes secret and activates GCP service account.
   - From: `deployBot_2e6910`
   - To: `gcpIamServiceAccounts_18e576`
   - Protocol: gcloud CLI / GCP IAM API

7. **DeployBot processes all request files**: Because `CERTIFICATE_REFRESH=1`, the deploybot script iterates over all JSON files in `requests/` (not just git-changed files) and treats each as requiring renewal.
   - From: `deployBot_2e6910`
   - To: `deployBot_2e6910` (internal iteration)
   - Protocol: shell iteration over `requests/**/*.json`

8. **DeployBot renews each cert-manager Certificate resource**: For each request file, deploybot applies an updated Kubernetes Certificate resource in the `gcp-tls-certificate-manager-dev` namespace. cert-manager re-issues the certificate.
   - From: `deployBot_2e6910`
   - To: `conveyorCloudKubernetes_449f0f`
   - Protocol: kubectl (Kubernetes API)

9. **cert-manager re-issues all certificates**: cert-manager processes each Certificate resource renewal and stores updated TLS material in the corresponding Kubernetes Secrets.
   - From: `certManager_8a8826`
   - To: `conveyorCloudKubernetes_449f0f`
   - Protocol: cert-manager.io/v1 Kubernetes API

10. **DeployBot retrieves updated TLS material for each service**: Deploybot reads each updated Kubernetes Secret, appends Groupon root CA to the chain.
    - From: `deployBot_2e6910`
    - To: `conveyorCloudKubernetes_449f0f`
    - Protocol: kubectl

11. **DeployBot pushes new secret versions to GCP**: For each service, deploybot adds a new version to the existing `tls--{org}-{service}` secret in the dev GCP project.
    - From: `deployBot_2e6910`
    - To: `gcpSecretManager_cc4b72`
    - Protocol: gcloud CLI (GCP Secret Manager API)

12. **Promotion to staging-gcp-refresh**: After dev refresh completes, human approver promotes to `staging-gcp-refresh` (`CERTIFICATE_REFRESH=1`, `KUBERNETES_NAMESPACE=gcp-tls-certificate-manager-staging`); steps 5–11 repeat for staging.
    - From: `deployBot_2e6910`
    - To: `conveyorCloudKubernetes_449f0f`, `gcpSecretManager_cc4b72`
    - Protocol: kubectl, gcloud CLI

13. **Promotion to production-gcp-refresh**: After staging refresh completes, human approver (with GPROD ticket) promotes to `production-gcp-refresh` (`kubernetes_cluster: gcp-production-us-central1`); steps 5–11 repeat for production.
    - From: `deployBot_2e6910`
    - To: `conveyorCloudKubernetes_449f0f`, `gcpSecretManager_cc4b72`
    - Protocol: kubectl, gcloud CLI

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| cert-manager `ServiceUnavailable` for one or more certificates | Retry the entire refresh deployment via DeployBot UI | Refresh retried; idempotent since existing valid certificates remain in GCP until overwritten |
| GCP Secret Manager version push fails for one service | gcloud returns error; deploybot logs indicate failure for that request | Other services' certificates are still refreshed; failed service must be retried manually |
| Refresh during deployment freeze (Moratorium) | VP approval required before proceeding | Refresh is deferred; certificates remain valid for remaining validity period |
| Monthly refresh missed | Certificates have 90-day validity; 60-day guaranteed validity with one refresh failure | Manually trigger `dev-gcp-refresh` via DeployBot UI; notify `gcp-groupon-migration-factory` before running |

## Sequence Diagram

```
Jenkins scheduler -> jenkins_a2feef: Cron fires (H 12 1-7 * 1 — first Monday of month)
jenkins_a2feef -> gcpTlsCertificateManagerPipeline: isTriggeredByTimer=true; run DeployRefresh stage
gcpTlsCertificateManagerPipeline -> deployBot_2e6910: deploybotDeploy(dev-gcp-refresh, SHA)
deployBot_2e6910 -> githubEnterprise: git clone at HEAD SHA
deployBot_2e6910 -> gcpIamServiceAccounts_18e576: Activate SA credentials
loop for each requests/**/*.json
  deployBot_2e6910 -> conveyorCloudKubernetes_449f0f: kubectl apply Certificate resource (renewal)
  certManager_8a8826 --> conveyorCloudKubernetes_449f0f: Re-issue TLS certificate; update Kubernetes Secret
  deployBot_2e6910 -> conveyorCloudKubernetes_449f0f: kubectl get secret (retrieve updated TLS material)
  deployBot_2e6910 -> gcpSecretManager_cc4b72: gcloud secrets versions add tls--{org}-{service}
end loop
deployBot_2e6910 --> gcpTlsCertificateManagerPipeline: dev refresh complete
Approver -> deployBot_2e6910: Promote to staging-gcp-refresh
Approver -> deployBot_2e6910: Promote to production-gcp-refresh (manual; GPROD ticket required)
```

## Related

- Architecture dynamic view: `dynamic-gcpTlsCertificateManager-refresh`
- Related flows: [New Certificate Provisioning](new-certificate-provisioning.md), [Certificate Update](certificate-update.md), [Certificate Deletion](certificate-deletion.md)
