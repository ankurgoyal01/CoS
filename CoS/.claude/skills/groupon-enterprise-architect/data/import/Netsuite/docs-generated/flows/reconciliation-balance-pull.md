---
service: "Netsuite"
title: "Reconciliation Balance Pull"
generated: "2026-03-03"
type: flow
flow_name: "reconciliation-balance-pull"
flow_type: synchronous
trigger: "Finance user submits NS Reconciliation Pull Suitelet in GOODS NetSuite instance (NS2)"
participants:
  - "continuumNetsuiteGoodsCustomizations"
  - "goodsRestlets"
  - "snapLogic"
  - "blackLine"
architecture_ref: "dynamic-netsuite-integration-flows"
---

# Reconciliation Balance Pull

## Summary

This flow triggers an export of NetSuite NS2 account balances to the SnapLogic reconciliation pipeline, which feeds the BlackLine accounting close and reconciliation platform. A finance/accounting staff member opens the `NS_Reconciliation_Pull` Suitelet and submits it, causing NetSuite to fire a POST to the SnapLogic `Reconciliation/NS2 Refresh Balance Trigger` pipeline. SnapLogic then reads the balance data from NetSuite and pushes it to BlackLine for period-end reconciliation.

## Trigger

- **Type**: user-action
- **Source**: Finance/Accounting staff in NetSuite GOODS (NS2) — submitting the NS Reconciliation Pull Suitelet
- **Frequency**: On-demand, typically at month-end or period close

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Finance/Accounting staff | Initiates balance pull via Suitelet UI | external (user) |
| NetSuite GOODS Suitelet (`NS_Reconciliation_Pull`) | Triggers SnapLogic reconciliation pipeline | `goodsRestlets` |
| SnapLogic pipeline (`GrouponProd/projects/Reconciliation/NS2 Refresh Balance Trigger`) | Reads NS2 balances and pushes to BlackLine | `snapLogic` |
| BlackLine | Receives account balance data for reconciliation workspace | `blackLine` |

## Steps

1. **Finance staff opens Reconciliation Pull Suitelet (GET)**: User navigates to the `NS_Reconciliation_Pull` Suitelet. Suitelet renders a form titled "Trigger NS Reconciliation Balance Pull" with a Submit button.
   - From: Finance/Accounting staff (browser)
   - To: `goodsRestlets` (Suitelet GET handler)
   - Protocol: HTTPS (NetSuite UI)

2. **Finance staff submits form (POST)**: User clicks Submit to initiate the balance pull.
   - From: Finance/Accounting staff (browser)
   - To: `goodsRestlets` (Suitelet POST handler)
   - Protocol: HTTPS (NetSuite form POST)

3. **Suitelet reads user ID**: Captures `nlapiGetContext().getUser()` for logging purposes.
   - From: `goodsRestlets`
   - To: NetSuite platform context
   - Protocol: in-process

4. **Suitelet triggers SnapLogic reconciliation pipeline**: Sends a request to `https://elastic.snaplogic.com:443/api/1/rest/slsched/feed/GrouponProd/projects/Reconciliation/NS2%20Refresh%20Balance%20Trigger` with `Authorization: Bearer SfBOjASnEChdU5COpCUvJf2efEEZ4hwx` header.
   - From: `goodsRestlets`
   - To: `snapLogic`
   - Protocol: REST (HTTPS, Bearer token)

5. **SnapLogic reads NS2 account balances**: Pipeline queries NetSuite NS2 for account balances across the relevant subsidiaries and accounts for the current period.
   - From: `snapLogic`
   - To: NetSuite NS2 (via REST API)
   - Protocol: REST (HTTPS)

6. **SnapLogic pushes balance data to BlackLine**: Pipeline delivers the extracted balance data to the BlackLine reconciliation platform, refreshing the reconciliation workspace with current NetSuite balances.
   - From: `snapLogic`
   - To: `blackLine`
   - Protocol: managed by SnapLogic pipeline

7. **Suitelet confirms trigger to user**: Logs `responseCode` from SnapLogic and renders confirmation form `NS Reconciliation Balance pull Triggered` with `Request Status: Triggered Pipeline` inline field.
   - From: `goodsRestlets`
   - To: Finance/Accounting staff (browser)
   - Protocol: HTTPS (NetSuite UI response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| SnapLogic returns non-200 | Response code logged via `nlapiLogExecution('DEBUG', 'UpdateResponse:', responseCode)` | Confirmation form still rendered; failure requires SnapLogic monitoring |
| SnapLogic pipeline offline | HTTP call fails; NetSuite logs error | Accounting team must retry or escalate to SnapLogic team |
| BlackLine unavailable | Failure handled by SnapLogic pipeline | BlackLine team must re-trigger after platform recovery |
| Bearer token expired | SnapLogic returns 401/403 | Token must be rotated in Suitelet script source |

## Sequence Diagram

```
Accounting staff -> goodsRestlets: GET NS_Reconciliation_Pull Suitelet
goodsRestlets --> Accounting staff: Form "Trigger NS Reconciliation Balance Pull"
Accounting staff -> goodsRestlets: POST (Submit)
goodsRestlets -> snapLogic: POST NS2 Refresh Balance Trigger (Bearer token)
snapLogic -> NetSuite NS2: Query account balances
NetSuite NS2 --> snapLogic: Balance data
snapLogic -> blackLine: Push balance data to reconciliation workspace
blackLine --> snapLogic: Acknowledgement
snapLogic --> goodsRestlets: HTTP response (responseCode)
goodsRestlets --> Accounting staff: Confirmation form "Triggered Pipeline"
```

## Related

- Architecture dynamic view: `dynamic-netsuite-integration-flows`
- Related flows: [Kyriba Treasury File Exchange](kyriba-treasury-exchange.md)
- See also: [Integrations](../integrations.md) — BlackLine and SnapLogic details
