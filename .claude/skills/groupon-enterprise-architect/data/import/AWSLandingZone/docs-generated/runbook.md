---
service: "aws-landing-zone"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Jenkins pipeline build status | Jenkins UI | On-demand / per PR | — |
| Wavefront dashboard: cloud-sre | Dashboard | Real-time | — |
| Wavefront dashboard: aws-landing-zone-vpc | Dashboard | Real-time | — |
| PagerDuty service `P5BVIK5` | Alert | On-call rotation | — |

> No HTTP health endpoint is exposed — this is an infrastructure delivery system, not a runtime service.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Terraform apply status | gauge | Success/failure of apply per environment | Failure triggers Slack alert |
| VPC configuration drift | gauge | Monitored via Wavefront `aws-landing-zone-vpc` dashboard | Operational procedures to be defined by service owner |
| IAM policy drift | event | Cloud Custodian scan results per account | Remediation applied automatically |
| CloudTrail log ingestion | gauge | Log events flowing into `GRPNCloudTrailLogs` log group | Operational procedures to be defined by service owner |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Cloud SRE | Wavefront | https://groupon.wavefront.com/dashboard/cloud-sre |
| AWS Landing Zone VPC | Wavefront | https://groupon.wavefront.com/dashboards/aws-landing-zone-vpc |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Terraform apply failure | One or more `apply` stages fail in Jenkins | critical | Check Slack `#cloudcoreteam-notify`; review Jenkins build log; check for state lock; run `unlock` action if needed |
| PagerDuty on-call | Service degradation per PagerDuty `P5BVIK5` | critical | Contact `cloud-core@groupon.pagerduty.com` |

## Common Operations

### Apply Infrastructure Changes

1. Open a PR in the `AWSLandingZone` GitHub repo with the desired Terraform, CloudFormation, or Custodian changes
2. Run `make pre-commit` locally to validate formatting
3. Await Cloud Core review and approval (2 business day SLA)
4. On merge to master, Jenkins automatically applies changes to sandbox/dev environments (`autoApply: true`)
5. For stable and production environments, trigger the Jenkins pipeline manually — select the target environment(s) and set action to `APPLY`
6. Monitor build progress in Jenkins and Slack `#cloudcoreteam-notify`

### Unlock a Stuck Terraform State

1. Open Jenkins pipeline for the target environment
2. Select the affected environment checkbox
3. Set action to `unlock`
4. Run the pipeline

### Deploy CloudFormation Baseline Changes

1. Ensure changes are committed to `CloudFormationBaseline/Accounts/`
2. Jenkins pipeline runs `cfn-lint` format-check automatically on every PR
3. For deployment, run `python CloudFormationDeploy.py --path ./output_dir/ -v` against the target environment
4. Templates are packaged to S3 bucket `grpn-stackset-admin` then deployed via CloudFormation StackSets

### Run a Cloud Custodian Policy

1. Activate AWS credentials via `aws-okta exec {profile}`
2. Test with dry-run: `custodian run --cache-period=0 --dryrun --region=us-west-2 -s output policies/{policy}.yaml`
3. Review output in `./output/` directory
4. Run live: `custodian run --cache-period=0 -s output policies/{policy}.yaml`
5. Always pass `--cache-period=0` to avoid stale 15-minute cache confusion

### Audit IAM Users Across Accounts

1. Prepare an AWS config file with profiles for target accounts (e.g., `landing-zone.config`)
2. Run: `python bin/audit-users/main.py --config landing-zone.config`
3. Review output: group assignments and access key ages are printed as Markdown tables

### Audit IAM Roles

1. Run: `python bin/audit-roles/audit-roles.py`
2. Optionally provide a list of specific roles to check via `optional_list_of_roles_to_check/`

## Troubleshooting

### Terraform State Lock

- **Symptoms**: Pipeline fails with "Error acquiring the state lock" or "Lock Info" message
- **Cause**: A previous apply was interrupted, leaving a DynamoDB lock in place
- **Resolution**: Run the Jenkins pipeline with action `unlock` for the affected environment; or manually delete the DynamoDB lock record in the state table

### cfn-lint Failures in PR

- **Symptoms**: Pipeline stage "CloudFormationBaseline format-check" fails
- **Cause**: CloudFormation YAML template has lint errors
- **Resolution**: Run `cfn-lint ./CloudFormationBaseline/**/*.yaml` locally, fix reported issues, push updated commit

### Cloud Custodian Policy Name Rename

- **Symptoms**: Old Lambda function left running after policy rename
- **Cause**: Cloud Custodian does not remove Lambda functions it creates when a policy is renamed
- **Resolution**: Manually delete the old Lambda function from the AWS console in each affected account

### Cloud Custodian Stale Cache

- **Symptoms**: Policy scan results appear incorrect or stale
- **Cause**: Cloud Custodian caches environment state for 15 minutes by default
- **Resolution**: Always pass `--cache-period=0` to `custodian run`

### IAM Permission Denied for Custodian Lambda

- **Symptoms**: Lambda errors in `GRPNCloudTrailLogs` CloudWatch log group with `AccessDenied` events for `userIdentity.arn = "*custodian*"`
- **Cause**: The Custodian Lambda role is missing a required IAM permission
- **Resolution**: Find the failing `eventName` and `eventSource` in CloudWatch; add the permission to the relevant `cloud_custodian` Terraform module; apply changes via pipeline

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | VPC or IAM outage blocking all deployments | Immediate | Cloud Core (`cloud-core@groupon.pagerduty.com`), PagerDuty `P5BVIK5` |
| P2 | Infrastructure drift detected, degraded account access | 30 min | Cloud Core team; Slack `#cloud-support` |
| P3 | Minor configuration issue, single environment apply failure | Next business day | Jira CLOUDCORE project |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| AWS Organizations / IAM | `aws sts get-caller-identity` with `grpn-all-landingzone-tf-admin` role | Manual console access as last resort |
| Jenkins controller | Jenkins UI status page | Contact Cloud Core for pipeline re-run |
| Docker registry (`docker.groupondev.com`) | `docker pull` in pipeline stage | Use cached image from Jenkins agent if available |
| GitHub Enterprise | Pipeline trigger via webhook | Manual Jenkins dispatch from UI |
