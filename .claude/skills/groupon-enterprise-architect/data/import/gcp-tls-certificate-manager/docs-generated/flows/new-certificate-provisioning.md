---
service: "gcp-tls-certificate-manager"
title: "New Certificate Provisioning"
generated: "2026-03-03"
type: flow
flow_name: "new-certificate-provisioning"
flow_type: event-driven
trigger: "Push to main branch containing a new file under requests/"
participants:
  - "githubEnterprise"
  - "gcpTlsCertificateManagerPipeline"
  - "jenkins_a2feef"
  - "deployBot_2e6910"
  - "conveyorCloudKubernetes_449f0f"
  - "certManager_8a8826"
  - "gcpSecretManager_cc4b72"
  - "gcpIamServiceAccounts_18e576"
architecture_ref: "dynamic-gcpTlsCertificateManager-newProvisioning"
---

# New Certificate Provisioning

## Summary

This flow handles the end-to-end provisioning of a new TLS certificate when an engineering team adds a new JSON request file to the `requests/` directory and merges it to the `main` branch. The Jenkins pipeline detects the new file, invokes DeployBot to orchestrate the cert-manager Certificate resource creation in Conveyor Cloud, retrieves the issued TLS material, and publishes a versioned JSON secret to GCP Secret Manager accessible to the requesting service's GCP service accounts. The promotion follows the environment path dev → staging → production.

## Trigger

- **Type**: event
- **Source**: GitHub Enterprise push event on `main` branch; `has-cert-requests.sh` detects a new file under `requests/`
- **Frequency**: On demand (every PR merge that adds a new request file)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GitHub Enterprise | Hosts the repository; sends push webhook to Jenkins; provides git history for change detection | `githubEnterprise` |
| Jenkins | Receives push event; runs the pipeline; executes `has-cert-requests.sh` and `get-cert-requests.sh` | `jenkins_a2feef` |
| GCP TLS Certificate Manager Pipeline | The Jenkinsfile and shell scripts that orchestrate the overall flow | `gcpTlsCertificateManagerPipeline` |
| DeployBot | Receives deployment request; runs the deploybot image in the target environment; manages environment promotion | `deployBot_2e6910` |
| Conveyor Cloud Kubernetes | Hosts the cert-manager namespace; receives Certificate resources via kubectl | `conveyorCloudKubernetes_449f0f` |
| cert-manager | Issues the TLS certificate from the Groupon internal CA against the Certificate resource | `certManager_8a8826` |
| GCP IAM Service Accounts | Provides GCP authentication credentials (service account key) for the deploybot image | `gcpIamServiceAccounts_18e576` |
| GCP Secret Manager | Receives the provisioned TLS material as a versioned secret | `gcpSecretManager_cc4b72` |

## Steps

1. **Engineer submits PR**: Engineer creates a new JSON file at `requests/{org}/{service}.json` specifying `org`, `service`, `environments` (with `project_id` and `accessors`), and optional `seq` and `cntype` fields.
   - From: `Engineer`
   - To: `githubEnterprise`
   - Protocol: GitHub Pull Request (HTTPS)

2. **PR merged to main**: PR is reviewed and merged; GitHub generates a push event on the `main` branch.
   - From: `githubEnterprise`
   - To: `jenkins_a2feef`
   - Protocol: GitHub webhook

3. **Pipeline Init stage runs**: Jenkins evaluates the push event; runs `has-cert-requests.sh` against `git show --name-only -m HEAD` — detects the new file under `requests/`; sets `hasRequests=true`, `isTriggeredByPushEvent=true`.
   - From: `jenkins_a2feef`
   - To: `gcpTlsCertificateManagerPipeline`
   - Protocol: Jenkins pipeline execution

4. **Validate Deploy Config stage runs**: Jenkins calls `deploybotValidate()` to confirm `.deploy_bot.yml` is valid.
   - From: `gcpTlsCertificateManagerPipeline`
   - To: `jenkins_a2feef`
   - Protocol: Conveyor CI utility call

5. **DeployNewUpdated stage invokes DeployBot**: Jenkins calls `deploybotDeploy()` targeting `dev-gcp`; passes the git SHA and repository URL.
   - From: `gcpTlsCertificateManagerPipeline`
   - To: `deployBot_2e6910`
   - Protocol: Conveyor CI deploybotDeploy API

6. **DeployBot clones repository**: DeployBot clones the repo from GitHub Enterprise at the target SHA.
   - From: `deployBot_2e6910`
   - To: `githubEnterprise`
   - Protocol: git (SSH)

7. **DeployBot activates GCP credentials**: Deploybot image reads `tls-certificate-cicd-sa-key` from the Conveyor Cloud Kubernetes namespace and activates the GCP service account.
   - From: `deployBot_2e6910`
   - To: `gcpIamServiceAccounts_18e576`
   - Protocol: gcloud CLI / GCP IAM API

8. **DeployBot detects Add action**: Deploybot script reads git diff and identifies the new request file with action `A` (Added).
   - From: `deployBot_2e6910`
   - To: `deployBot_2e6910` (internal)
   - Protocol: git diff (local)

9. **DeployBot creates cert-manager Certificate resource**: Deploybot applies a Kubernetes Certificate resource in the `gcp-tls-certificate-manager-{env}` namespace with the CN set to `{env}/{service}` (or `{service}.{env}.service` for legacy).
   - From: `deployBot_2e6910`
   - To: `conveyorCloudKubernetes_449f0f`
   - Protocol: kubectl (Kubernetes API)

10. **cert-manager issues the TLS certificate**: cert-manager processes the Certificate resource, contacts the Groupon internal CA, and stores the resulting TLS material in a Kubernetes Secret within the namespace.
    - From: `certManager_8a8826`
    - To: `conveyorCloudKubernetes_449f0f`
    - Protocol: Kubernetes API (cert-manager.io/v1)

11. **DeployBot retrieves TLS material**: Deploybot reads the resulting Kubernetes Secret containing the certificate, private key, and appends the Groupon root CA to the certificate chain.
    - From: `deployBot_2e6910`
    - To: `conveyorCloudKubernetes_449f0f`
    - Protocol: kubectl (Kubernetes API)

12. **DeployBot creates GCP Secret Manager secret**: Deploybot runs `gcloud secrets create tls--{org}-{service}` in the target GCP project, then pushes the JSON payload (certificate, key, certificate_chain, environment) as version 1.
    - From: `deployBot_2e6910`
    - To: `gcpSecretManager_cc4b72`
    - Protocol: gcloud CLI (GCP Secret Manager API)

13. **DeployBot sets secret IAM bindings**: GCP secret accessors listed in the request file's `accessors` array are granted `roles/secretmanager.secretAccessor` on the new secret.
    - From: `deployBot_2e6910`
    - To: `gcpSecretManager_cc4b72`
    - Protocol: GCP IAM API

14. **Promotion to staging and production**: After successful dev deployment, the human approver promotes the deployment to `staging-gcp` and then (with manual approval and GPROD ticket) to `production-gcp`. Steps 6–13 repeat for each environment using the environment's `project_id` and `accessors`.
    - From: `deployBot_2e6910`
    - To: `conveyorCloudKubernetes_449f0f`, `gcpSecretManager_cc4b72`
    - Protocol: kubectl, gcloud CLI

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `tls-certificate-cicd-sa-key` Kubernetes secret not found | Deployment fails with `NotFound` error | Certificate not provisioned; operator must create the Kubernetes secret from the SA JSON key and retry |
| cert-manager `ServiceUnavailable` on patch | Kubernetes API transient error | Deployment fails; operator retries via DeployBot UI |
| Incorrect `project_id` in request file | GCP secret created in wrong project, or GCP API returns error | Secret not created in expected project; operator corrects `project_id` and re-merges a modification |
| Groupon root CA not appended to certificate chain | Chain missing root CA; downstream TLS validation fails | Certificate must be re-provisioned; debugging of deploybot image required |
| Complex git operations (rename, copy) not detected | `has-cert-requests.sh` uses simple `beginswith 'requests/'` filter; renames may not parse cleanly | Deployment skipped; operator should re-commit the change in a simpler form |

## Sequence Diagram

```
Engineer -> githubEnterprise: Create requests/{org}/{service}.json via PR and merge
githubEnterprise -> jenkins_a2feef: Push event webhook (main branch)
jenkins_a2feef -> gcpTlsCertificateManagerPipeline: Run Init stage; execute has-cert-requests.sh
gcpTlsCertificateManagerPipeline -> jenkins_a2feef: hasRequests=true; isTriggeredByPushEvent=true
jenkins_a2feef -> gcpTlsCertificateManagerPipeline: Run DeployNewUpdated stage
gcpTlsCertificateManagerPipeline -> deployBot_2e6910: deploybotDeploy(dev-gcp, SHA)
deployBot_2e6910 -> githubEnterprise: git clone at SHA
deployBot_2e6910 -> gcpIamServiceAccounts_18e576: Activate SA credentials (tls-certificate-cicd-sa-key)
deployBot_2e6910 -> conveyorCloudKubernetes_449f0f: kubectl apply Certificate resource (CN: {env}/{service})
conveyorCloudKubernetes_449f0f -> certManager_8a8826: Process Certificate CRD
certManager_8a8826 --> conveyorCloudKubernetes_449f0f: Store TLS material in Kubernetes Secret
deployBot_2e6910 -> conveyorCloudKubernetes_449f0f: kubectl get secret (retrieve TLS material)
deployBot_2e6910 -> gcpSecretManager_cc4b72: gcloud secrets create tls--{org}-{service}; add version
gcpSecretManager_cc4b72 --> deployBot_2e6910: Secret created [tls--{org}-{service}] version [1]
deployBot_2e6910 --> gcpTlsCertificateManagerPipeline: Deployment complete (dev)
Approver -> deployBot_2e6910: Promote to staging-gcp
Approver -> deployBot_2e6910: Promote to production-gcp (manual; GPROD ticket required)
```

## Related

- Architecture dynamic view: `dynamic-gcpTlsCertificateManager-newProvisioning`
- Related flows: [Certificate Update](certificate-update.md), [Certificate Deletion](certificate-deletion.md), [Monthly Certificate Refresh](monthly-certificate-refresh.md)
