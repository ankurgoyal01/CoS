---
service: "aws-service-catalog"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for AWS ServiceCatalog.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Product Template Authoring and Upload](product-template-authoring.md) | batch | Manual — engineer creates or updates a product template | Authors a new or updated CFN product template, increments the VERSION, and uploads versioned artifacts to S3 |
| [Product Version Promotion](product-version-promotion.md) | batch | Manual — Cloud Core operator promotes a version across stages | Promotes a product version through dev, stable, and prod portfolio stages by updating CloudFormation conditions and deploying stacks |
| [Portfolio Share Acceptance](portfolio-share-acceptance.md) | batch | Manual — destination account onboards to a shared portfolio | Deploys share-accept CFN stacks in destination LandingZone accounts so ConveyorCloud teams can discover and provision products |
| [AWS Resource Provisioning by Consumer](consumer-resource-provisioning.md) | synchronous | User action — ConveyorCloud team provisions a product in their account | ConveyorCloud service team selects a product from the shared portfolio and provisions an AWS resource (e.g., S3 bucket, OpenSearch domain) using Service Catalog |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 3 |

## Cross-Service Flows

The Product Version Promotion flow is documented as a dynamic view in the architecture model at `dynamic-ProductPromotionFlow` (`continuumSystem`). The Portfolio Share Acceptance flow is referenced in `views/dynamics/share-acceptance.dsl` (currently disabled in the DSL due to external stub limitations). See [Architecture Context](../architecture-context.md) for container relationships.
