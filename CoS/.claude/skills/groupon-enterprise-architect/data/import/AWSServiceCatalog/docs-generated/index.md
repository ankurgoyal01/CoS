---
service: "aws-service-catalog"
title: "AWS ServiceCatalog Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers:
    - "serviceCatalogPortfolioStacks"
    - "serviceCatalogShareAcceptStacks"
    - "productTemplateCatalog"
    - "terraformOrchestration"
    - "keyspacesSingleTableMacroLambda"
    - "keyspacesMultipleTableMacroLambda"
tech_stack:
  language: "CloudFormation YAML / HCL"
  framework: "AWS Service Catalog"
  runtime: "AWS CloudFormation / Terraform 0.12"
---

# AWS ServiceCatalog Documentation

Groupon's implementation of AWS Service Catalog as a hub-and-spoke model for standardizing and governing infrastructure provisioned by service teams across AWS LandingZone accounts.

## Contents

| Document | Description |
|----------|-------------|
| [Overview](overview.md) | Service identity, purpose, domain context, tech stack |
| [Architecture Context](architecture-context.md) | Containers, components, C4 references |
| [API Surface](api-surface.md) | Endpoints, contracts, protocols |
| [Events](events.md) | Async messages published and consumed |
| [Data Stores](data-stores.md) | Databases, caches, storage |
| [Integrations](integrations.md) | External and internal dependencies |
| [Configuration](configuration.md) | Environment, flags, secrets |
| [Flows](flows/index.md) | Process and flow documentation |
| [Deployment](deployment.md) | Infrastructure and environments |
| [Runbook](runbook.md) | Operations, monitoring, troubleshooting |

## Quick Facts

| Property | Value |
|----------|-------|
| Language | CloudFormation YAML / HCL |
| Framework | AWS Service Catalog |
| Runtime | AWS CloudFormation / Terraform 0.12 |
| Build tool | Jenkins (cfn-guard validation) |
| Platform | AWS LandingZone |
| Domain | Cloud Infrastructure / Platform Engineering |
| Team | Cloud Core (cloud-core@groupon.com) |
