---
service: "aws-service-catalog"
title: "AWS Resource Provisioning by Consumer"
generated: "2026-03-03"
type: flow
flow_name: "consumer-resource-provisioning"
flow_type: synchronous
trigger: "User action — ConveyorCloud or Community team provisions an AWS resource product from a shared portfolio"
participants:
  - "serviceCatalogPortfolioStacks"
  - "productTemplateCatalog"
  - "serviceCatalogShareAcceptStacks"
architecture_ref: "dynamic-ProductPromotionFlow"
---

# AWS Resource Provisioning by Consumer

## Summary

After a portfolio has been shared with and accepted in a destination account, ConveyorCloud service teams can provision AWS resources (S3 buckets, OpenSearch domains, Keyspaces, RDS instances, SNS topics, Secrets Manager secrets) by launching products from the Service Catalog portfolio. Service Catalog uses the launch-constraint IAM role (`grpn-all-conveyor-service-catalog-execution`) to provision the underlying CloudFormation stack with the consumer's chosen parameters. This flow is owned and initiated by the consumer but depends entirely on the infrastructure defined and maintained by this repository.

## Trigger

- **Type**: user-action
- **Source**: ConveyorCloud service team selecting a product in the AWS Service Catalog console or via ConveyorCloud operator
- **Frequency**: On demand (per resource provisioning request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| ConveyorCloud Service Team | Initiates product provisioning via Service Catalog console or ConveyorCloud operator | N/A (human / ConveyorCloud platform actor) |
| Service Catalog Portfolio Stacks | Hosts the portfolio definition, products, and launch constraints in the hub account | `serviceCatalogPortfolioStacks` |
| Service Catalog Share-Accept Stacks | Has granted `conveyor-provisioner` principal access to the portfolio in the destination account | `serviceCatalogShareAcceptStacks` |
| Product Template Catalog (S3) | Provides the versioned CloudFormation template fetched by Service Catalog during provisioning | `productTemplateCatalog` / `amazonS3TemplatesBucket` |
| Launch Constraint IAM Role | `grpn-all-conveyor-service-catalog-execution` — the IAM role Service Catalog assumes to deploy the product CFN stack | `awsIamService` |

## Steps

1. **Browse portfolio products**: ConveyorCloud team browses the shared portfolio in their destination account's Service Catalog console (or via ConveyorCloud operator) and selects a product (e.g., `ConveyorS3Bucket`, `OpenSearch`, `KeyspacesMultipleTables`)
   - From: ConveyorCloud team
   - To: AWS Service Catalog console (destination account)
   - Protocol: HTTPS / AWS console

2. **Select provisioning artifact version**: Team selects a product version (e.g., `ConveyorS3Bucket` `v1.11`) and provides required input parameters (e.g., `BucketName`, `ServiceTag`, `OwnerTag`)
   - From: ConveyorCloud team
   - To: AWS Service Catalog API (destination account)
   - Protocol: AWS Service Catalog API

3. **Service Catalog fetches product template**: AWS Service Catalog fetches the corresponding CloudFormation template from the S3 URL registered in the provisioning artifact (e.g., `https://s3-us-west-2.amazonaws.com/grpn-prod-cloudcore-service-catalog/templates/products/ConveyorCloud/s3-with-iam-role-access/template-v1.11.yaml`)
   - From: AWS Service Catalog
   - To: `amazonS3TemplatesBucket`
   - Protocol: HTTPS

4. **Service Catalog assumes launch constraint role**: Service Catalog assumes the `grpn-all-conveyor-service-catalog-execution` IAM role (defined as a `LaunchRoleConstraint` in the portfolio) to deploy the product CloudFormation stack
   - From: AWS Service Catalog
   - To: `awsIamService`
   - Protocol: AWS STS AssumeRole

5. **CloudFormation stack created**: CloudFormation deploys the provisioned product stack in the destination account using the fetched template and consumer-supplied parameters (e.g., creates an encrypted S3 bucket with the requested IAM access policy)
   - From: AWS CloudFormation (running as `grpn-all-conveyor-service-catalog-execution`)
   - To: Destination AWS account resources
   - Protocol: AWS CloudFormation

6. **Provisioning complete**: Service Catalog marks the provisioned product as `AVAILABLE`; the consumer can access their newly created AWS resource
   - From: AWS Service Catalog
   - To: ConveyorCloud team
   - Protocol: AWS Service Catalog console / API response

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Launch constraint IAM role missing in destination account | CloudFormation stack creation fails with IAM permissions error | Coordinate with Cloud Core / LandingZone team to deploy the `grpn-all-conveyor-service-catalog-execution` role |
| Consumer provides invalid parameter values | CloudFormation parameter validation fails | Service Catalog surfaces the error to the consumer; consumer corrects parameters and retries |
| Product template referenced in S3 returns 403 | Service Catalog cannot fetch template; provisioning fails | Cloud Core verifies S3 bucket ACLs and CloudFormation service principal access to the bucket |
| CloudFormation stack fails during resource creation | Stack rolls back; Service Catalog shows `FAILED` status | Consumer reviews CloudFormation events; Cloud Core may need to update the product template version |

## Sequence Diagram

```
ConveyorTeam -> ServiceCatalog: Select product + version + parameters
ServiceCatalog -> amazonS3TemplatesBucket: Fetch versioned CFN template
amazonS3TemplatesBucket --> ServiceCatalog: template-v{N}.yaml
ServiceCatalog -> awsIamService: AssumeRole grpn-all-conveyor-service-catalog-execution
awsIamService --> ServiceCatalog: Temporary credentials
ServiceCatalog -> CloudFormation: CreateStack with consumer parameters
CloudFormation --> ServiceCatalog: Stack CREATE_COMPLETE
ServiceCatalog --> ConveyorTeam: Provisioned product AVAILABLE
```

## Related

- Architecture dynamic view: `dynamic-ProductPromotionFlow`
- Related flows: [Portfolio Share Acceptance](portfolio-share-acceptance.md), [Product Version Promotion](product-version-promotion.md)
