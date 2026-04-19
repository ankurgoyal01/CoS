---
service: "Netsuite"
title: "Kyriba Treasury File Exchange"
generated: "2026-03-03"
type: flow
flow_name: "kyriba-treasury-exchange"
flow_type: synchronous
trigger: "Finance user submits Kyriba Inbound or Outbound trigger Suitelet in GOODS NetSuite instance (NS2)"
participants:
  - "continuumNetsuiteGoodsCustomizations"
  - "goodsRestlets"
  - "snapLogic"
  - "kyriba"
architecture_ref: "dynamic-netsuite-integration-flows"
---

# Kyriba Treasury File Exchange

## Summary

This flow synchronizes treasury data between the GOODS NetSuite instance (NS2) and the Kyriba treasury management platform via two Suitelets. The **Outbound** Suitelet (`Kyriba Outbound Trigger`) captures NetSuite cash transaction data and sends it to Kyriba. The **Inbound** Suitelet (`Kyriba Inbound trigger`) imports Kyriba cash position and payment status data back into NetSuite. Both operations are orchestrated through SnapLogic pipelines triggered by the Suitelets. Finance staff manually initiate each direction via the respective Suitelet form.

## Trigger

- **Type**: user-action
- **Source**: Finance/Treasury staff in NetSuite GOODS (NS2) — submitting the Kyriba Inbound or Outbound Suitelet form
- **Frequency**: On-demand, typically daily as part of treasury cash management cycle

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Finance/Treasury staff | Initiates Kyriba sync via Suitelet UI | external (user) |
| NetSuite GOODS Suitelet (`Kyriba Outbound Trigger`) | Triggers outbound NetSuite-to-Kyriba data capture | `goodsRestlets` |
| NetSuite GOODS Suitelet (`Kyriba Inbound trigger`) | Triggers inbound Kyriba-to-NetSuite data import; accepts subsidiary selection | `goodsRestlets` |
| SnapLogic pipeline (`Kyriba outbound parent Trigger`) | Orchestrates NS2 data extraction and delivery to Kyriba | `snapLogic` |
| SnapLogic pipeline (`Kyriba NS2 Inbound Kickoff`) | Orchestrates Kyriba data retrieval and import into NS2 | `snapLogic` |
| Kyriba | Treasury management platform receiving/sending payment and cash data | `kyriba` |

## Steps

### Outbound Direction (NetSuite to Kyriba)

1. **Finance staff opens Outbound Suitelet (GET)**: User navigates to the Kyriba Outbound Trigger Suitelet. Suitelet renders a form titled "Book Cash Rec Transactions from Kyriba" with a Submit button.
   - From: Finance/Treasury staff (browser)
   - To: `goodsRestlets` (Suitelet GET handler)
   - Protocol: HTTPS (NetSuite UI)

2. **Finance staff submits form (POST)**: User clicks Submit to initiate outbound data capture.
   - From: Finance/Treasury staff (browser)
   - To: `goodsRestlets` (Suitelet POST handler)
   - Protocol: HTTPS (NetSuite form POST)

3. **Suitelet triggers Kyriba outbound SnapLogic pipeline**: Sends a request to `https://elastic.snaplogic.com:443/api/1/rest/slsched/feed/GrouponProd/projects/Kyriba/Kyriba%20outbound%20parent%20Trigger` with `Authorization: Bearer KSdmXYy0NXvApjd1JJJLOdIn7WGd1QiG` header.
   - From: `goodsRestlets`
   - To: `snapLogic`
   - Protocol: REST (HTTPS, Bearer token)

4. **SnapLogic extracts NS2 cash transaction data and delivers to Kyriba**: Pipeline reads NetSuite cash/bank transaction data and pushes it to Kyriba treasury platform for reconciliation.
   - From: `snapLogic`
   - To: `kyriba`
   - Protocol: managed by SnapLogic pipeline

5. **Suitelet confirms to user**: Renders form titled "Kyriba Outbound File Captured" with `Request Status: Outbound data has been Captured` inline field.
   - From: `goodsRestlets`
   - To: Finance/Treasury staff (browser)
   - Protocol: HTTPS (NetSuite UI response)

### Inbound Direction (Kyriba to NetSuite)

1. **Finance staff opens Inbound Suitelet (GET)**: User navigates to the Kyriba Inbound trigger Suitelet. Suitelet renders a form titled "Send Transactions to Kyriba" with a required subsidiary selector dropdown (options include "All" and individual subsidiaries).
   - From: Finance/Treasury staff (browser)
   - To: `goodsRestlets` (Suitelet GET handler)
   - Protocol: HTTPS (NetSuite UI)

2. **Finance staff selects subsidiary and submits (POST)**: User selects the target subsidiary and clicks Submit.
   - From: Finance/Treasury staff (browser)
   - To: `goodsRestlets` (Suitelet POST handler)
   - Protocol: HTTPS (NetSuite form POST)

3. **Suitelet triggers Kyriba inbound SnapLogic pipeline**: Sends a request to `https://elastic.snaplogic.com:443/api/1/rest/slsched/feed/GrouponProd/projects/Kyriba/Kyriba%20NS2%20Inbound%20Kickoff` with `Authorization: Bearer mLZCTEfLvGdyPC1f38pTi8F8S7Eyw953` header.
   - From: `goodsRestlets`
   - To: `snapLogic`
   - Protocol: REST (HTTPS, Bearer token)

4. **SnapLogic fetches data from Kyriba and imports into NS2**: Pipeline retrieves cash positions and payment status updates from Kyriba and books them as transactions in NetSuite NS2.
   - From: `snapLogic`
   - To: `kyriba` (read)
   - From: `snapLogic`
   - To: NetSuite NS2 via REST (write)
   - Protocol: managed by SnapLogic pipeline

5. **Suitelet confirms to user**: Renders form titled "Kyriba Inbound File Submitted" with `Request Status: Inbound data has been Submitted` inline field.
   - From: `goodsRestlets`
   - To: Finance/Treasury staff (browser)
   - Protocol: HTTPS (NetSuite UI response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| SnapLogic returns non-200 | Response code and body captured but not surfaced to user in current implementation | Silent failure — requires SnapLogic pipeline monitoring |
| Kyriba platform unavailable | Failure handled by SnapLogic pipeline; not visible in NetSuite | Treasury team must retry via Suitelet |
| Bearer token expired or invalid | SnapLogic returns 401/403 | SnapLogic call fails; token must be rotated in Suitelet script source |

## Sequence Diagram

```
Treasury staff -> goodsRestlets: GET Kyriba Outbound Suitelet
goodsRestlets --> Treasury staff: Form with Submit button
Treasury staff -> goodsRestlets: POST (Submit)
goodsRestlets -> snapLogic: POST Kyriba outbound parent Trigger (Bearer token)
snapLogic -> kyriba: Push NS2 cash transaction data
kyriba --> snapLogic: Acknowledgement
snapLogic --> goodsRestlets: HTTP response
goodsRestlets --> Treasury staff: Confirmation (Outbound data captured)

Treasury staff -> goodsRestlets: GET Kyriba Inbound Suitelet
goodsRestlets --> Treasury staff: Form with subsidiary selector
Treasury staff -> goodsRestlets: POST (subsidiary selected)
goodsRestlets -> snapLogic: POST Kyriba NS2 Inbound Kickoff (Bearer token)
snapLogic -> kyriba: Fetch cash position and payment status
kyriba --> snapLogic: Kyriba data payload
snapLogic -> NetSuite NS2: Import transactions via NS REST API
snapLogic --> goodsRestlets: HTTP response
goodsRestlets --> Treasury staff: Confirmation (Inbound data submitted)
```

## Related

- Architecture dynamic view: `dynamic-netsuite-integration-flows`
- Related flows: [JPM ACH Payment Batch Submission](jpm-ach-payment-batch.md), [Reconciliation Balance Pull](reconciliation-balance-pull.md)
- See also: [Integrations](../integrations.md) — Kyriba and SnapLogic details
