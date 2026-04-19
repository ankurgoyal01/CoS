---
service: "gcp-dataplex-infra"
title: "GCP Authentication and Service Account Impersonation"
generated: "2026-03-03"
type: flow
flow_name: "gcp-auth-and-sa-impersonation"
flow_type: synchronous
trigger: "Operator initiates any Terraform plan or apply make target"
participants:
  - "operator"
  - "gcloud-cli"
  - "gcp-iam-api"
  - "terraform-google-provider"
architecture_ref: "gcp-dataplex-infra-containers"
---

# GCP Authentication and Service Account Impersonation

## Summary

Before any Terraform operation can modify GCP resources, the operator must authenticate with GCP and the Terraform Google provider must obtain a scoped, short-lived access token by impersonating the designated Terraform service account. This flow ensures that all infrastructure changes are applied under the `grpn-sa-terraform-data-catalog` service account rather than the operator's personal credentials, enforcing least-privilege and auditability in GCP.

## Trigger

- **Type**: manual
- **Source**: Operator runs `make stable/gcp-login` or any `make stable/*/plan` or `make stable/*/APPLY` target
- **Frequency**: Per session (ADC credentials are valid until revoked; impersonation token has a 3600s lifetime)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator | Initiates authentication; holds personal GCP identity | — |
| gcloud CLI | Performs Application Default Credentials login and sets active GCP project | — |
| GCP IAM API | Issues impersonation access token for the Terraform service account | — |
| Terraform Google provider (impersonate alias) | Requests the impersonation token using ADC; passes token to the main provider | — |

## Steps

1. **Run GCP login**: Operator runs `make stable/gcp-login` which calls `gcloud auth application-default login && gcloud config set project prj-grp-data-cat-stable-0b72`
   - From: `operator`
   - To: gcloud CLI
   - Protocol: local shell

2. **Browser OAuth2 flow**: gcloud CLI opens a browser for the operator to sign in with their GCP identity; ADC credentials are saved to the local credential file
   - From: gcloud CLI
   - To: GCP OAuth2 endpoint
   - Protocol: HTTPS (OAuth2)

3. **Terraform initialises impersonation provider**: When Terraform runs, the `google` provider aliased as `impersonate` is initialised using ADC and the two OAuth2 scopes (`cloud-platform`, `userinfo.email`)
   - From: Terraform Google provider
   - To: GCP IAM API
   - Protocol: HTTPS

4. **Request impersonation token**: Terraform calls `google_service_account_access_token` data source, requesting a token for `grpn-sa-terraform-data-catalog@prj-grp-central-sa-stable-66eb.iam.gserviceaccount.com` with scopes `userinfo-email` and `cloud-platform`; lifetime is set to `3600s`
   - From: Terraform Google provider (impersonate alias)
   - To: GCP IAM API (`iamcredentials.googleapis.com`)
   - Protocol: HTTPS

5. **Receive access token**: GCP IAM issues a short-lived OAuth2 access token scoped to the Terraform SA
   - From: GCP IAM API
   - To: Terraform Google provider
   - Protocol: HTTPS (JSON response)

6. **Configure main providers with token**: Both the `google` and `google-beta` Terraform providers are configured with `access_token` set to the impersonated token; all subsequent GCP API calls use this token
   - From: Terraform CLI (internal provider configuration)
   - To: Google Cloud Dataplex API / GCS API
   - Protocol: HTTPS (Bearer token in Authorization header)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| ADC credentials missing or expired | Terraform fails to initialise the impersonate provider | Operator re-runs `make stable/gcp-login` |
| Operator lacks `roles/iam.serviceAccountTokenCreator` on the Terraform SA | GCP IAM returns 403 on token request | Operator requests IAM role assignment from GCP admin |
| Impersonation token expires mid-apply (>3600s apply) | Terraform API calls begin failing with 401 | Operator re-authenticates and re-applies; partial state is preserved in GCS backend |
| Wrong GCP project set | Resources created in incorrect project | Operator verifies `gcloud config get project` before running apply |

## Sequence Diagram

```
Operator -> gcloud CLI: gcloud auth application-default login
gcloud CLI -> GCP OAuth2: browser-based authentication
GCP OAuth2 --> gcloud CLI: ADC credentials saved locally
gcloud CLI -> GCP: gcloud config set project prj-grp-data-cat-stable-0b72
Operator -> Make: make stable/us-central1/plan or APPLY
Make -> Terraform: invoke via Terragrunt
Terraform -> GCP IAM API: request impersonation token (grpn-sa-terraform-data-catalog, 3600s)
GCP IAM API --> Terraform: access_token
Terraform -> GCP Dataplex API: API calls with Bearer access_token
Terraform -> GCP Storage API: API calls with Bearer access_token
```

## Related

- Architecture dynamic view: `gcp-dataplex-infra-containers`
- Related flows: [Terraform Infrastructure Provisioning](terraform-infrastructure-provisioning.md), [Terraform Plan and Compliance Review](terraform-plan-and-compliance-review.md)
