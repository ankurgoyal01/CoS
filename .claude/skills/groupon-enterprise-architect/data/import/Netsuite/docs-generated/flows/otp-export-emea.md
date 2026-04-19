---
service: "Netsuite"
title: "OTP Export to PO Manager (EMEA)"
generated: "2026-03-03"
type: flow
flow_name: "otp-export-emea"
flow_type: scheduled
trigger: "Timed scheduled script execution (GG_emea_sched_push_otp_pomgr) in GOODS NetSuite instance (NS2)"
participants:
  - "continuumNetsuiteGoodsCustomizations"
  - "goodsScheduledScripts"
architecture_ref: "dynamic-netsuite-integration-flows"
---

# OTP Export to PO Manager (EMEA)

## Summary

This flow exports EMEA Order-to-Pay (OTP) purchase orders from the GOODS NetSuite instance (NS2) to the PO Manager EMEA system via a scheduled script (`GG_emea_sched_push_otp_pomgr`). It operates identically in structure to the [GLS OTP export flow](otp-export-gls.md) but targets EMEA purchase orders (with `tranid startswith PO_EMGG0`), uses fulfillment methods 1, 3, 4, and 6, and delivers to the PO Manager EMEA URL using EMEA-specific credentials (`emea_clientid`, `emea_xsig`). It uses the same `customrecord_poes_auto_ctrl` control record pattern (internal ID 6 for EMEA OTP) for state management.

## Trigger

- **Type**: schedule
- **Source**: NetSuite Scheduled Script Deployment (`GG_emea_sched_push_otp_pomgr`) — runs on a timed interval configured in the Script Deployment record
- **Frequency**: Periodic (interval configured in NetSuite deployment; script self-reschedules for large batches)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| NetSuite GOODS Scheduled Script (`GG_emea_sched_push_otp_pomgr`) | Queries EMEA POs, builds JSON, sends to PO Manager | `goodsScheduledScripts` |
| NetSuite ERP Database | Source of EMEA purchase order data | `continuumNetsuiteGoodsCustomizations` |
| NetSuite File Cabinet | Staging area for JSON export files | `continuumNetsuiteGoodsCustomizations` |
| PO Manager EMEA | Receives EMEA OTP purchase order data | external |

## Steps

1. **Checks for concurrent execution**: Reads `customrecord_poes_auto_ctrl` (internal ID `6`) to check `custrecord_poes_auto_ctrl_running_chk`. If running and elapsed time since last success is less than `custscript_push_emea_running_reset` minutes, terminates early.
   - From: `goodsScheduledScripts`
   - To: NetSuite ERP Database
   - Protocol: `nlapiSearchRecord` (in-process)

2. **Marks script as running**: Sets `custrecord_poes_auto_ctrl_running_chk = T`.
   - From: `goodsScheduledScripts`
   - To: NetSuite ERP Database
   - Protocol: `nlapiSubmitField` (in-process)

3. **Queries modified EMEA purchase orders**: Searches `purchaseorder` records with filters:
   - `lastmodifieddate onorafter <last run date>`
   - `datecreated onorafter 4/1/2015`
   - `customform anyof [121, 110]` (EMEA OTP forms)
   - `tranid startswith PO_EMGG0` (EMEA GOODS naming convention)
   - `custbody_po_sf_fulfillment_method anyof [1, 3, 4, 6]`
   - `LENGTH(tranid) < 23` (excludes child POs with old naming convention)
   - `mainline = T`
   - From: `goodsScheduledScripts`
   - To: NetSuite ERP Database
   - Protocol: `nlapiCreateSearch` / `runSearch` (in-process)

4. **Builds purchase order objects**: For each PO, constructs a `purchaseOrdersObject` containing `po`, `vendor`, and `items` arrays. Includes EMEA-specific fields: `custbodyPoSfNsEsStatus` (NS-ES status). Exchange rate used to convert item rates from functional currency to foreign currency. PO type set to `OTP` for fulfillment methods 2 and 6.
   - From: `goodsScheduledScripts`
   - To: NetSuite ERP Database (secondary item search per PO)
   - Protocol: `nlapiCreateSearch` per PO (in-process)

5. **Checks batch size and splits if needed**: If accumulated JSON size exceeds `custscript_push_emea_max_kb_to_send * 1024` characters, flushes current batch to file and sends before continuing.
   - From: `goodsScheduledScripts`
   - To: NetSuite File Cabinet
   - Protocol: `nlapiCreateFile` / `nlapiSubmitFile` (in-process)

6. **Writes JSON to File Cabinet**: Creates a flat file named `<timestamp>_POmgr_EMEA_otp_json.txt` in folder `custscript_push_emea_save_folder`.
   - From: `goodsScheduledScripts`
   - To: NetSuite File Cabinet
   - Protocol: `nlapiCreateFile` / `nlapiSubmitFile` (in-process)

7. **POSTs JSON to PO Manager EMEA**: Sends payload to `EMEAurl` (from `getPOmgrCredentials()`) with `Content-Type: application/json`, `x-client-id: emea_clientid`, `x-signature: emea_xsig` headers. Retries up to 5 times with 10-second pauses.
   - From: `goodsScheduledScripts`
   - To: PO Manager EMEA
   - Protocol: REST (HTTPS POST, JSON)

8. **Updates control record on success**: Updates `custrecord_poes_auto_ctrl_last_success` and `custrecord_poes_auto_ctrl_last_modified`.
   - From: `goodsScheduledScripts`
   - To: NetSuite ERP Database
   - Protocol: `nlapiSubmitField` (in-process)

9. **Governance and time limit management**: Calls `reschedScript(MAX_USAGE=500)` and `checkScriptTime(startTime, 45)` at each iteration. Self-reschedules before hitting limits.
   - From: `goodsScheduledScripts`
   - To: NetSuite platform
   - Protocol: in-process

10. **Marks script as complete**: Sets `custrecord_poes_auto_ctrl_running_chk = F`.
    - From: `goodsScheduledScripts`
    - To: NetSuite ERP Database
    - Protocol: `nlapiSubmitField` (in-process)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Previous run still active (under reset threshold) | Script terminates early | No duplicate processing |
| PO Manager EMEA endpoint returns non-200 | Retries up to 5 times; resets running flag to F and terminates after max retries | Processing halted; manual investigation required |
| Governance units exhausted | `reschedScript(500)` yields and reschedules | Processing continues in new execution |
| Script exceeds 45 minutes | `checkScriptTime` triggers self-reschedule | Resumes in next execution |
| nlobjError | Caught, logged, rethrown | Script fails; error in execution log |

## Sequence Diagram

```
NetSuite Scheduler -> goodsScheduledScripts: Trigger sendData()
goodsScheduledScripts -> NetSuite ERP DB: Read customrecord_poes_auto_ctrl (ID=6, running check)
goodsScheduledScripts -> NetSuite ERP DB: Set running_chk = T
goodsScheduledScripts -> NetSuite ERP DB: Search purchaseorder EMEA (customform 121/110, tranid PO_EMGG0)
goodsScheduledScripts -> NetSuite ERP DB: Search purchaseorder line items (per PO)
goodsScheduledScripts -> NetSuite File Cabinet: Write JSON file (<timestamp>_POmgr_EMEA_otp_json.txt)
goodsScheduledScripts -> PO Manager EMEA: POST purchaseOrders JSON (x-client-id, x-signature)
PO Manager EMEA --> goodsScheduledScripts: HTTP 200 OK
goodsScheduledScripts -> NetSuite ERP DB: Update customrecord_poes_auto_ctrl timestamps
goodsScheduledScripts -> NetSuite ERP DB: Set running_chk = F
```

## Related

- Architecture dynamic view: `dynamic-netsuite-integration-flows`
- Related flows: [OTP Export to GLS](otp-export-gls.md)
- See also: [Configuration](../configuration.md) for `custscript_push_emea_*` parameters
