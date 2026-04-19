---
service: "Netsuite"
title: "Vendor Bill Creation"
generated: "2026-03-03"
type: flow
flow_name: "vendor-bill-creation"
flow_type: synchronous
trigger: "REST POST from GLS invoicing service via SnapLogic to the GG_VendorBillExpense_RESTletv1 RESTlet"
participants:
  - "continuumNetsuiteGoodsCustomizations"
  - "goodsRestlets"
  - "snapLogic"
architecture_ref: "dynamic-netsuite-integration-flows"
---

# Vendor Bill Creation

## Summary

The vendor bill creation flow receives invoice payloads from the GLS (Groupon Logistics/Invoicing) service via the `GG_VendorBillExpense_RESTletv1` RESTlet deployed in the GOODS NetSuite instance (NS2). For each invoice object in the batch, NetSuite validates all required fields, creates a `vendorbill` record (or a `vendorcredit` for negative amounts), and returns the NetSuite internal record ID back to the caller. In asynchronous mode the RESTlet immediately acknowledges receipt and sends results via a callback to the GLS update URL.

## Trigger

- **Type**: api-call
- **Source**: GLS invoicing service (via SnapLogic) — HTTP POST to NetSuite RESTlet URL
- **Frequency**: On-demand, per invoice batch from GLS

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GLS invoicing service | Caller — submits invoice batch payload | external |
| SnapLogic | Integration broker (may proxy the call) | `snapLogic` |
| NetSuite GOODS RESTlet (`GG_VendorBillExpense_RESTletv1`) | Processes invoice payload, creates records | `goodsRestlets` |
| NetSuite GOODS User Event (`APAccountchange_autobatching`) | Fires on bill save — auto-assigns currency-specific AP account | `goodsUserEventScripts` |
| NetSuite GOODS User Event (`HeaderTaxCoupaGoodsUserEvent`) | Fires on bill save — distributes Coupa header tax/shipping across lines | `goodsUserEventScripts` |
| NetSuite GOODS User Event (`Groupon_SS_VendorBillNumbering`) | Fires on bill save — sets transaction ID from invoice number, updates parent PO bill total | `goodsUserEventScripts` |

## Steps

1. **Receives invoice batch**: GLS POSTs a JSON array of invoice objects to the RESTlet. Each object contains `glsPaymentUuid`, `recordtype`, `entity` (vendor ID), `custbody_invoice_number`, `duedate`, `terms`, `expense[]` lines, and optional `memo`, `trandate`, `ponumber` fields.
   - From: `GLS invoicing service`
   - To: `goodsRestlets` (NetSuite GOODS NS2)
   - Protocol: REST (HTTPS, JSON)

2. **Checks governance headroom**: RESTlet reads `custscript_vb_min_usage` parameter and checks `nlapiGetContext().getRemainingUsage()`. Stops processing and returns error if governance units are below threshold.
   - From: `goodsRestlets`
   - To: NetSuite platform governance API
   - Protocol: direct (in-process)

3. **Validates required fields**: For each invoice, validates presence of `glsPaymentUuid`, `recordtype`, `duedate`, `custbody_invoice_number`, `entity`, and `terms`. On any missing field, appends an error object to results and skips to the next invoice.
   - From: `goodsRestlets`
   - To: `goodsRestlets` (internal validation)
   - Protocol: direct

4. **Detects negative amounts (credit flow)**: If any expense line has `amount < 0`, routes to `create_vendor_credit` instead of `create_vendor_bill`.
   - From: `goodsRestlets`
   - To: `goodsRestlets` (internal routing)
   - Protocol: direct

5. **Looks up payment terms**: Calls `getCustomListItemId(termsname, 'Term', false)` to resolve terms name to NetSuite internal ID. Returns error if term not found.
   - From: `goodsRestlets`
   - To: NetSuite ERP database
   - Protocol: `nlapiSearchRecord` (in-process API)

6. **Creates vendor bill record**: Calls `nlapiCreateRecord(input.recordtype)` and sets all header and line-item fields using script parameters (`custscript_vb_expense_account`, `custscript_vb_ap_account`, `custscript_vb_sales_channel`, `custscript_vb_cost_center`, `custscript_vb_payment_type_expense`, `custscript_vb_appr_status`) plus payload values. Submits via `nlapiSubmitRecord`.
   - From: `goodsRestlets`
   - To: NetSuite ERP database
   - Protocol: `nlapiCreateRecord` / `nlapiSubmitRecord` (in-process API)

7. **User Event scripts fire on save**: NetSuite automatically triggers `beforeSubmit` and `afterSubmit` User Event scripts: AP account is auto-corrected to currency-specific account (`APAccountchange_autobatching`), Coupa header tax/shipping is distributed across expense lines (`HeaderTaxCoupaGoodsUserEvent`), and transaction ID is set from invoice number while parent PO bill totals are updated (`Groupon_SS_VendorBillNumbering`).
   - From: NetSuite platform
   - To: `goodsUserEventScripts`
   - Protocol: NetSuite event dispatch (synchronous)

8. **Returns results**: Appends `{ glsPaymentUuid, netsuiteRecordId, status: 'created', message: 'bill creation successful', billtype: 'mktpl' }` to results array.
   - From: `goodsRestlets`
   - To: `GLS invoicing service`
   - Protocol: REST (JSON response body)

9. **Async callback (when `custscript_vb_asynchronous = T`)**: Instead of returning results inline, RESTlet immediately returns a `200 OK` acknowledgement and then calls `sendResponse()` to PUT results back to the GLS update URL with `x-client-id`, `x-signature`, and `x-request-time` headers. Retries up to 5 times with 10-second pauses.
   - From: `goodsRestlets`
   - To: GLS invoicing callback URL
   - Protocol: REST (HTTPS PUT, JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing required field (glsPaymentUuid, entity, duedate, etc.) | Appends error entry to results, skips record, continues batch | Partial success — other invoices still processed |
| Vendor not found in NetSuite | Appends error with `"vendor not found in netsuite"`, skips record | Record skipped; caller must retry with correct vendor ID |
| Terms not found in NetSuite | Appends error with `"Terms not found in netsuite"`, skips record | Record skipped |
| Governance units exceeded | Appends `"governance exceeded"` error, halts remaining batch | Partial processing; caller must resubmit unprocessed invoices |
| nlobjError from `nlapiSubmitRecord` | Catches error, appends `"process error: <code>: <detail>"` to results | Record not created; error returned to caller |
| Async callback failure | Retries up to 5 times; logs failure if all retries exhausted | Results not delivered; requires manual investigation |

## Sequence Diagram

```
GLS/SnapLogic -> goodsRestlets: POST invoice batch (JSON array)
goodsRestlets -> goodsRestlets: Check governance headroom
goodsRestlets -> goodsRestlets: Validate required fields per invoice
goodsRestlets -> NetSuite ERP DB: nlapiSearchRecord (terms lookup)
goodsRestlets -> NetSuite ERP DB: nlapiCreateRecord + nlapiSubmitRecord (vendorbill)
NetSuite ERP DB --> goodsUserEventScripts: beforeSubmit (AP account, Coupa tax)
NetSuite ERP DB --> goodsUserEventScripts: afterSubmit (bill numbering, PO bill total)
goodsRestlets --> GLS/SnapLogic: JSON result array [{glsPaymentUuid, netsuiteRecordId, status}]
```

## Related

- Architecture dynamic view: `dynamic-netsuite-integration-flows`
- Related flows: [OTP Export to GLS](otp-export-gls.md)
- See also: [API Surface](../api-surface.md), [Integrations](../integrations.md)
