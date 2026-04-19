---
service: "deal_wizard"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Deal Wizard.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Deal Creation Wizard](deal-wizard-creation.md) | synchronous | Sales rep initiates deal from Salesforce Opportunity | End-to-end guided wizard flow from Opportunity selection to deal record creation |
| [Deal Option & Pricing Configuration](deal-option-pricing-configuration.md) | synchronous | Sales rep reaches the Options step in the wizard | Configures deal pricing, discount percentages, voucher values, and quantity limits |
| [Merchant Fine Print Configuration](merchant-fine-print-configuration.md) | synchronous | Sales rep reaches the Fine Prints step in the wizard | Selects and customizes locale-appropriate legal fine print content for a deal |
| [Deal Approval & Submission](deal-approval-and-submission.md) | synchronous | Sales rep submits completed deal for approval | Validates deal completeness, submits to approval workflow, and persists to Salesforce |
| [Deal Inventory Allocation](deal-inventory-allocation.md) | synchronous | Deal option configuration is finalized | Allocates voucher inventory and sets redemption windows via Voucher Inventory Service |
| [Deal Status Monitoring](deal-status-monitoring.md) | synchronous | Admin or sales rep requests deal status | Retrieves deal adoption rate and outstanding voucher data from downstream services |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 6 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- [Deal Approval & Submission](deal-approval-and-submission.md) spans `continuumDealWizardWebApp` and `salesForce` — the submission step persists deal data to Salesforce via `POST /api/v1/create_salesforce_deal`
- [Deal Inventory Allocation](deal-inventory-allocation.md) spans `continuumDealWizardWebApp` and `continuumVoucherInventoryService`
- [Deal Option & Pricing Configuration](deal-option-pricing-configuration.md) spans `continuumDealWizardWebApp` and `continuumDealManagementApi`
