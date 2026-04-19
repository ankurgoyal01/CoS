---
service: "gcp-tls-certificate-manager"
title: "Certificate Update / Accessor Change"
generated: "2026-03-03"
type: flow
flow_name: "certificate-update"
flow_type: event-driven
trigger: "Push to main branch with a modified requests/*.json file"
participants:
  - "githubEnterprise"
  - "gcpTlsCertificateManagerPipeline"
  - "jenkins_a2feef"
  - "deployBot_2e6910"
  - "conveyorCloudKubernetes_449f0f"
  - "certManager_8a8826"
  - "gcpSecretManager_cc4b72"
  - "gcpIamServiceAccounts_18e576"
architecture_ref: "dynamic-gcpTlsCertificateManager-update"
---

# Certificate Update / Accessor Change

## Summary

This flow handles modifications to an existing certificate request. When a team modifies a JSON file in `requests/` (typically to change the `accessors` list or increment `seq` to force regeneration) and merges to `main`, the Jenkins pipeline detects the modification action (`M`), invokes DeployBot to regenerate the certificate in Conveyor Cloud using cert-manager, retrieves the new TLS material, and pushes a new version to the existing GCP Secret Manager secret. The primary supported use case is accessor list changes; changing `project_id` is not fully supported and may result in an orphaned secret in the old project.

## Trigger

- **Type**: event
- **Source**: GitHub Enterprise push event on `main` branch; `has-cert-requests.sh` detects a modified file under `requests/`
- **Frequency**: On demand (every PR merge that modifies an existing request file)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GitHub Enterprise | Hosts repository; sends push webhook; provides git diff to detect modification | `githubEnterprise` |
| Jenkins | Receives push event; runs pipeline stages; detects `M` action | `jenkins_a2feef` |
| GCP TLS Certificate Manager Pipeline | Jenkinsfile and shell scripts | `gcpTlsCertificateManagerPipeline` |
| DeployBot | Runs deploybot image; applies updated Certificate resource; pushes new secret version | `deployBot_2e6910` |
| Conveyor Cloud Kubernetes | Hosts the cert-manager namespace; receives updated Certificate resource | `conveyorCloudKubernetes_449f0f` |
| cert-manager | Re-issues the TLS certificate for the updated Certificate resource | `certManager_8a8826` |
| GCP IAM Service Accounts | Provides authentication credentials | `gcpIamServiceAccounts_18e576` |
| GCP Secret Manager | Receives the new TLS material as a new secret version | `gcpSecretManager_cc4b72` |

## Steps

1. **Engineer modifies request file**: Engineer edits `requests/{org}/{service}.json` (e.g., adds a new accessor, increments `seq`) and raises a PR.
   - From: `Engineer`
   - To: `githubEnterprise`
   - Protocol: GitHub Pull Request (HTTPS)

2. **PR merged to main**: PR merged; GitHub push event triggered.
   - From: `githubEnterprise`
   - To: `jenkins_a2feef`
   - Protocol: GitHub webhook

3. **Pipeline detects modification**: `has-cert-requests.sh` finds a modified file under `requests/`; `get-cert-requests.sh` reports action `M` for the file.
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

6. **DeployBot applies updated Certificate resource**: Deploybot applies the updated cert-manager Certificate resource with the existing CN; cert-manager re-issues the certificate.
   - From: `deployBot_2e6910`
   - To: `conveyorCloudKubernetes_449f0f`
   - Protocol: kubectl (Kubernetes API)

7. **cert-manager re-issues certificate**: cert-manager renews the Certificate and stores updated TLS material in the Kubernetes Secret.
   - From: `certManager_8a8826`
   - To: `conveyorCloudKubernetes_449f0f`
   - Protocol: cert-manager.io/v1 Kubernetes API

8. **DeployBot retrieves updated TLS material**: Deploybot reads the updated Kubernetes Secret.
   - From: `deployBot_2e6910`
   - To: `conveyorCloudKubernetes_449f0f`
   - Protocol: kubectl

9. **DeployBot adds new version to GCP Secret**: Deploybot pushes new TLS material as a new version of the existing `tls--{org}-{service}` secret. Updated IAM bindings are applied if `accessors` changed.
   - From: `deployBot_2e6910`
   - To: `gcpSecretManager_cc4b72`
   - Protocol: gcloud CLI (GCP Secret Manager API)

10. **Promotion to staging and production**: Approver promotes through environments; steps 5–9 repeat per environment.
    - From: `deployBot_2e6910`
    - To: `conveyorCloudKubernetes_449f0f`, `gcpSecretManager_cc4b72`
    - Protocol: kubectl, gcloud CLI

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `project_id` changed in request file | Deploybot updates certificate in new project; old project's secret is orphaned | Operator must manually delete the old secret from the original GCP project |
| cert-manager `ServiceUnavailable` | Transient Kubernetes error | Retry deployment via DeployBot UI |
| Accessor update fails (IAM permission denied) | gcloud returns permission error | New accessor cannot read the secret; verify the GCP service account has necessary IAM roles and retry |

## Sequence Diagram

```
Engineer -> githubEnterprise: Modify requests/{org}/{service}.json via PR and merge
githubEnterprise -> jenkins_a2feef: Push event webhook (main branch)
jenkins_a2feef -> gcpTlsCertificateManagerPipeline: Detect M action for request file
gcpTlsCertificateManagerPipeline -> deployBot_2e6910: deploybotDeploy(dev-gcp, SHA)
deployBot_2e6910 -> githubEnterprise: git clone at SHA
deployBot_2e6910 -> gcpIamServiceAccounts_18e576: Activate SA credentials
deployBot_2e6910 -> conveyorCloudKubernetes_449f0f: kubectl apply updated Certificate resource
certManager_8a8826 --> conveyorCloudKubernetes_449f0f: Re-issue TLS certificate; update Kubernetes Secret
deployBot_2e6910 -> conveyorCloudKubernetes_449f0f: kubectl get secret (retrieve updated TLS material)
deployBot_2e6910 -> gcpSecretManager_cc4b72: gcloud secrets versions add tls--{org}-{service}
gcpSecretManager_cc4b72 --> deployBot_2e6910: New version added
Approver -> deployBot_2e6910: Promote to staging-gcp, then production-gcp
```

## Related

- Architecture dynamic view: `dynamic-gcpTlsCertificateManager-update`
- Related flows: [New Certificate Provisioning](new-certificate-provisioning.md), [Certificate Deletion](certificate-deletion.md), [Monthly Certificate Refresh](monthly-certificate-refresh.md)
