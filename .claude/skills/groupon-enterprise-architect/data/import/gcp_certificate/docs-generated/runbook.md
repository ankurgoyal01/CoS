---
service: "gcp_certificate"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

> No evidence found in codebase. This is an IaC-only service with no runtime health endpoint. CA health is assessed via GCP Console or by running a Terraform plan to detect drift.

| Mechanism | Type | Interval | Timeout |
|-----------|------|----------|---------|
| Terraform plan (`make <env>/plan`) | exec | On demand | Terraform timeout |
| GCP Console — CA pool status | manual | On demand | n/a |

## Monitoring

### Metrics

> No evidence found in codebase. This service does not emit application metrics. GCP Private CA metrics (certificate issuance rates, errors) are available in GCP Cloud Monitoring under the `privateca.googleapis.com` namespace.

### Dashboards

> No evidence found in codebase. Operational procedures to be defined by service owner.

### Alerts

> No evidence found in codebase. Operational procedures to be defined by service owner.

## Common Operations

### Apply Infrastructure Changes

1. Clone or update the repository to the desired state.
2. Set required environment variables: `TF_VAR_GCP_PROJECT_NUMBER`, `TF_VAR_GCP_PROJECT_ID`, `TF_VAR_GCP_ENV_STAGE`, `TF_VAR_PROJECTNAME`.
3. Authenticate with GCP (ensure credentials allow impersonation of `grpn-sa-terraform-security`).
4. Run `make grp-security-prod/plan` from within the `envs/` directory to review changes.
5. Run `make grp-security-prod/APPLY` to apply.

### Add a New Certificate to an Existing Template

1. Edit the appropriate `account.hcl` file (`envs/grp-security-dev/account.hcl` or `envs/grp-security-prod/account.hcl`).
2. Add an entry to the correct certificate type list (`mTLS`, `client_auth`, `server_auth`, or `custom`) with `service`, `common_name`, `requesters`, and `SANs` as required.
3. Ensure the common name and SANs match the `valid_domain_suffixes` for the target environment.
4. Submit a pull request for review by `infosec@groupon.com`.
5. After merge, apply via `make grp-security-prod/APPLY` targeting the `certificates` module.

### Add a New Custom Certificate Template

1. Add a new entry in the `custom` list of the target `account.hcl` with a unique `template_name`, `requesters`, `identity_contraints` (CEL expression), `maximum_lifetime`, `ca_options`, `base_key_usage`, `extended_key_usage`, and optionally `name_constraints` (list of allowed domain suffixes).
2. The `custom` module will invoke `name_constraints.py` to compute the ASN.1 DER encoding for x509v3 OID `2.5.29.30` if `name_constraints` is non-empty.
3. Apply as above.

### Activate a New Subordinate CA from Scratch

1. Apply Terraform to create the CA resource (it will fail to activate automatically).
2. In the GCP Console, navigate to the new CA and download the Certificate Signing Request (CSR).
3. Use the Groupon Root CA to issue a certificate from the CSR.
4. Upload the signed certificate in GCP Console to activate the CA.

### Retrieve a Certificate (fetch_cert / issue_cert)

Both scripts (`scripts/fetch_cert`, `scripts/issue_cert`) share the same logic:

1. Pass `--cert_role <IAM_ROLE_ARN>` and optionally `--cert_path <DIR>` (default `/var/certs`).
2. Script assumes the IAM role via `aws sts assume-role`.
3. Reads the `CertARN` tag from the IAM role.
4. Exports the certificate from AWS ACM using the ARN.
5. Decrypts the private key with `openssl rsa`.
6. Rotates files: writes `cert-bundle.pem` and `privkey.pem`; backs up previous as `cert_old.pem` and `privkey_old.pem`.

### Scale Up / Down

> Not applicable — GCP Private CA scales automatically. No manual scaling steps are required.

### Database Operations

> Not applicable — no application database exists. For Terraform state issues, use `terragrunt state` commands within the appropriate module directory.

## Troubleshooting

### Terraform Apply Fails with "failed to parse CA name"

- **Symptoms**: `Error activating subordinate CA with first party issuer: failed to parse CA name: , parts: []`
- **Cause**: This is expected on initial CA creation when using a PEM issuer chain. The CA is created but not yet active.
- **Resolution**: Follow the manual activation steps in "Activate a New Subordinate CA from Scratch" above. Download the CSR from GCP Console, issue the certificate using the Root CA, and upload it.

### IAM Policy Apply Fails — Permission Denied

- **Symptoms**: Terraform errors during `google_privateca_ca_pool_iam_policy` or `google_privateca_certificate_template_iam_policy` apply
- **Cause**: The Terraform service account does not have `resourcemanager.projects.setIamPolicy` or `privateca.caPool.setIamPolicy`
- **Resolution**: Verify that `grpn-sa-terraform-security` has the required IAM role in the target GCP project. Contact the CloudCore team if SA permissions need adjustment.

### Certificate Requester Gets Permission Denied on Issuance

- **Symptoms**: A service team cannot request a certificate via the GCP API; receives `PERMISSION_DENIED`
- **Cause**: The requester's Google Group is not in the `requesters` list for the correct template, or the requested common name does not match the IAM condition expression
- **Resolution**: Verify the service entry in `account.hcl`. Confirm the `common_name` in the request exactly matches the `common_name` field. Confirm the requester's group identity matches. Apply updated configuration.

### SAN Not Allowed by Issuance Policy

- **Symptoms**: Certificate issuance fails with a policy violation — SAN does not match allowed domain suffixes
- **Cause**: The requested SAN does not end with one of the `valid_domain_suffixes` defined in `account.hcl`
- **Resolution**: Add the domain suffix to `valid_domain_suffixes` in the target environment's `account.hcl` (requires infosec review) and re-apply.

### fetch_cert Fails with "cert_role is unknown"

- **Symptoms**: `scripts/fetch_cert` prints "Exit when cert_role is unknown" and exits 0
- **Cause**: The caller passed `--cert_role unknown` (sentinel value used when no cert role is needed)
- **Resolution**: This is expected behavior. If a certificate is actually needed, provide the correct IAM role ARN.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | CA pool unavailable — no new certificates can be issued; existing certificates remain valid | Immediate | infosec@groupon.com |
| P2 | Specific template misconfigured — one or more services cannot renew certificates | 30 min | infosec@groupon.com |
| P3 | Terraform state drift detected; no immediate service impact | Next business day | infosec@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| GCP Private CA API (`privateca.googleapis.com`) | GCP Console — CA pool and CA status; or run `terraform plan` | Existing issued certificates remain valid until expiry (up to 400 days for leaf certs) |
| GCS (Terraform state) | `terragrunt state list` in any module directory | Manual state recovery via `terraform state` commands |
| AWS STS + ACM (fetch_cert/issue_cert) | Run script manually with known-good role ARN | Use existing certificate files if not yet expired |
