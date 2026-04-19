---
service: "aws-service-catalog"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| AWS CloudFormation stack status (console / CLI) | manual | On demand | N/A |
| AWS Service Catalog portfolio status (console) | manual | On demand | N/A |

> No automated health endpoints are configured. Health is assessed by checking CloudFormation stack statuses in the AWS console.

## Monitoring

### Metrics

> No evidence found in codebase.

No application-level metrics are emitted. Operational visibility is provided through AWS CloudFormation stack events and AWS CloudTrail audit logs. The Terraform orchestration deploys Wavefront dashboards via `wavefrontDashboardsModule` for related infrastructure.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Wavefront operational dashboards | Wavefront | Deployed via `wavefrontDashboardsModule` in Terraform orchestration; link not defined in codebase |

### Alerts

> No evidence found in codebase.

No automated alerts are configured in this repository. Operational procedures to be defined by service owner.

## Common Operations

### Add a New Product Version to ConveyorCloud Portfolio

1. Update the product template file in `templates/products/ConveyorCloud/{product}/template.yaml`
2. Increment the version number in `templates/products/ConveyorCloud/{product}/VERSION`
3. Add a new `ProvisioningArtifactParameters` entry to `portfolios/ConveyorCloud/main.yaml` under the appropriate promotion condition (`OnlyInDev` for new versions)
4. Upload templates to S3: `cd templates/ && aws-okta exec servicecatalog-prod -- aws s3 sync . s3://grpn-prod-cloudcore-service-catalog/templates --region us-west-2`
5. Rename the uploaded template with the version suffix: `aws-okta exec servicecatalog-prod -- aws s3 mv s3://grpn-prod-cloudcore-service-catalog/templates/products/ConveyorCloud/{product}/template.yaml s3://grpn-prod-cloudcore-service-catalog/templates/products/ConveyorCloud/{product}/template-$(cat products/ConveyorCloud/{product}/VERSION).yaml --region us-west-2`
6. Deploy to dev portfolio: `cd portfolios/ConveyorCloud && aws-okta exec servicecatalog-prod -- aws cloudformation update-stack --stack-name ServiceCatalog-ConveyorCloud-dev --template-body file://main.yaml --parameters file://dev/parameters.json --region us-west-2`

### Promote a Product Version to Stable

1. Update the promotion condition for the target product version in `portfolios/ConveyorCloud/main.yaml` from `OnlyInDev` to `PromoteToStable`
2. Run `aws cloudformation update-stack --stack-name ServiceCatalog-ConveyorCloud-stable` for each region (`eu-west-1`, `us-west-1`, `us-west-2`) with the appropriate `parameters.json`

### Promote a Product Version to Production

1. Update the promotion condition for the target product version to `PromoteToAll`
2. Run `aws cloudformation update-stack --stack-name ServiceCatalog-ConveyorCloud-prod` for each region (`eu-west-1`, `us-west-1`, `us-west-2`) with the appropriate `parameters.json`

### Share Portfolio with a New Destination Account

1. Add a new `AWS::ServiceCatalog::PortfolioShare` resource in `portfolios/ConveyorCloud/main.yaml` with the target `AccountId` and the appropriate stage condition
2. Deploy the portfolio stack update to the hub account
3. In the destination account, deploy the share-accept stack: `aws cloudformation create-stack --stack-name ServiceCatalog-ConveyorCloud-{stage}-accept --template-body file://portfolios/ConveyorCloud/share-accept/main.yaml --parameters file://portfolios/ConveyorCloud/share-accept/{stage}/{region}/parameters.json --region {region}`

### Scale Up / Down

> Not applicable — AWS Service Catalog and CloudFormation are fully managed AWS services with no scaling configuration.

### Database Operations

> Not applicable — this service does not own any databases.

## Troubleshooting

### CloudFormation Stack Update Fails

- **Symptoms**: `aws cloudformation update-stack` returns an error or stack enters `UPDATE_ROLLBACK_COMPLETE` state
- **Cause**: Invalid CloudFormation template syntax, missing S3 template URL, or IAM permission issue
- **Resolution**: Review CloudFormation stack events in the AWS console for the specific error; verify the template URL is accessible in S3; check IAM role permissions for `servicecatalog-prod` profile

### Product Template Not Found at S3 URL

- **Symptoms**: Portfolio stack fails to create a new product version with `TemplateURL` error
- **Cause**: Template file was not uploaded to S3, or `aws s3 mv` was not run to rename with the version suffix
- **Resolution**: Re-run the S3 sync and `aws s3 mv` commands; verify the file exists at the expected key in `grpn-prod-cloudcore-service-catalog`

### Destination Account Cannot Access Shared Portfolio

- **Symptoms**: ConveyorCloud provisioner cannot see the portfolio in the destination account's Service Catalog console
- **Cause**: Share-accept stack not deployed, or `PortfolioPrincipalAssociation` not created for the `conveyor-provisioner` IAM user
- **Resolution**: Deploy or update the share-accept stack in the destination account; verify `AcceptPortfolio` and `AddPortfolioAccessConveyorProvisioner` resources are in `CREATE_COMPLETE` state

### cfn-guard Validation Failures

- **Symptoms**: Jenkins pipeline fails in the `cfn-validate` stage
- **Cause**: Product template violates compliance rules in `cfn-guard/rules/guard_rules.guard` (e.g., OpenSearch missing encryption, S3 public access enabled, Cassandra resources missing `Service`/`Owner` tags)
- **Resolution**: Update the offending template to satisfy the failing rule; common fixes include setting `EncryptionAtRestOptions.Enabled: true`, `BlockPublicAcls: true`, and ensuring `Tags` include `Service` and `Owner` keys

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | ConveyorCloud teams cannot provision any AWS resources (portfolio unavailable) | Immediate | Cloud Core on-call via Slack `#CF874A1HR` |
| P2 | Specific product type unavailable or broken in prod portfolio | 30 min | Cloud Core team (cloud-core@groupon.com) |
| P3 | Dev/stable portfolio issue; new version not promoted | Next business day | Cloud Core team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| AWS Service Catalog API | Check portfolio status in AWS console or via `aws servicecatalog list-portfolios` | No fallback; service unavailable until AWS resolves |
| Amazon S3 (`grpn-prod-cloudcore-service-catalog`) | `aws s3 ls s3://grpn-prod-cloudcore-service-catalog/templates/` | Existing products still usable; new template uploads blocked |
| AWS CloudFormation | Check `aws cloudformation describe-stacks` for stack status | Portfolio stacks remain at last deployed version |
