---
service: "aws-service-catalog"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 7
internal_count: 1
---

# Integrations

## Overview

AWSServiceCatalog integrates with seven AWS-managed external services to deliver its portfolio management and product provisioning capabilities. All interactions are via AWS SDK/CLI calls performed during CloudFormation stack deployments or manual operator steps. Internally, it is consumed by ConveyorCloud destination accounts through the portfolio share-accept mechanism.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| AWS Service Catalog API | aws-sdk / CloudFormation | Creates portfolios, products, versioned artifacts, launch constraints, and portfolio shares | yes | `awsServiceCatalogApi` |
| AWS CloudFormation API | aws-sdk / CLI | Deploys and updates portfolio stacks and share-accept stacks | yes | `awsCloudFormationApi` |
| Amazon S3 (`grpn-prod-cloudcore-service-catalog`) | HTTPS / AWS SDK | Stores and serves versioned product CloudFormation templates | yes | `amazonS3TemplatesBucket` |
| AWS Organizations | aws-sdk | Enables delegated administrator configuration for cross-account portfolio sharing | yes | `awsOrganizationsService` |
| AWS IAM | aws-sdk / Terraform | Creates and updates launch-constraint IAM roles and policies (e.g., `grpn-all-conveyor-service-catalog-execution`) | yes | `awsIamService` |
| AWS Lambda | aws-sdk / Terraform | Deploys Keyspaces macro Lambda functions (single-table and multi-table transforms) | no | `awsLambdaService` |
| AWS Secrets Manager | aws-sdk / Terraform | Reads managed secret values as automation inputs during Terraform orchestration | no | `awsSecretsManagerService` |

### AWS Service Catalog API Detail

- **Protocol**: AWS SDK (via CloudFormation `AWS::ServiceCatalog::*` resource types)
- **Base URL / SDK**: AWS CloudFormation managed; `AWS::ServiceCatalog::Portfolio`, `AWS::ServiceCatalog::CloudFormationProduct`, `AWS::ServiceCatalog::LaunchRoleConstraint`, `AWS::ServiceCatalog::PortfolioProductAssociation`, `AWS::ServiceCatalog::PortfolioShare`, `AWS::ServiceCatalog::AcceptedPortfolioShare`, `AWS::ServiceCatalog::PortfolioPrincipalAssociation`
- **Auth**: AWS IAM role (`arn:aws:iam::746540744976:role/Groupon-Admin` via `aws-okta` for manual ops; `conveyor-provisioner` IAM user in destination accounts)
- **Purpose**: Central registry for all product definitions, versioned provisioning artifacts, and portfolio-to-account share relationships
- **Failure mode**: CloudFormation stack update fails; portfolio and product state remains at previous version
- **Circuit breaker**: No

### AWS CloudFormation API Detail

- **Protocol**: AWS CLI / SDK
- **Base URL / SDK**: `aws cloudformation create-stack`, `update-stack`, `delete-stack`
- **Auth**: AWS IAM via `aws-okta exec servicecatalog-prod`
- **Purpose**: Deploys and updates the `ServiceCatalog-ConveyorCloud-{stage}` and `ServiceCatalog-Community-{stage}` portfolio stacks and the share-accept stacks in destination accounts
- **Failure mode**: Stack update fails with CloudFormation rollback; previous state preserved
- **Circuit breaker**: No

### Amazon S3 Detail

- **Protocol**: HTTPS (template URL references) + AWS CLI (`aws s3 sync`, `aws s3 mv`)
- **Base URL / SDK**: `https://s3-${ProductTemplateS3Region}.amazonaws.com/${ProductTemplateS3BucketName}/templates/...`
- **Auth**: AWS IAM via `aws-okta exec servicecatalog-prod`
- **Purpose**: Stores all versioned product CloudFormation templates; templates are referenced by URL in provisioning artifact definitions
- **Failure mode**: CloudFormation stack update fails if template URL is unreachable at deployment time
- **Circuit breaker**: No

### AWS Organizations Detail

- **Protocol**: AWS SDK
- **Base URL / SDK**: AWS Organizations delegated administrator API
- **Auth**: AWS IAM (Organization management account)
- **Purpose**: `grpn-service-catalog-prod` is registered as the delegated administrator so portfolios can be shared at the OU level across LandingZone accounts
- **Failure mode**: Portfolio sharing fails; destination accounts cannot access the portfolio
- **Circuit breaker**: No

### AWS IAM Detail

- **Protocol**: AWS SDK / Terraform
- **Base URL / SDK**: Terraform `aws` provider; `grpn-all-conveyor-service-catalog-execution` launch constraint role
- **Auth**: Terraform execution role
- **Purpose**: Manages launch-constraint roles that Service Catalog uses to provision product resources in destination accounts; also manages `grpn-sandbox-service-catalog-community-provisioner` for Community portfolio
- **Failure mode**: Product provisioning fails in destination account if role does not exist
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| ConveyorCloud (LandingZone accounts) | CloudFormation / Service Catalog console | Destination accounts accept shared portfolios and provision AWS resources via the Service Catalog interface | `landingZoneAccounts` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| ConveyorCloud service teams | AWS Service Catalog console / API | Provision S3, OpenSearch, Keyspaces, RDS, SNS, Secrets Manager resources in ConveyorCloud destination accounts |
| Community / general engineering teams | AWS Service Catalog console / API | Provision generic AWS resources via the Community portfolio in sandbox environments |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

CloudFormation stack deployments are self-contained and synchronous. There are no health-check endpoints or circuit breakers configured in this repository. Failed stack updates automatically roll back to the previous state. Operators should verify stack status in the AWS CloudFormation console in `us-west-2`, `us-west-1`, and `eu-west-1` for stable/prod portfolios.
