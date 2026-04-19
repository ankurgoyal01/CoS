---
service: "gcp-tls-certificate-manager"
title: "Certificate Deletion"
generated: "2026-03-03"
type: flow
flow_name: "certificate-deletion"
flow_type: event-driven
trigger: "Push to main branch with a deleted requests/*.json file"
participants:
  - "githubEnterprise"
  - "gcpTlsCertificateManagerPipeline"
  - "jenkins_a2feef"
  - "deployBot_2e6910"
  - "conveyorCloudKubernetes_449f0f"
  - "gcpSecretManager_cc4b72"
  - "gcpIamServiceAccounts_18e576"
architecture_ref: "dynamic-gcpTlsCertificateManager-deletion"
---

# Certificate Deletion

## Summary

This flow handles the removal of a TLS certificate when an engineering team deletes a JSON request file from the `requests/` directory and merges to `main`. The Jenkins pipeline detects the deletion action (`D`), invokes DeployBot, which removes both the cert-manager Certificate resource (and associated Kubernetes Secret) from the Conveyor Cloud namespace and deletes the `tls--{org}-{service}` secret from GCP Secret Manager. Deletion is promoted through the same environment path as provisioning: dev → staging → production.

## Trigger

- **Type**: event
- **Source**: GitHub Enterprise push event on `main` branch; `has-cert-requests.sh` detects a deleted file under `requests/`
- **Frequency**: On demand (every PR merge that removes a request file)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GitHub Enterprise | Hosts repository; sends push webhook; provides git diff to detect deletion | `githubEnterprise` |
| Jenkins | Receives push event; runs pipeline stages; detects `D` action | `jenkins_a2feef` |
| GCP TLS Certificate Manager Pipeline | Jenkinsfile and shell scripts | `gcpTlsCertificateManagerPipeline` |
| DeployBot | Runs deploybot image; removes Certificate resource and GCP secret | `deployBot_2e6910` |
| Conveyor Cloud Kubernetes | Hosts the cert-manager namespace; Certificate and Kubernetes Secret resources are removed | `conveyorCloudKubernetes_449f0f` |
| GCP IAM Service Accounts | Provides authentication credentials for GCP API calls | `gcpIamServiceAccounts_18e576` |
| GCP Secret Manager | Target secret (`tls--{org}-{service}`) is deleted | `gcpSecretManager_cc4b72` |

## Steps

1. **Engineer deletes request file**: Engineer removes `requests/{org}/{service}.json` from the repository and raises a PR.
   - From: `Engineer`
   - To: `githubEnterprise`
   - Protocol: GitHub Pull Request (HTTPS)

2. **PR merged to main**: PR merged; GitHub push event triggered.
   - From: `githubEnterprise`
   - To: `jenkins_a2feef`
   - Protocol: GitHub webhook

3. **Pipeline detects deletion**: `has-cert-requests.sh` finds a file removed from `requests/`; `get-cert-requests.sh` reports action `D` for the deleted file path.
   - From: `jenkins_a2feef`
   - To: `gcpTlsCertificateManagerPipeline`
   - Protocol: Jenkins pipeline execution (shell scripts against git diff)

4. **DeployBot invoked for dev-gcp**: Jenkins calls `deploybotDeploy()` targeting `dev-gcp`.
   - From: `gcpTlsCertificateManagerPipeline`
   - To: `deployBot_2e6910`
   - Protocol: Conveyor CI deploybotDeploy API

5. **DeployBot clones repo and activates credentials**: DeployBot clones at target SHA; activates GCP service account from `tls-certificate-cicd-sa-key`.
   - From: `deployBot_2e6910`
   - To: `githubEnterprise`, `gcpIamServiceAccounts_18e576`
   - Protocol: git (SSH), gcloud CLI

6. **DeployBot removes cert-manager Certificate resource**: Deploybot runs `kubectl delete` on the Certificate resource in `gcp-tls-certificate-manager-{env}` namespace; associated Kubernetes Secret is cleaned up.
   - From: `deployBot_2e6910`
   - To: `conveyorCloudKubernetes_449f0f`
   - Protocol: kubectl (Kubernetes API)

7. **DeployBot deletes GCP Secret Manager secret**: Deploybot runs `gcloud secrets delete tls--{org}-{service}` in the target GCP project, removing all versions and the secret itself.
   - From: `deployBot_2e6910`
   - To: `gcpSecretManager_cc4b72`
   - Protocol: gcloud CLI (GCP Secret Manager API)

8. **Promotion to staging and production**: Approver promotes through environments; steps 5–7 repeat per environment using the environment's `project_id` from the deleted request file's last known content.
   - From: `deployBot_2e6910`
   - To: `conveyorCloudKubernetes_449f0f`, `gcpSecretManager_cc4b72`
   - Protocol: kubectl, gcloud CLI

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GCP secret already deleted or does not exist | gcloud returns not-found error | Deployment may warn but does not block; certificate removal from Conveyor Cloud still proceeds |
| Kubernetes Certificate resource not found | kubectl delete returns not-found | Treated as already removed; GCP secret deletion still proceeds |
| cert-manager `ServiceUnavailable` during delete | Transient Kubernetes API error | Retry deployment; cert-manager resource may be left in an inconsistent state requiring manual cleanup |

## Sequence Diagram

```
Engineer -> githubEnterprise: Delete requests/{org}/{service}.json via PR and merge
githubEnterprise -> jenkins_a2feef: Push event webhook (main branch)
jenkins_a2feef -> gcpTlsCertificateManagerPipeline: Detect D action for deleted request file
gcpTlsCertificateManagerPipeline -> deployBot_2e6910: deploybotDeploy(dev-gcp, SHA)
deployBot_2e6910 -> githubEnterprise: git clone at SHA
deployBot_2e6910 -> gcpIamServiceAccounts_18e576: Activate SA credentials
deployBot_2e6910 -> conveyorCloudKubernetes_449f0f: kubectl delete Certificate resource in gcp-tls-certificate-manager-dev
deployBot_2e6910 -> gcpSecretManager_cc4b72: gcloud secrets delete tls--{org}-{service}
gcpSecretManager_cc4b72 --> deployBot_2e6910: Secret deleted
Approver -> deployBot_2e6910: Promote to staging-gcp, then production-gcp
```

## Related

- Architecture dynamic view: `dynamic-gcpTlsCertificateManager-deletion`
- Related flows: [New Certificate Provisioning](new-certificate-provisioning.md), [Certificate Update](certificate-update.md), [Monthly Certificate Refresh](monthly-certificate-refresh.md)
