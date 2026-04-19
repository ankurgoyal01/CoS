---
service: "gcp_certificate"
title: "Certificate Retrieval via AWS ACM"
generated: "2026-03-03"
type: flow
flow_name: "certificate-retrieval-aws-acm"
flow_type: synchronous
trigger: "Manual execution of scripts/fetch_cert or scripts/issue_cert by a service operator"
participants: []
architecture_ref: "containers-gcp-certificate"
---

# Certificate Retrieval via AWS ACM

## Summary

The `scripts/fetch_cert` and `scripts/issue_cert` scripts provide a way for service operators to retrieve an existing certificate and its private key from AWS Certificate Manager (ACM) and write them to the local filesystem. The scripts assume an AWS IAM role (identified by the `--cert_role` argument), read the `CertARN` tag from that role, export the certificate from ACM with a one-time passphrase, decrypt the private key with `openssl`, and rotate the on-disk certificate files atomically. This is used for services that store certificates in AWS ACM for use in non-GCP contexts.

## Trigger

- **Type**: manual
- **Source**: Service operator or deployment automation invokes `scripts/fetch_cert --cert_role <IAM_ROLE_ARN>`
- **Frequency**: On demand — typically during certificate rotation or initial service deployment

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator / deployment automation | Invokes the script with the cert role ARN | n/a |
| AWS STS | Validates and issues temporary credentials for the cert role | external |
| AWS IAM (list-role-tags) | Provides the `CertARN` tag from the role | external |
| AWS ACM | Exports the certificate, chain, and encrypted private key | external |
| `openssl` (local) | Decrypts the private key using the one-time passphrase | local |

## Steps

1. **Parse arguments**: Script reads `--cert_role <ARN>` and optionally `--cert_path <DIR>` (default `/var/certs`). Exits if `cert_role` is empty. Exits cleanly (exit 0) if `cert_role` is the sentinel value `unknown`.
   - From: Operator
   - To: `scripts/fetch_cert`
   - Protocol: bash argument

2. **Generate one-time passphrase**: Script generates a 20-byte random hex passphrase via `openssl rand -hex 20`.
   - From: `scripts/fetch_cert`
   - To: local `openssl`
   - Protocol: shell

3. **Assume IAM role**: Script calls `aws sts assume-role --role-arn $CERT_ROLE --role-session-name security_cert_session` to obtain temporary AWS credentials (`AccessKeyId`, `SecretAccessKey`, `SessionToken`).
   - From: `scripts/fetch_cert`
   - To: AWS STS
   - Protocol: AWS CLI / REST

4. **Retrieve CertARN tag**: Using the temporary credentials, script calls `aws iam list-role-tags --role-name <ROLE_NAME>` and extracts the value of the `CertARN` tag, which contains the ACM certificate ARN.
   - From: `scripts/fetch_cert`
   - To: AWS IAM
   - Protocol: AWS CLI / REST

5. **Export certificate from ACM**: Script calls `aws acm export-certificate --certificate-arn $CERT_ARN --passphrase $PASSPHRASE --region $REGION` to retrieve the certificate PEM, certificate chain PEM, and passphrase-encrypted private key PEM.
   - From: `scripts/fetch_cert`
   - To: AWS ACM
   - Protocol: AWS CLI / REST

6. **Write new certificate files**: Script writes the certificate + chain to `cert_new.pem` and the encrypted private key to `privkey_new.pem` in the cert path directory.
   - From: `scripts/fetch_cert`
   - To: local filesystem
   - Protocol: file I/O

7. **Decrypt private key**: Script calls `openssl rsa -in $NEW_KEY -out $NEW_KEY -passin pass:$PASSPHRASE` to decrypt the private key in place.
   - From: `scripts/fetch_cert`
   - To: local `openssl`
   - Protocol: shell

8. **Rotate certificate files atomically**: If existing `cert-bundle.pem` and `privkey.pem` exist, they are moved to `cert_old.pem` and `privkey_old.pem` (644/600 permissions). New files are moved to `cert-bundle.pem` (644) and `privkey.pem` (600).
   - From: `scripts/fetch_cert`
   - To: local filesystem
   - Protocol: file I/O

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `cert_role` not provided | Script prints error and exits 1 | No files written |
| `cert_role` is `unknown` | Script prints message and exits 0 (intentional sentinel) | No files written; caller treats as success |
| AWS STS assume-role fails | `set -e` causes script to abort | No certificate files written; existing files unchanged |
| `CertARN` tag not present on IAM role | `jq` returns empty string; `aws acm export-certificate` fails with invalid ARN | Script aborts; existing files unchanged |
| ACM export fails | `set -e` causes script to abort | No new certificate files written |
| `openssl` decryption fails | `set -e` causes script to abort | Encrypted private key remains on disk; caller must re-run |

## Sequence Diagram

```
Operator -> scripts/fetch_cert: --cert_role arn:aws:iam::<acct>:role/<cert-role>
scripts/fetch_cert -> openssl: rand -hex 20
openssl --> scripts/fetch_cert: PASSPHRASE
scripts/fetch_cert -> AWS STS: assume-role (security_cert_session)
AWS STS --> scripts/fetch_cert: AccessKeyId, SecretAccessKey, SessionToken
scripts/fetch_cert -> AWS IAM: list-role-tags (ROLE_NAME)
AWS IAM --> scripts/fetch_cert: Tags[CertARN=<acm-arn>]
scripts/fetch_cert -> AWS ACM: export-certificate (CertARN, PASSPHRASE, REGION)
AWS ACM --> scripts/fetch_cert: Certificate PEM + CertificateChain PEM + PrivateKey PEM (encrypted)
scripts/fetch_cert -> filesystem: write cert_new.pem, privkey_new.pem
scripts/fetch_cert -> openssl: rsa -in privkey_new.pem (decrypt with PASSPHRASE)
openssl --> scripts/fetch_cert: decrypted privkey_new.pem
scripts/fetch_cert -> filesystem: rotate cert-bundle.pem (644) + privkey.pem (600)
scripts/fetch_cert --> Operator: exit 0
```

## Related

- Architecture dynamic view: `containers-gcp-certificate`
- Related flows: [Certificate Issuance](certificate-issuance.md)
