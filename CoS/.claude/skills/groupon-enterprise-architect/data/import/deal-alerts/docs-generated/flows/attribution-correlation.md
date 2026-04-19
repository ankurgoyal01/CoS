---
service: "deal-alerts"
title: "Attribution Correlation"
generated: "2026-03-03"
type: flow
flow_name: "attribution-correlation"
flow_type: batch
trigger: "Scheduled timer in n8n"
participants:
  - "continuumDealAlertsWorkflows_attributions"
  - "continuumDealAlertsDb_snapshotStorage"
  - "continuumDealAlertsDb_actionMapping"
architecture_ref: "dynamic-deal-alerts-continuumDealAlertsDb_alertLifecycle"
---

# Attribution Correlation

## Summary

The Attributions workflow correlates inventory replenishment events (detected via deal_deltas where remaining_quantity increases after reaching zero) with the Salesforce tasks and SMS notification replies that preceded them. This produces attribution records that measure the effectiveness of alert-driven interventions. Each attribution includes a score based on the timing and proximity of the action to the replenishment event.

## Trigger

- **Type**: schedule
- **Source**: n8n scheduled timer
- **Frequency**: Periodic (configured in n8n)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Attributions | Correlates replenishment deltas with actions and replies to produce attribution records | `continuumDealAlertsWorkflows_attributions` |
| Snapshot Storage | Source of deal_deltas for detecting replenishment events (remaining_quantity increases) | `continuumDealAlertsDb_snapshotStorage` |
| Action & Attribution Tables | Source of Salesforce tasks and notification replies; target for attribution records | `continuumDealAlertsDb_actionMapping` |

## Steps

1. **Detect replenishment events**: Query `deal_deltas` for records where `field_name = 'remaining_quantity'` and the new value is greater than the old value (inventory was replenished), particularly after a zero-quantity state.
   - From: `continuumDealAlertsWorkflows_attributions`
   - To: `continuumDealAlertsDb_snapshotStorage`
   - Protocol: SQL

2. **Find preceding actions**: For each replenishment event, look up Salesforce tasks and SMS notification replies that were created or received before the replenishment timestamp for the same deal/option.
   - From: `continuumDealAlertsWorkflows_attributions`
   - To: `continuumDealAlertsDb_actionMapping`
   - Protocol: SQL

3. **Calculate attribution scores**: Compute a score for each action-replenishment pair based on temporal proximity and the action type. The n8n-blocks `replenishment-check` module (using Luxon for date math) assists with threshold calculations.
   - From: `continuumDealAlertsWorkflows_attributions`
   - To: Internal processing

4. **Insert attribution records**: Create `alert_inventory_attributions` records linking the alert, option, delta, quantities, action owner, task details, and calculated score.
   - From: `continuumDealAlertsWorkflows_attributions`
   - To: `continuumDealAlertsDb_actionMapping`
   - Protocol: SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No replenishment events found | Workflow completes with no attributions created | Normal state when no inventory changes occurred |
| No preceding actions for a replenishment | No attribution created for that event | Replenishment not attributed to alert-driven intervention |
| Database query timeout | n8n workflow error handling | Retried on next scheduled run |

## Sequence Diagram

```
Attributions -> SnapshotStorage: Query deal_deltas for replenishment events
Attributions -> ActionMapping: Find preceding Salesforce tasks and SMS replies
Attributions -> Attributions: Calculate attribution scores
Attributions -> ActionMapping: Insert alert_inventory_attributions records
```

## Related

- Architecture dynamic view: `dynamic-deal-alerts-continuumDealAlertsDb_alertLifecycle`
- Related flows: [Action Orchestration](action-orchestration.md), [SoldOut Notification Pipeline](soldout-notification-pipeline.md)
