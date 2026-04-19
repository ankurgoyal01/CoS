---
service: "aws-landing-zone"
title: "Cloud Custodian Governance Remediation"
generated: "2026-03-03"
type: flow
flow_name: "custodian-governance-remediation"
flow_type: event-driven
trigger: "CloudTrail event (Lambda mode) or manual custodian run"
participants:
  - "continuumLandingZoneCloudCustodian"
  - "awsIamService"
architecture_ref: "dynamic-landing-zone-change-flow"
---

# Cloud Custodian Governance Remediation

## Summary

Cloud Custodian policies enforce continuous governance across all Landing Zone accounts. In Lambda mode, policies react to AWS CloudTrail events (e.g., resource creation) and automatically remediate non-compliant resources. One-time utility policies in `CloudCustodian/policies/OneTimeUtility/` are run manually to address bulk remediation scenarios. Supported remediations include IAM access key deactivation, S3 public access grant removal, and security group open-world ingress removal.

## Trigger

- **Type**: event (Lambda mode via CloudTrail) or manual
- **Source**: CloudTrail events in target AWS account (Lambda mode); engineer running `custodian run` or `RunCustodianPolicy.py` (manual mode)
- **Frequency**: Continuous (Lambda mode) or on-demand (manual)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cloud Custodian Policies | Evaluates policies, invokes remediations | `continuumLandingZoneCloudCustodian` |
| AWS IAM | Target of IAM key deactivation and drift remediation | `awsIamService` |
| AWS CloudTrail / CloudWatch | Source of events for Lambda-mode policies; `GRPNCloudTrailLogs` log group | — |
| AWS Lambda | Hosts Custodian Lambda functions (deployed from policy definitions) | — |
| AWS S3 | Target of public access grant removal | — |
| AWS EC2 Security Groups | Target of open-world ingress removal | — |

## Steps

### Lambda Mode (Continuous)

1. **CloudTrail records API event**: An AWS API call occurs in the target account (e.g., `RunInstances`, IAM mutation). CloudTrail records the event and writes it to the `GRPNCloudTrailLogs` CloudWatch log group.
   - From: AWS service API
   - To: AWS CloudTrail → `GRPNCloudTrailLogs`
   - Protocol: AWS-internal

2. **CloudWatch triggers Lambda**: A CloudWatch Event Rule (or EventBridge rule) configured by the Custodian policy invokes the Custodian Lambda function.
   - From: CloudWatch
   - To: AWS Lambda (Custodian function)
   - Protocol: AWS-internal

3. **Lambda evaluates policy filters**: The Custodian Lambda loads the policy definition, fetches the relevant resource (e.g., IAM user, S3 bucket, security group), and applies the filter conditions.
   - From: `continuumLandingZoneCloudCustodian` (`custodianPolicies` → `custodianExecutionRunner`)
   - To: `awsIamService` / AWS S3 / AWS EC2
   - Protocol: AWS SDK

4. **Lambda applies remediation action**: If the resource matches the filter, Custodian applies the configured action (deactivate key, remove public grant, remove ingress rule).
   - From: `continuumLandingZoneCloudCustodian`
   - To: `awsIamService` / AWS S3 / AWS EC2
   - Protocol: AWS SDK

5. **Lambda logs results**: Execution results are written to the CloudWatch log group defined in the policy's `execution-options.log_group` field (e.g., `/aws/lambda/custodian-auto-terminator`).
   - From: AWS Lambda
   - To: CloudWatch Logs
   - Protocol: AWS-internal

### Manual Mode (One-time Utility Policies)

1. **Engineer activates credentials**: Engineer runs `aws-okta exec {profile} -- aws sts get-caller-identity` to confirm active credentials for the target account.
   - From: Engineer
   - To: AWS STS
   - Protocol: AWS CLI / Okta SAML

2. **Engineer dry-runs policy**: `RunCustodianPolicy.py --profile {profile} --policypath OneTimeUtility --dry-run` runs `custodian run --dryrun` against all `.yaml` files in the policy path, writing results to `output/`.
   - From: `continuumLandingZoneCloudCustodian` (`custodianExecutionRunner`)
   - To: `awsIamService` / AWS S3 / AWS EC2
   - Protocol: Python / c7n / AWS SDK

3. **Engineer reviews dry-run output**: Reviews matched resources in `output/` directory before committing to live remediation.

4. **Engineer runs live policy**: `RunCustodianPolicy.py --profile {profile} --policypath OneTimeUtility` runs `custodian run` (without `--dryrun`) applying all policies.
   - From: `continuumLandingZoneCloudCustodian`
   - To: `awsIamService` / AWS S3 / AWS EC2
   - Protocol: Python / c7n / AWS SDK

## Active One-Time Utility Policies

| Policy Name | Resource | Filter | Action |
|-------------|----------|--------|--------|
| `unused-user-delete` | `iam-user` | Headless user with access key unused for >10 days | `remove-keys` (disable) |
| `s3-delete-global-grants` | `s3` | Buckets with global grants | `delete-global-grants` |
| `high-risk-security-groups-remediate` | `security-group` | Ingress rules open to `0.0.0.0/0` | `remove-permissions` (matched ingress) |
| `tag_super_user` | IAM user | Super user tagging | Tag resource |

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Custodian Lambda missing IAM permission | `AccessDenied` error logged in CloudWatch log group | Engineer identifies missing permission from CloudWatch event, updates `cloud_custodian` Terraform module, applies via pipeline |
| Stale Custodian cache during manual run | Incorrect resource list returned | Always pass `--cache-period=0` to `custodian run` |
| Policy renamed — old Lambda not removed | Old Lambda function continues to run | Manually delete old Lambda from AWS console in each affected account |
| Dry-run shows unexpected matches | More resources would be affected than intended | Refine policy filters; re-run dry-run before going live |

## Sequence Diagram

```
AWS CloudTrail -> GRPNCloudTrailLogs (CloudWatch): Record API event
CloudWatch -> AWS Lambda (Custodian): Invoke policy Lambda
Cloud Custodian Policies -> AWS IAM / S3 / EC2: Fetch resource, apply filters
Cloud Custodian Policies -> AWS IAM / S3 / EC2: Apply remediation action
AWS Lambda -> CloudWatch Logs: Write execution results
```

## Related

- Architecture dynamic view: `dynamic-landing-zone-change-flow`
- Related flows: [IAM Role Provisioning](iam-role-provisioning.md), [Landing Zone Change Deployment](landing-zone-change-deployment.md)
