---
service: "deal_wizard"
title: "Deal Inventory Allocation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-inventory-allocation"
flow_type: synchronous
trigger: "Deal option configuration is finalized and inventory allocation is initiated"
participants:
  - "dealWizardWebUi"
  - "dealManagementClient"
  - "continuumDealManagementApi"
  - "continuumVoucherInventoryService"
architecture_ref: "dynamic-dealInventoryAllocation"
---

# Deal Inventory Allocation

## Summary

The Deal Inventory Allocation flow provisions voucher inventory for a deal after its options and pricing configuration have been finalized. The Web UI uses the Deal Management API to update the inventory products associated with the deal UUID, then calls the Voucher Inventory Service to set redemption windows and voucher quantity limits. This flow ensures that the deal's voucher supply is reserved and properly configured in the inventory system before the deal enters the approval pipeline.

## Trigger

- **Type**: user-action (initiated as part of the wizard flow after option submission)
- **Source**: Triggered when deal options are saved and the wizard advances; may also be triggered manually by re-saving the options step
- **Frequency**: On-demand; once per deal options finalization (may repeat on option edits)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Sales Representative (User) | Finalizes deal options, triggering inventory allocation | — |
| Deal Wizard Web UI | Orchestrates inventory allocation calls after options are persisted | `dealWizardWebUi` |
| Deal Management Client | Updates inventory product records in Deal Management API | `dealManagementClient` |
| Deal Management API | Manages inventory product definitions for the deal | `continuumDealManagementApi` |
| Voucher Inventory Service | Allocates voucher supply and configures redemption windows | `continuumVoucherInventoryService` |

## Steps

1. **Options Persisted**: Deal options (pricing tiers, quantities, voucher values) have been validated and saved to MySQL (see [Deal Option & Pricing Configuration](deal-option-pricing-configuration.md)).
   - From: `dealWizardWebUi`
   - To: MySQL (`dealWizardMysql`)
   - Protocol: Direct (ActiveRecord)

2. **Update Inventory Products**: Deal Management Client calls Deal Management API to update or create inventory product records for the deal UUID, reflecting the finalized option configuration.
   - From: `dealWizardWebUi` via `dealManagementClient`
   - To: `continuumDealManagementApi`
   - Protocol: REST

3. **Allocate Voucher Inventory**: Web UI calls Voucher Inventory Service to set voucher quantity limits and redemption windows for each configured deal option.
   - From: `continuumDealWizardWebApp`
   - To: `continuumVoucherInventoryService`
   - Protocol: REST

4. **Confirm Allocation**: Voucher Inventory Service confirms that inventory has been allocated and redemption windows are set.
   - From: `continuumVoucherInventoryService`
   - To: `continuumDealWizardWebApp`
   - Protocol: REST response

5. **Update Deal Record**: Web UI records inventory allocation status on the deal record in MySQL.
   - From: `dealWizardWebUi`
   - To: MySQL (`dealWizardMysql`)
   - Protocol: Direct (ActiveRecord)

6. **Advance to Fine Prints**: With inventory allocated, the wizard advances the sales rep to the Fine Prints step.
   - From: `dealWizardWebUi`
   - To: `Sales Representative`
   - Protocol: HTTPS (browser redirect)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal Management API unavailable | HTTP error displayed; inventory product update not completed | Sales rep sees error; must retry options submission |
| Voucher Inventory Service unavailable | HTTP error displayed; inventory not allocated | Sales rep sees error; deal options saved but inventory not reserved; must retry |
| Inventory allocation rejected (quantity/limit violation) | Error response from Voucher Inventory Service surfaced in UI | Sales rep must adjust option quantities within allowed limits |
| Partial failure (products updated, inventory not allocated) | Deal record flags incomplete inventory allocation | Wizard prevents progression to approval until allocation is resolved |

## Sequence Diagram

```
dealWizardWebUi -> MySQL: Persist deal options (quantities, voucher values)
dealWizardWebUi -> dealManagementClient: Update inventory products
dealManagementClient -> continuumDealManagementApi: PUT /deals/:uuid/products
continuumDealManagementApi --> dealManagementClient: Products updated
dealManagementClient --> dealWizardWebUi: Confirmation
dealWizardWebUi -> continuumVoucherInventoryService: Allocate voucher inventory + set redemption windows
continuumVoucherInventoryService --> dealWizardWebUi: Inventory allocated
dealWizardWebUi -> MySQL: Update deal record (inventory_allocated = true)
dealWizardWebUi --> Sales Rep: Redirect to /deals/:id/fine_prints
```

## Related

- Architecture dynamic view: `dynamic-dealInventoryAllocation`
- Related flows: [Deal Option & Pricing Configuration](deal-option-pricing-configuration.md), [Deal Approval & Submission](deal-approval-and-submission.md), [Deal Status Monitoring](deal-status-monitoring.md)
