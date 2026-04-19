---
service: "gcp_certificate"
title: "Certificate Issuance"
generated: "2026-03-03"
type: flow
flow_name: "certificate-issuance"
flow_type: synchronous
trigger: "Authorized service team calls GCP Private CA API to request a leaf certificate"
participants:
  - "continuumPrivateCaModule"
  - "continuumCertificatesModule"
architecture_ref: "containers-gcp-certificate"
---

# Certificate Issuance

## Summary

This flow describes how an authorized internal service team obtains a leaf certificate from Groupon's GCP Private CA. After the `gcp_certificate` infrastructure has been provisioned (CA pool, intermediate CA, and templates), service teams can self-serve certificate issuance without infosec involvement. The requester's Google Group identity is validated against the IAM condition on the CA pool, which enforces the certificate template used, the allowed common name, and allowed SANs.

## Trigger

- **Type**: api-call
- **Source**: Authorized service team member or automated CI/CD pipeline using GCP credentials with `roles/privateca.certificateRequester` on the CA pool
- **Frequency**: On demand — typically once per certificate lifecycle (up to 400-day validity for leaf certs via standard templates; up to 15 years for the `conveyor_subordinate_cert_authority` custom template)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Service team (requester) | Calls GCP Private CA API to issue a certificate using their approved template | n/a |
| GCP Private CA API (`privateca.googleapis.com`) | Validates IAM permissions, enforces issuance policy, issues the signed certificate | external — `continuumPrivateCaModule` |
| Groupon GCP Intermediate CA | Signs the certificate request | `continuumPrivateCaModule` |
| GCP IAM API | Evaluates `roles/privateca.certificateRequester` binding and IAM condition expression | external |

## Steps

1. **Generate CSR or config**: The requester generates a Certificate Signing Request (CSR) locally (CSR-based issuance) or prepares a certificate config (config-based issuance). Both modes are allowed by the CA pool's `allowed_issuance_modes`.
   - From: Requester / service
   - To: local key generation (e.g., `openssl`, GCP client library)
   - Protocol: local

2. **Submit certificate request**: The requester calls the GCP Private CA API (`projects.locations.caPools.certificates.create`) specifying the CA pool, the certificate template resource name (e.g., `projects/prj-grp-security-prod-1403/locations/us-central1/certificateTemplates/client_auth_template`), the common name, and SANs.
   - From: Requester
   - To: GCP Private CA API (`privateca.googleapis.com`)
   - Protocol: GCP SDK / REST

3. **IAM condition evaluation**: GCP IAM validates that the requester's identity holds `roles/privateca.certificateRequester` on the CA pool AND that the IAM condition expression matches: template name equals the specified template, common name equals the approved CN, and SANs match the approved list.
   - From: GCP Private CA API
   - To: GCP IAM API
   - Protocol: internal GCP

4. **Issuance policy validation**: The CA pool's issuance policy CEL expression validates that all SANs are of type `DNS` and end with one of the Groupon-approved domain suffixes (e.g., `.groupondev.com`, `.production.service`).
   - From: GCP Private CA API
   - To: CA pool issuance policy engine
   - Protocol: internal GCP

5. **Sign and issue certificate**: The Groupon GCP Intermediate CA signs the certificate request using RSA_PKCS1_4096_SHA256 (CA key) and returns the signed leaf certificate.
   - From: Groupon GCP Intermediate CA
   - To: GCP Private CA API
   - Protocol: internal GCP

6. **Return certificate to requester**: GCP Private CA API returns the signed certificate PEM and the certificate chain (intermediate CA cert) to the requester.
   - From: GCP Private CA API
   - To: Requester
   - Protocol: GCP SDK / REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| IAM condition not satisfied (wrong template, CN, or SANs) | GCP IAM denies the request with `PERMISSION_DENIED` | Certificate not issued; requester must fix request or contact infosec to update policy |
| SAN fails domain suffix policy | GCP Private CA API rejects with policy violation error | Certificate not issued; SAN must end with approved suffix |
| Requester's Google Group lacks the IAM binding | GCP IAM denies with `PERMISSION_DENIED` | Infosec must add the group to the correct `requesters` entry in `account.hcl` and re-apply |
| CA is not yet activated | GCP Private CA API returns error — CA in pending state | Infosec must complete the manual CA activation flow |
| Certificate lifetime exceeds template maximum | GCP Private CA API clamps to template maximum (e.g., 400 days for standard templates) | Certificate issued with clamped lifetime |

## Sequence Diagram

```
Requester -> GCP Private CA API: certificates.create (CA pool, template=client_auth_template, CN=production/encore-service, SANs=[])
GCP Private CA API -> GCP IAM API: evaluate certificateRequester binding + condition
GCP IAM API --> GCP Private CA API: authorized
GCP Private CA API -> CA Pool Issuance Policy: validate SANs against domain suffix CEL
CA Pool Issuance Policy --> GCP Private CA API: policy satisfied
GCP Private CA API -> Groupon GCP Intermediate CA: sign certificate
Groupon GCP Intermediate CA --> GCP Private CA API: signed leaf certificate
GCP Private CA API --> Requester: certificate PEM + chain PEM
```

## Related

- Architecture dynamic view: `containers-gcp-certificate`
- Related flows: [Private CA Provisioning](private-ca-provisioning.md), [Certificate Template Registration](certificate-template-registration.md)
