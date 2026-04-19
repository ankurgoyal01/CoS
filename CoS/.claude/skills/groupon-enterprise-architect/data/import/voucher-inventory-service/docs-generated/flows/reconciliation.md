---
service: "voucher-inventory-service"
title: "Reconciliation"
generated: "2026-03-03"
type: flow
flow_name: "reconciliation"
flow_type: batch
trigger: "Scheduled job or manual trigger"
participants:
  - "continuumVoucherInventoryWorkers"
  - "continuumVoucherInventoryWorkers_reconciliationWorkers"
  - "continuumVoucherInventoryWorkers_backfillWorkers"
  - "continuumVoucherInventoryApi_ordersClient"
  - "continuumVoucherInventoryUnitsDb"
architecture_ref: "dynamic-continuum-voucher-inventory"
---

# Reconciliation

## Summary

The reconciliation flow detects and corrects drift between voucher unit status in VIS and the authoritative order status in the Orders Service. Reconciliation workers query units that may be out of sync, fetch their corresponding order status from the Orders Service, and correct any mismatches. This batch process handles missed events, failed message processing, and edge cases that escape the real-time event-driven sync.

## Trigger

- **Type**: schedule / manual
- **Source**: Scheduled Sidekiq jobs or manual rake task execution
- **Frequency**: Periodic (scheduled intervals) or on-demand for targeted reconciliation

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Voucher Inventory Workers | Runs reconciliation worker pods | `continuumVoucherInventoryWorkers` |
| Reconciliation Workers | Queries for drifted units and corrects status | `continuumVoucherInventoryWorkers_reconciliationWorkers` |
| Backfill Workers | Supports bulk correction operations | `continuumVoucherInventoryWorkers_backfillWorkers` |
| Orders Client | Fetches authoritative order status | `continuumVoucherInventoryApi_ordersClient` |
| Voucher Inventory Units DB | Source and target for unit status corrections | `continuumVoucherInventoryUnitsDb` |

## Steps

1. **Identify candidate units**: Reconciliation workers query the Units DB for units in potentially drifted states (e.g., reserved but not confirmed within timeout, or flagged by previous failed processing).
   - From: `continuumVoucherInventoryWorkers_reconciliationWorkers`
   - To: `continuumVoucherInventoryUnitsDb`
   - Protocol: MySQL

2. **Fetch authoritative order status**: For each candidate unit, fetch the current order status from the Orders Service.
   - From: `continuumVoucherInventoryWorkers_reconciliationWorkers`
   - To: `continuumVoucherInventoryApi_ordersClient`
   - Protocol: HTTPS/JSON

3. **Compare and detect drift**: Compare the VIS unit status against the authoritative order status to identify mismatches.
   - From: `continuumVoucherInventoryWorkers_reconciliationWorkers`
   - To: (internal processing)
   - Protocol: Ruby method calls

4. **Correct drifted units**: Update unit status in the Units DB to match the authoritative order status.
   - From: `continuumVoucherInventoryWorkers_reconciliationWorkers`
   - To: `continuumVoucherInventoryUnitsDb`
   - Protocol: MySQL

5. **Reconsider failed messages**: The `ReconsiderFailedMessagesWorker` reprocesses previously failed messages that may have caused the drift.
   - From: `continuumVoucherInventoryWorkers_reconciliationWorkers`
   - To: `continuumVoucherInventoryUnitsDb`
   - Protocol: MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Orders Service unavailable | Skip batch, retry on next scheduled run | Reconciliation deferred |
| Partial batch failure | Log failed units, continue with remaining | Partially reconciled; failures retried next run |
| High drift volume detected | Alert operations team | Manual investigation triggered |

## Sequence Diagram

```
Scheduler -> Reconciliation Workers: triggerReconciliation()
Reconciliation Workers -> Units DB: SELECT units WHERE status IN (candidate_states)
Units DB --> Reconciliation Workers: candidateUnits[]
loop for each candidateUnit
    Reconciliation Workers -> Orders Client: getOrderStatus(orderId)
    Orders Client --> Reconciliation Workers: orderStatus
    alt status mismatch
        Reconciliation Workers -> Units DB: UPDATE inventory_units SET status = orderStatus
    end
end
Reconciliation Workers -> Workers Observability: reportReconciliationResults()
```

## Related

- Architecture dynamic view: `dynamic-continuum-voucher-inventory`
- Related flows: [Order Status Sync](order-status-sync.md), [Inventory Reservation](inventory-reservation.md)
