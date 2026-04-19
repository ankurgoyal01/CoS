---
service: "aws-service-catalog"
title: "Portfolio Share Acceptance"
generated: "2026-03-03"
type: flow
flow_name: "portfolio-share-acceptance"
flow_type: batch
trigger: "Manual — a destination LandingZone account must be onboarded to receive a shared portfolio"
participants:
  - "serviceCatalogPortfolioStacks"
  - "serviceCatalogShareAcceptStacks"
  - "conveyorShareAcceptTemplate"
architecture_ref: "dynamic-ShareAcceptanceFlow"
---

# Portfolio Share Acceptance

## Summary

After a Service Catalog portfolio is deployed in the hub account (`grpn-service-catalog-prod`) and shared with a destination AWS account via `AWS::ServiceCatalog::PortfolioShare`, the destination account must accept the share and grant access to the IAM principals that will use the portfolio. This is done by deploying a share-accept CloudFormation stack in the destination account. This flow implements the hub-and-spoke model's second half: enabling consumption of the shared portfolio.

## Trigger

- **Type**: manual
- **Source**: Cloud Core operator onboarding a new destination account or adding a new portfolio stage share
- **Frequency**: On demand (once per account/region/stage combination, or when the portfolio is first shared to a new account)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cloud Core Operator | Deploys share-accept stack in the destination account | N/A (human actor) |
| Service Catalog Portfolio Stacks (hub) | Has already shared the portfolio with the destination account ID via `AWS::ServiceCatalog::PortfolioShare` | `serviceCatalogPortfolioStacks` |
| Service Catalog Share-Accept Stacks | CloudFormation stacks deployed in destination accounts to accept the share and assign principals | `serviceCatalogShareAcceptStacks` |
| ConveyorCloud Share-Accept Template | The `portfolios/ConveyorCloud/share-accept/main.yaml` template defining `AcceptedPortfolioShare` and `PortfolioPrincipalAssociation` resources | `conveyorShareAcceptTemplate` |
| Destination AWS Account | The LandingZone account (e.g., conveyor-sandbox `236248269315`, conveyor-stable `286052569778`, conveyor-prod `497256801702`) that receives the portfolio | `landingZoneAccounts` |

## Steps

1. **Verify portfolio share exists in hub**: Operator confirms the hub portfolio stack includes an `AWS::ServiceCatalog::PortfolioShare` for the target account ID and that the stack is in `UPDATE_COMPLETE` or `CREATE_COMPLETE` state
   - From: Operator
   - To: `serviceCatalogPortfolioStacks` (AWS CloudFormation console in hub account)
   - Protocol: AWS console / CLI

2. **Obtain the shared Portfolio ID**: Operator retrieves the Portfolio ID output from the hub account's CloudFormation stack (`ServiceCatalog-ConveyorCloud-{stage}` → Outputs → `ServiceCatalogPortfolio`)
   - From: Operator
   - To: `serviceCatalogPortfolioStacks`
   - Protocol: AWS console / `aws cloudformation describe-stacks`

3. **Deploy share-accept stack in destination account**: Operator assumes the destination account's IAM role via `aws-okta` and creates the share-accept stack with the portfolio ID as a parameter:
   ```
   aws-okta exec {destination-profile} -- aws cloudformation create-stack \
     --stack-name ServiceCatalog-ConveyorCloud-{stage}-accept \
     --template-body file://portfolios/ConveyorCloud/share-accept/main.yaml \
     --parameters file://portfolios/ConveyorCloud/share-accept/{stage}/{region}/parameters.json \
     --region {region}
   ```
   - From: Operator (AWS CLI)
   - To: `serviceCatalogShareAcceptStacks` (via AWS CloudFormation in destination account)
   - Protocol: AWS CLI / CloudFormation API

4. **Accept the portfolio share**: CloudFormation creates `AWS::ServiceCatalog::AcceptedPortfolioShare` resource in the destination account, accepting the share from the hub account
   - From: `conveyorShareAcceptTemplate`
   - To: AWS Service Catalog in destination account
   - Protocol: AWS CloudFormation resource provisioning

5. **Associate principal IAM user**: For ConveyorCloud accounts (account IDs `236248269315`, `549734399709`, `286052569778`, `497256801702`), CloudFormation also creates `AWS::ServiceCatalog::PortfolioPrincipalAssociation` granting portfolio access to `arn:aws:iam::{AccountId}:user/conveyor-provisioner`
   - From: `conveyorShareAcceptTemplate`
   - To: `landingZoneAccounts` (IAM in destination account)
   - Protocol: AWS CloudFormation resource provisioning

6. **Verify access**: Operator or ConveyorCloud team confirms the portfolio and its products are visible in the Service Catalog console of the destination account using the `conveyor-provisioner` credentials
   - From: Operator / ConveyorCloud team
   - To: AWS Service Catalog console (destination account)
   - Protocol: AWS Service Catalog console

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Portfolio share not found in destination account | Hub stack may not have been updated to include the share for this account; verify hub stack includes `AWS::ServiceCatalog::PortfolioShare` with correct `AccountId` | Hub stack update required before share-accept can succeed |
| `PortfolioPrincipalAssociation` fails — `conveyor-provisioner` user not found | IAM user not provisioned in destination account yet (handled by AWSLandingZone repo) | Coordinate with LandingZone team to create the IAM user first |
| Share-accept stack already exists | Use `update-stack` instead of `create-stack` | Operator switches to `aws cloudformation update-stack` |
| Wrong `PortfolioId` in parameters | `AcceptedPortfolioShare` fails | Retrieve correct Portfolio ID from hub stack outputs and update `parameters.json` |

## Sequence Diagram

```
Operator -> serviceCatalogPortfolioStacks: Verify PortfolioShare for destination account exists
serviceCatalogPortfolioStacks --> Operator: Portfolio ID output
Operator -> serviceCatalogShareAcceptStacks: aws cloudformation create-stack (destination account)
serviceCatalogShareAcceptStacks -> landingZoneAccounts: Create AcceptedPortfolioShare
serviceCatalogShareAcceptStacks -> landingZoneAccounts: Create PortfolioPrincipalAssociation (conveyor-provisioner)
landingZoneAccounts --> Operator: Portfolio visible in Service Catalog console
```

## Related

- Architecture dynamic view: `dynamic-ShareAcceptanceFlow` (referenced in DSL but currently disabled)
- Related flows: [Product Version Promotion](product-version-promotion.md), [AWS Resource Provisioning by Consumer](consumer-resource-provisioning.md)
