---
service: "aws-landing-zone"
title: "Infrastructure Audit"
generated: "2026-03-03"
type: flow
flow_name: "infrastructure-audit"
flow_type: batch
trigger: "Manual invocation by Cloud Core engineer"
participants:
  - "continuumLandingZoneTerraform"
  - "awsIamService"
architecture_ref: "dynamic-landing-zone-change-flow"
---

# Infrastructure Audit

## Summary

The Landing Zone provides a suite of Python audit scripts in the `bin/` directory that allow Cloud Core engineers to inspect the current state of IAM users, roles, AMI sharing, and account authorization across all Landing Zone accounts. These scripts are run manually using AWS credentials obtained via `aws-okta`, producing Markdown-formatted reports for review. They do not make any changes to AWS resources.

## Trigger

- **Type**: manual
- **Source**: Cloud Core engineer invokes audit script from their local machine
- **Frequency**: On-demand (periodic security reviews, incident investigation, compliance audits)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cloud Core Engineer | Initiates audit, reviews output | — |
| Landing Zone Terraform | Provides `account.hcl` files used by account-finder to enumerate authorized accounts | `continuumLandingZoneTerraform` |
| AWS IAM | Source of user, role, key, and group data | `awsIamService` |

## Steps

### IAM User Audit (`bin/audit-users/`)

1. **Prepare AWS config**: Engineer ensures `~/.aws/{config-file}` contains profiles for all target accounts (one profile per account).

2. **Run audit**: `python bin/audit-users/main.py --config landing-zone.config` spawns parallel processes (one per account profile).

3. **Obtain credentials per account**: For each account, `aws-okta exec {profile}` is called to retrieve `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_SESSION_TOKEN`.
   - From: `terraformAutomationScripts` (`bin/audit-users/main.py`)
   - To: `awsIamService`
   - Protocol: AWS CLI / Okta SAML / STS

4. **List users and access keys**: For each account, `iam.list_users()` retrieves all IAM users; `iam.list_access_keys(UserName=u)` retrieves access key metadata per user.
   - From: `bin/audit-users/main.py`
   - To: `awsIamService`
   - Protocol: AWS SDK (boto3)

5. **Retrieve group assignments and key usage**: `iam.list_groups_for_user()` retrieves group memberships; `iam.get_access_key_last_used()` retrieves last-used date for each access key.
   - From: `bin/audit-users/main.py`
   - To: `awsIamService`
   - Protocol: AWS SDK (boto3)

6. **Output Markdown report**: Results printed as Markdown tables — Group Assignment section and User Key Data section (user, access key ID, last used date, user creation date).

### IAM Role Audit (`bin/audit-roles/`)

1. **Run audit**: `python bin/audit-roles/run.py`
2. **Optionally filter roles**: Place role names in `optional_list_of_roles_to_check/` to scope the audit
3. **Scan accounts**: `audit-roles.py` queries each account for role existence and permission assignments
4. **Review output**: Results show which roles exist in which accounts

### Shared AMI Audit (`bin/audit-shared-amis/`)

1. **Run audit**: `python bin/audit-shared-amis/run.py`
2. **Query AMI share lists**: `audit-shared-amis.py` retrieves all AMIs shared with Groupon accounts
3. **Compare against authorized accounts**: Account IDs in share lists are compared against Landing Zone authorized account IDs

### Account Finder (`bin/account-finder/`)

1. **Prepare input file**: Create a text file with one AWS account ID per line (e.g., from an AMI share list)
2. **Run**: `python bin/account-finder/account-finder.py path/to/account_ids.txt`
3. **Build authorized account list**: Script walks `terraform/envs/` and extracts account IDs from `account.hcl` files
4. **Compare and report**: Prints any account IDs in the input file that are NOT in the authorized Landing Zone account list; exits non-zero if unauthorized accounts are found

### Permission Deployment Check (`bin/check-if-permission-deployed-to-role/`)

1. **Run**: `python bin/check-if-permission-deployed-to-role/run.py`
2. **Verifies**: Whether a specific permission has been deployed to a specific role across accounts

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `aws-okta` credential failure for an account | `loguru` logs error with account name; process continues for other accounts | Partial report; engineer re-runs for failed account with fresh credentials |
| Account profile not in `~/.aws/config` | Profile skipped silently | Engineer adds missing profile to config file |
| IAM API rate limiting | boto3 retries with backoff | Slower execution; report eventually completes |

## Sequence Diagram

```
Engineer -> bin/audit-users/main.py: Run with --config landing-zone.config
main.py -> aws-okta: Exec profile to obtain credentials (per account, parallel)
aws-okta -> AWS STS: AssumeRole / SAML auth
main.py -> AWS IAM: list_users, list_access_keys, list_groups_for_user, get_access_key_last_used
AWS IAM --> main.py: User and key data
main.py --> Engineer: Markdown report (Group Assignments + User Key Data)
```

## Related

- Architecture dynamic view: `dynamic-landing-zone-change-flow`
- Related flows: [IAM Role Provisioning](iam-role-provisioning.md), [Cloud Custodian Governance Remediation](custodian-governance-remediation.md)
