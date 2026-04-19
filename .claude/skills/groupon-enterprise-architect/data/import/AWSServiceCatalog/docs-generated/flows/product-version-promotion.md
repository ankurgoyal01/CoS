---
service: "aws-service-catalog"
title: "Product Version Promotion"
generated: "2026-03-03"
type: flow
flow_name: "product-version-promotion"
flow_type: batch
trigger: "Manual — Cloud Core operator promotes a tested product version to stable and then production"
participants:
  - "serviceCatalogPortfolioStacks"
  - "productTemplateCatalog"
  - "conveyorCloudPortfolioDefinition"
  - "portfolioPromotionRules"
architecture_ref: "dynamic-ProductPromotionFlow"
---

# Product Version Promotion

## Summary

After a new product version has been validated in the `dev` portfolio, a Cloud Core operator promotes it to the `stable` and then `prod` portfolio stages. This is achieved by updating the CloudFormation condition on the version entry in the portfolio template (from `OnlyInDev` to `PromoteToStable`, then to `PromoteToAll`) and deploying the updated stack to the three production regions. This flow matches the architecture dynamic view `ProductPromotionFlow`.

## Trigger

- **Type**: manual
- **Source**: Cloud Core operator after successful validation of a product version in the dev portfolio
- **Frequency**: On demand (per product version promotion decision)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cloud Core Operator | Decides promotion, updates condition, deploys stacks | N/A (human actor) |
| ConveyorCloud Portfolio Definition | CloudFormation template containing product version entries and conditions | `conveyorCloudPortfolioDefinition` |
| Portfolio Promotion Rules | CloudFormation conditions (`OnlyInDev`, `PromoteToStable`, `PromoteToAll`) | `portfolioPromotionRules` |
| Product Template Catalog | Provides VERSION manifests confirming the version to promote | `productTemplateCatalog` |
| Service Catalog Portfolio Stacks | Deploys the updated portfolio stack with the promoted version visible | `serviceCatalogPortfolioStacks` |

## Steps

1. **Verify dev portfolio**: Operator confirms the target product version is working correctly in the `dev` portfolio stage by provisioning a test product instance in a dev destination account
   - From: Operator
   - To: AWS Service Catalog console (dev destination account)
   - Protocol: AWS Service Catalog console / API

2. **Update promotion condition to `PromoteToStable`**: Operator edits `portfolios/ConveyorCloud/main.yaml` (or Community equivalent), changing the condition on the target version entry from `OnlyInDev` to `PromoteToStable`
   - From: Operator
   - To: `conveyorCloudPortfolioDefinition` (local source)
   - Protocol: local file edit

3. **Deploy stable portfolio stack in eu-west-1**: `aws-okta exec servicecatalog-prod -- aws cloudformation update-stack --stack-name ServiceCatalog-ConveyorCloud-stable --template-body file://main.yaml --parameters file://stable/parameters.json --region eu-west-1`
   - From: `portfolioPromotionRules` (condition resolved to include stable)
   - To: `serviceCatalogPortfolioStacks` (via AWS CloudFormation in `eu-west-1`)
   - Protocol: AWS CLI / CloudFormation API

4. **Deploy stable portfolio stack in us-west-1**: Same command targeting `--region us-west-1`
   - From: `portfolioPromotionRules`
   - To: `serviceCatalogPortfolioStacks`
   - Protocol: AWS CLI / CloudFormation API

5. **Deploy stable portfolio stack in us-west-2**: Same command targeting `--region us-west-2`
   - From: `portfolioPromotionRules`
   - To: `serviceCatalogPortfolioStacks`
   - Protocol: AWS CLI / CloudFormation API

6. **Update promotion condition to `PromoteToAll`**: After stable validation, operator changes condition from `PromoteToStable` to `PromoteToAll` in the portfolio template
   - From: Operator
   - To: `conveyorCloudPortfolioDefinition`
   - Protocol: local file edit

7. **Deploy prod portfolio stack in all three regions**: Operator runs `update-stack` for `ServiceCatalog-ConveyorCloud-prod` in `eu-west-1`, `us-west-1`, and `us-west-2` using `prod/parameters.json`
   - From: `portfolioPromotionRules` (condition resolved to include prod)
   - To: `serviceCatalogPortfolioStacks` (via AWS CloudFormation)
   - Protocol: AWS CLI / CloudFormation API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Stack update fails in one region | CloudFormation rolls back in that region; other regions unaffected | Operator investigates stack events in affected region; remaining regions stay at previous version |
| Version breaks in stable environment | Operator changes condition back to `OnlyInDev`; re-deploys stable stacks | Version removed from stable portfolio; dev testing continues |
| Operator deploys to wrong stage | CloudFormation parameters file mismatch results in wrong `PortfolioStage` value | Check stack parameters in console; redeploy with correct `parameters.json` |

## Sequence Diagram

```
Operator -> conveyorCloudPortfolioDefinition: Update version condition to PromoteToStable
Operator -> serviceCatalogPortfolioStacks: aws cloudformation update-stack (stable, eu-west-1)
serviceCatalogPortfolioStacks -> productTemplateCatalog: Reference promoted version URLs
Operator -> serviceCatalogPortfolioStacks: aws cloudformation update-stack (stable, us-west-1)
Operator -> serviceCatalogPortfolioStacks: aws cloudformation update-stack (stable, us-west-2)
Operator -> conveyorCloudPortfolioDefinition: Update version condition to PromoteToAll
Operator -> serviceCatalogPortfolioStacks: aws cloudformation update-stack (prod, eu-west-1)
Operator -> serviceCatalogPortfolioStacks: aws cloudformation update-stack (prod, us-west-1)
Operator -> serviceCatalogPortfolioStacks: aws cloudformation update-stack (prod, us-west-2)
```

## Related

- Architecture dynamic view: `dynamic-ProductPromotionFlow`
- Related flows: [Product Template Authoring and Upload](product-template-authoring.md), [Portfolio Share Acceptance](portfolio-share-acceptance.md)
