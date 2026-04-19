---
service: "aws-service-catalog"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "serviceCatalogPortfolioStacks"
    - "serviceCatalogShareAcceptStacks"
    - "productTemplateCatalog"
    - "terraformOrchestration"
    - "keyspacesSingleTableMacroLambda"
    - "keyspacesMultipleTableMacroLambda"
---

# Architecture Context

## System Context

AWSServiceCatalog is modeled as part of the `continuumSystem` (Continuum Platform) within Groupon's C4 architecture. It sits in the Cloud Infrastructure domain and acts as the central control plane for standardized AWS resource provisioning. The system owns the hub account (`grpn-service-catalog-prod`) and pushes portfolio definitions outward to LandingZone destination accounts (ConveyorCloud sandboxes, stable, and prod environments). ConveyorCloud teams interact with shared portfolios in their own accounts to provision AWS resources (S3, OpenSearch, Keyspaces, RDS, SNS, Secrets Manager) without needing direct CloudFormation expertise.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Service Catalog Portfolio Stacks | `serviceCatalogPortfolioStacks` | IaC | CloudFormation YAML | AWSTemplateFormatVersion 2010-09-09 | CloudFormation stacks that define and update Service Catalog portfolios, products, and versions |
| Service Catalog Share-Accept Stacks | `serviceCatalogShareAcceptStacks` | IaC | CloudFormation YAML | AWSTemplateFormatVersion 2010-09-09 | CloudFormation stacks deployed in destination accounts to accept shared portfolios and assign principals |
| Product Template Catalog | `productTemplateCatalog` | IaC / Catalog | CloudFormation Templates | Multiple (up to v1.11 S3, v0.13 OpenSearch) | Versioned CloudFormation product templates and VERSION manifests under `templates/products/` |
| Terraform Orchestration | `terraformOrchestration` | IaC | Terraform/HCL | 0.12.7 | Terraform and Terragrunt modules that orchestrate Service Catalog resources and Keyspaces macro infrastructure |
| Keyspaces Single-Table Macro Lambda | `keyspacesSingleTableMacroLambda` | Lambda | Python (AWS Lambda) | N/A | Lambda source and packaging for single-table Keyspaces CloudFormation macro transform |
| Keyspaces Multi-Table Macro Lambda | `keyspacesMultipleTableMacroLambda` | Lambda | Python (AWS Lambda) | N/A | Lambda source and packaging for multi-table Keyspaces CloudFormation macro transform |

## Components by Container

### Service Catalog Portfolio Stacks (`serviceCatalogPortfolioStacks`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `conveyorCloudPortfolioDefinition` | Defines ConveyorCloud portfolio resources, products, product versions, and promotion conditions | CloudFormation Template |
| `communityPortfolioDefinition` | Defines Community portfolio resources and product registrations | CloudFormation Template |
| `portfolioPromotionRules` | Condition logic controlling which product versions are promoted to dev, stable, and prod portfolios | CloudFormation Conditions |

### Service Catalog Share-Accept Stacks (`serviceCatalogShareAcceptStacks`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `conveyorShareAcceptTemplate` | Share-accept stack used by destination accounts for ConveyorCloud portfolio access | CloudFormation Template |
| `communityShareAcceptTemplate` | Share-accept stack used by destination accounts for Community portfolio access | CloudFormation Template |

### Product Template Catalog (`productTemplateCatalog`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `conveyorCloudProductTemplates` | CloudFormation templates for ConveyorCloud products (S3, OpenSearch, Keyspaces, operator tester) | CloudFormation Templates |
| `genericProductTemplates` | CloudFormation templates for community and generic products (RDS, SNS, Keyspaces, Secret, Elasticsearch) | CloudFormation Templates |
| `templateVersionManifests` | VERSION files that pin and promote provisioning artifact versions | Version Metadata |

### Terraform Orchestration (`terraformOrchestration`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `mainOrchestrationModule` | Entry-point Terragrunt/Terraform module wiring Service Catalog and macro submodules across environments | Terraform Module |
| `scPortfolioModule` | Creates and updates Service Catalog portfolios | Terraform Module |
| `scProductModule` | Creates and updates Service Catalog products and provisioning artifacts | Terraform Module |
| `scSharePortfolioModule` | Creates and updates portfolio share and acceptance associations | Terraform Module |
| `macroKeyspacesGlobalModule` | Deploys global resources for Keyspaces macro workflows | Terraform Module |
| `macroKeyspacesRegionalModule` | Deploys regional macro resources and Lambda packaging logic | Terraform Module |
| `wavefrontDashboardsModule` | Creates dashboard resources for operational monitoring | Terraform Module |

### Keyspaces Single-Table Macro Lambda (`keyspacesSingleTableMacroLambda`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `singleTableMacroHandler` | Python Lambda function that converts compact Keyspaces definitions into CloudFormation resources | Python |
| `singleTableTransformTemplate` | Template mapping consumed by the macro handler for output synthesis | JSON Template |

### Keyspaces Multi-Table Macro Lambda (`keyspacesMultipleTableMacroLambda`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `multipleTableMacroHandler` | Python Lambda function that expands multi-table Keyspaces definitions into CloudFormation resources | Python |
| `multipleTableTransformTemplate` | Template mapping consumed by the macro handler for output synthesis | JSON Template |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `serviceCatalogPortfolioStacks` | `productTemplateCatalog` | References product template URLs stored in S3 | HTTPS / S3 URL |
| `terraformOrchestration` | `awsIamService` | Creates and updates IAM roles and policies | AWS SDK |
| `mainOrchestrationModule` | `scPortfolioModule` | Calls module to manage Service Catalog portfolios | Terraform module call |
| `mainOrchestrationModule` | `scProductModule` | Calls module to manage products and provisioning artifacts | Terraform module call |
| `mainOrchestrationModule` | `scSharePortfolioModule` | Calls module to manage portfolio shares and principal associations | Terraform module call |
| `mainOrchestrationModule` | `macroKeyspacesGlobalModule` | Calls module to deploy global macro resources | Terraform module call |
| `mainOrchestrationModule` | `macroKeyspacesRegionalModule` | Calls module to deploy regional macro resources | Terraform module call |
| `mainOrchestrationModule` | `wavefrontDashboardsModule` | Calls module to deploy monitoring dashboards | Terraform module call |
| `scProductModule` | `templateVersionManifests` | Reads template versions and URLs | File read |
| `macroKeyspacesRegionalModule` | `singleTableMacroHandler` | Packages and deploys single-table macro Lambda source | Terraform / Lambda deployment |
| `macroKeyspacesRegionalModule` | `multipleTableMacroHandler` | Packages and deploys multi-table macro Lambda source | Terraform / Lambda deployment |
| `portfolioPromotionRules` | `conveyorCloudPortfolioDefinition` | Applies promotion gates (dev, stable, prod) for product versions | CloudFormation Conditions |
| `portfolioPromotionRules` | `communityPortfolioDefinition` | Applies promotion gates for community products | CloudFormation Conditions |
| `conveyorShareAcceptTemplate` | `conveyorCloudPortfolioDefinition` | Accepts shared ConveyorCloud portfolio instances in destination accounts | CloudFormation |
| `communityShareAcceptTemplate` | `communityPortfolioDefinition` | Accepts shared Community portfolio instances in destination accounts | CloudFormation |

## Architecture Diagram References

- Container: `containers-AWSServiceCatalog`
- Component (Portfolio Stacks): `components-service-catalog-portfolio-stacks`
- Component (Share-Accept Stacks): `components-service-catalog-share-accept-stacks`
- Component (Product Template Catalog): `components-product-template-catalog`
- Component (Terraform Orchestration): `components-terraform-orchestration`
- Component (Single-Table Macro): `components-keyspaces-single-table-macro-lambda`
- Component (Multi-Table Macro): `components-keyspaces-multi-table-macro-lambda`
- Dynamic (Product Promotion): `dynamic-ProductPromotionFlow`
