---
service: "aws-service-catalog"
title: "Product Template Authoring and Upload"
generated: "2026-03-03"
type: flow
flow_name: "product-template-authoring"
flow_type: batch
trigger: "Manual — Cloud Core engineer creates or updates a product CloudFormation template"
participants:
  - "productTemplateCatalog"
  - "amazonS3TemplatesBucket"
  - "serviceCatalogPortfolioStacks"
architecture_ref: "dynamic-ProductPromotionFlow"
---

# Product Template Authoring and Upload

## Summary

When a new AWS resource type needs to be added to a Service Catalog portfolio, or an existing product template requires enhancement, a Cloud Core engineer authors or modifies a CloudFormation template under `templates/products/`. After incrementing the `VERSION` file, the engineer uploads the template to the `grpn-prod-cloudcore-service-catalog` S3 bucket, renames it with the version suffix, and registers the new version in the portfolio definition with an appropriate promotion condition.

## Trigger

- **Type**: manual
- **Source**: Cloud Core engineer initiating a product template change
- **Frequency**: On demand (per product version release)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cloud Core Engineer | Initiates template change, uploads to S3, updates portfolio stack | N/A (human actor) |
| Product Template Catalog | Stores versioned template files and VERSION manifests locally | `productTemplateCatalog` |
| Amazon S3 Template Bucket | Hosts versioned template artifacts for Service Catalog to fetch | `amazonS3TemplatesBucket` |
| Service Catalog Portfolio Stacks | Registers new provisioning artifact version pointing to S3 URL | `serviceCatalogPortfolioStacks` |
| Jenkins Pipeline | Validates updated templates with cfn-guard before merge | N/A (CI system) |

## Steps

1. **Author template**: Engineer creates or updates `templates/products/{portfolio}/{product}/template.yaml` following product conventions (SSE encryption, public access blocking, required tags, etc.)
   - From: `productTemplateCatalog` (local working copy)
   - To: `productTemplateCatalog`
   - Protocol: local file edit

2. **Increment version**: Engineer updates `templates/products/{portfolio}/{product}/VERSION` with the next semantic version (e.g., `v1.11` -> `v1.12`)
   - From: `productTemplateCatalog`
   - To: `productTemplateCatalog`
   - Protocol: local file edit

3. **Validate via Jenkins**: On pull request, Jenkins runs `cfn-guard validate -r /opt/rules/guard_rules.guard -d /opt/tests/ConveyorCloud/` against all templates under `templates/products/ConveyorCloud/`
   - From: Jenkins agent
   - To: `productTemplateCatalog` (read-only validation)
   - Protocol: Docker (cfn-guard container `docker.groupondev.com/cloudcore/cfn-guard:v0.1.0`)

4. **Upload templates to S3**: After merge, engineer syncs all templates: `cd templates/ && aws-okta exec servicecatalog-prod -- aws s3 sync . s3://grpn-prod-cloudcore-service-catalog/templates --region us-west-2`
   - From: `productTemplateCatalog`
   - To: `amazonS3TemplatesBucket`
   - Protocol: AWS SDK / S3

5. **Version-stamp in S3**: Engineer renames the uploaded template with its version suffix: `aws-okta exec servicecatalog-prod -- aws s3 mv s3://.../template.yaml s3://.../template-v{VERSION}.yaml`
   - From: `amazonS3TemplatesBucket`
   - To: `amazonS3TemplatesBucket`
   - Protocol: AWS SDK / S3

6. **Register new version in portfolio**: Engineer adds a new `ProvisioningArtifactParameters` entry in `portfolios/ConveyorCloud/main.yaml` (or Community equivalent) pointing to the versioned S3 URL, gated by `OnlyInDev` condition
   - From: `productTemplateCatalog` (VERSION manifests)
   - To: `serviceCatalogPortfolioStacks` (portfolio CFN template source)
   - Protocol: local file edit

7. **Deploy portfolio stack update**: Engineer runs `aws cloudformation update-stack --stack-name ServiceCatalog-ConveyorCloud-dev --parameters file://dev/parameters.json --region us-west-2`
   - From: Engineer (AWS CLI)
   - To: `serviceCatalogPortfolioStacks` (via AWS CloudFormation)
   - Protocol: AWS CLI / CloudFormation API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| cfn-guard validation failure | Jenkins pipeline fails; PR blocked | Engineer fixes template to satisfy compliance rules before merging |
| S3 upload permission denied | `aws-okta exec servicecatalog-prod` returns access denied | Engineer verifies `servicecatalog-prod` Okta profile and IAM role configuration |
| Template URL missing in S3 | CloudFormation `update-stack` fails with TemplateURL error | Engineer re-runs `aws s3 sync` and `aws s3 mv` to ensure versioned file is present |
| CloudFormation stack update fails | Stack rolls back to previous state | Engineer reviews CloudFormation stack events and corrects the portfolio template |

## Sequence Diagram

```
Engineer -> Jenkins: Push PR with updated template
Jenkins -> productTemplateCatalog: Read templates for cfn-guard validation
Jenkins --> Engineer: Validation pass/fail result
Engineer -> amazonS3TemplatesBucket: aws s3 sync (upload templates)
Engineer -> amazonS3TemplatesBucket: aws s3 mv (rename with version suffix)
Engineer -> serviceCatalogPortfolioStacks: aws cloudformation update-stack (register new artifact version)
serviceCatalogPortfolioStacks -> amazonS3TemplatesBucket: Reference versioned template URL
```

## Related

- Architecture dynamic view: `dynamic-ProductPromotionFlow`
- Related flows: [Product Version Promotion](product-version-promotion.md)
