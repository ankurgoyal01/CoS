---
service: "Netsuite"
title: "OTP Export to GLS (Drop-Ship)"
generated: "2026-03-03"
type: flow
flow_name: "otp-export-gls"
flow_type: scheduled
trigger: "Timed scheduled script execution (GG_sched_push_ds_otp_gls) in GOODS NetSuite instance (NS2)"
participants:
  - "continuumNetsuiteGoodsCustomizations"
  - "goodsScheduledScripts"
architecture_ref: "dynamic-netsuite-integration-flows"
---

# OTP Export to GLS (Drop-Ship)

## Summary

This flow exports Drop-Ship Order-to-Pay (OTP) purchase orders from the GOODS NetSuite instance (NS2) to the GLS (Groupon Logistics Service / invoicing service) via a scheduled script. The script queries purchase orders modified since its last successful run, serializes them to JSON (including PO header, vendor details, and line items), and POSTs the payload to the GLS callback URL. It uses a `customrecord_poes_auto_ctrl` control record (type 4 = OTP DS) to track state across runs and support rescheduling within NetSuite's 60-minute execution limit.

## Trigger

- **Type**: schedule
- **Source**: NetSuite Scheduled Script Deployment (`GG_sched_push_ds_otp_gls`) — runs on a timed interval configured in the Script Deployment record
- **Frequency**: Periodic (interval configured in NetSuite deployment; script self-reschedules for large batches)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| NetSuite GOODS Scheduled Script (`GG_sched_push_ds_otp_gls`) | Queries POs, builds JSON, sends to GLS | `goodsScheduledScripts` |
| NetSuite ERP Database | Source of purchase order data | `continuumNetsuiteGoodsCustomizations` |
| NetSuite File Cabinet | Staging area for JSON export files | `continuumNetsuiteGoodsCustomizations` |
| GLS invoicing service | Receives OTP purchase order data | external |

## Steps

1. **Checks for concurrent execution**: Reads `customrecord_poes_auto_ctrl` (type 4) to determine if a previous run is still active (`custrecord_poes_auto_ctrl_running_chk = T`). If running and elapsed time since last success is less than `custscript_push_gls_otp_running_reset` minutes, terminates early.
   - From: `goodsScheduledScripts`
   - To: NetSuite ERP Database
   - Protocol: `nlapiSearchRecord` (in-process)

2. **Marks script as running**: Sets `custrecord_poes_auto_ctrl_running_chk = T` on the control record to prevent concurrent execution.
   - From: `goodsScheduledScripts`
   - To: NetSuite ERP Database
   - Protocol: `nlapiSubmitField` (in-process)

3. **Reads control timestamps**: Retrieves `custrecord_poes_auto_ctrl_last_modified` (used as query start date) and records new run date.
   - From: `goodsScheduledScripts`
   - To: NetSuite ERP Database
   - Protocol: `nlapiSearchRecord` (in-process)

4. **Queries modified purchase orders**: Searches `purchaseorder` records with filters:
   - `lastmodifieddate onorafter <last run date>`
   - `customform anyof [101, 120]` (OTP forms)
   - `tranid startswith PO_USGG0` (Goods US Drop-Ship naming convention)
   - `mainline = T`
   - From: `goodsScheduledScripts`
   - To: NetSuite ERP Database
   - Protocol: `nlapiCreateSearch` / `runSearch` (in-process)

5. **Builds purchase order objects**: For each PO result, constructs a `purchaseOrdersObject` containing:
   - `po` object: `tranId`, `internalId`, `poType` (OTP for fulfillment methods 3/4), `poStatus`, `requestType` (New/Update/Cancel), Salesforce opportunity fields, warehouse fields, freight/fulfillment fields, exchange rate
   - `vendor` object: company name, legal name, address, phone
   - `items` array: line items with item ID, catalog ID, description, dimensions, weight, quantity, rate (converted from functional to foreign currency using exchange rate), VAT rate/code, shipping rate, gross unit price
   - From: `goodsScheduledScripts`
   - To: NetSuite ERP Database (secondary item search per PO)
   - Protocol: `nlapiCreateSearch` per PO (in-process)

6. **Checks batch size limits**: If accumulated JSON character count exceeds `custscript_push_gls_otp_max_kb_to_send * 1024`, splits the current batch, writes a file, and sends before continuing.
   - From: `goodsScheduledScripts`
   - To: NetSuite File Cabinet
   - Protocol: `nlapiCreateFile` / `nlapiSubmitFile` (in-process)

7. **Writes JSON to File Cabinet**: Creates a flat text file named `<timestamp>_GLS_otp_json.txt` containing the serialized `purchaseOrders` JSON and saves it to the folder configured in `custscript_push_gls_otp_save_folder`.
   - From: `goodsScheduledScripts`
   - To: NetSuite File Cabinet
   - Protocol: `nlapiCreateFile` / `nlapiSubmitFile` (in-process)

8. **POSTs JSON to GLS**: Sends the JSON payload to the GLS callback URL (`urlBackfill` from `getGLSCredentials()`) with `Content-Type: application/json`, `clientId`, and `Message-Key` (MD5 of char count) headers. Retries up to 5 times with 10-second pauses between attempts.
   - From: `goodsScheduledScripts`
   - To: GLS invoicing service
   - Protocol: REST (HTTPS POST, JSON)

9. **Updates control record on success**: Updates `custrecord_poes_auto_ctrl_last_success` and `custrecord_poes_auto_ctrl_last_modified` with the new run timestamps.
   - From: `goodsScheduledScripts`
   - To: NetSuite ERP Database
   - Protocol: `nlapiSubmitField` (in-process)

10. **Checks time limit and reschedules if needed**: Calls `checkScriptTime(startTime, 45)` at each iteration. If execution time approaches 45 minutes, reschedules the script and terminates the current run.
    - From: `goodsScheduledScripts`
    - To: NetSuite platform
    - Protocol: `nlapiScheduleScript` (in-process)

11. **Marks script as complete**: Sets `custrecord_poes_auto_ctrl_running_chk = F` on completion.
    - From: `goodsScheduledScripts`
    - To: NetSuite ERP Database
    - Protocol: `nlapiSubmitField` (in-process)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Previous run still active (under reset threshold) | Script terminates early without processing | No duplicate processing; next schedule attempt will check again |
| GLS endpoint returns non-200 | Retries up to 5 times with 10-second pause | After 5 failures, sets running flag to F, sets `terminate = true`, exits |
| NetSuite governance units low | `reschedScript(MAX_USAGE=500)` yields and reschedules script | Processing continues in new execution instance |
| Script exceeds 45 minutes | `checkScriptTime` triggers self-reschedule | Processing resumes from last saved position in next execution |
| nlobjError from search/submit | Caught, logged via `nlapiLogExecution('ERROR', ...)`, rethrown | Script fails with error log entry; requires manual investigation |

## Sequence Diagram

```
NetSuite Scheduler -> goodsScheduledScripts: Trigger sendData()
goodsScheduledScripts -> NetSuite ERP DB: Read customrecord_poes_auto_ctrl (running check)
goodsScheduledScripts -> NetSuite ERP DB: Set running_chk = T
goodsScheduledScripts -> NetSuite ERP DB: Search purchaseorder (modified since last run)
goodsScheduledScripts -> NetSuite ERP DB: Search purchaseorder line items (per PO)
goodsScheduledScripts -> NetSuite File Cabinet: Write JSON file (<timestamp>_GLS_otp_json.txt)
goodsScheduledScripts -> GLS invoicing service: POST purchaseOrders JSON
GLS invoicing service --> goodsScheduledScripts: HTTP 200 OK
goodsScheduledScripts -> NetSuite ERP DB: Update customrecord_poes_auto_ctrl timestamps
goodsScheduledScripts -> NetSuite ERP DB: Set running_chk = F
```

## Related

- Architecture dynamic view: `dynamic-netsuite-integration-flows`
- Related flows: [OTP Export to PO Manager (EMEA)](otp-export-emea.md), [Vendor Bill Creation](vendor-bill-creation.md)
- See also: [Configuration](../configuration.md) for `custscript_push_gls_otp_*` parameters
