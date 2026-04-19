---
service: "Netsuite"
title: "JPM ACH Payment Batch Submission"
generated: "2026-03-03"
type: flow
flow_name: "jpm-ach-payment-batch"
flow_type: synchronous
trigger: "Finance user submits selected payment files via JPM Goods ACH Suitelet in GOODS NetSuite instance (NS2)"
participants:
  - "continuumNetsuiteGoodsCustomizations"
  - "goodsRestlets"
  - "snapLogic"
  - "jpmPayments"
architecture_ref: "dynamic-netsuite-integration-flows"
---

# JPM ACH Payment Batch Submission

## Summary

This flow enables finance staff to review staged ACH payment files in the NetSuite File Cabinet and submit a selected batch to JPMorgan Chase for ACH processing. The user opens a Suitelet (`JPM Goods ACH Launch SnapLogic NS2 MP` for Marketplace payments, or `JPM Goods ACH Launch SnapLogic NS2 Trade` for Trade AP payments), reviews the pending payment files with their amounts and transaction counts, selects those to submit, and clicks Submit. NetSuite then triggers a SnapLogic pipeline that picks up the selected files and delivers them to JPMorgan Chase. Separate Suitelets cover Goods Marketplace and Trade payment streams in both US and global variants.

## Trigger

- **Type**: user-action
- **Source**: Finance operations staff in NetSuite GOODS (NS2) — GET to load the Suitelet, POST to submit selected payment files
- **Frequency**: On-demand, typically daily or per payment run cycle

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Finance staff (NetSuite user) | Initiates payment batch submission via Suitelet UI | external (user) |
| NetSuite GOODS Suitelet (`JPM Goods ACH Launch SnapLogic NS2 MP`) | Displays pending files, collects user selection, triggers SnapLogic | `goodsRestlets` |
| NetSuite File Cabinet (folder `195312`) | Stores staged ACH payment files pending submission | `continuumNetsuiteGoodsCustomizations` |
| NetSuite Custom Record `customrecord_2663_file_admin` | Stores per-file metadata: amount, bank account, process date, transaction count, GL amount | `continuumNetsuiteGoodsCustomizations` |
| SnapLogic (`GrouponProd/projects/Banking/JPM NS2 Send to ACH`) | Receives trigger, picks up files, transmits to JPM | `snapLogic` |
| JPMorgan Chase | Receives ACH payment instructions | `jpmPayments` |

## Steps

1. **Finance user opens Suitelet (GET)**: User navigates to the JPM ACH Suitelet in NetSuite. Suitelet responds with a form showing pending payment files from File Cabinet folder `195312`.
   - From: Finance staff (browser)
   - To: `goodsRestlets` (Suitelet GET handler)
   - Protocol: HTTPS (NetSuite UI)

2. **Suitelet queries pending files**: Searches File Cabinet for files in folder `195312` using `nlapiSearchRecord('file', ...)`. For each file, looks up the associated `customrecord_2663_file_admin` record to retrieve batch amount (`custrecord_2663_total_amount`), bank account (`custrecord_2663_bank_account`), process date (`custrecord_2663_process_date`), reference note (`custrecord_2663_ref_note`), transaction count (`custrecord_2663_total_transactions`), file amount (`custrecord_file_amount`), and GL amount (`custrecord_gl_amount`).
   - From: `goodsRestlets`
   - To: NetSuite ERP Database
   - Protocol: `nlapiSearchRecord` (in-process)

3. **Renders payment file table**: Suitelet populates a sublist showing all pending files with columns: File Name, Folder, Batch Number, Date Created, Ref Note, Bank Account, Process Date, Amount, Total Transactions, File Amount, GL Amount. User can select files using checkboxes.
   - From: `goodsRestlets`
   - To: Finance staff (browser)
   - Protocol: HTTPS (NetSuite UI response)

4. **Finance user submits selected files (POST)**: User selects one or more payment files and clicks Submit.
   - From: Finance staff (browser)
   - To: `goodsRestlets` (Suitelet POST handler)
   - Protocol: HTTPS (NetSuite form POST)

5. **Suitelet looks up user email**: Calls `getUserEmail(stUserId)` via `nlapiSearchRecord('employee', ...)` to retrieve the submitting user's email address for notification.
   - From: `goodsRestlets`
   - To: NetSuite ERP Database
   - Protocol: `nlapiSearchRecord` (in-process)

6. **Triggers SnapLogic ACH pipeline**: Sends GET request to `https://elastic.snaplogic.com:443/api/1/rest/slsched/feed/GrouponProd/projects/Banking/JPM%20NS2%20Send%20to%20ACH?Folder=<folderId>&Email=<userEmail>` with `Authorization: Bearer <token>` header. SnapLogic pipeline picks up the files from the specified folder and delivers them to JPMorgan Chase.
   - From: `goodsRestlets`
   - To: `snapLogic`
   - Protocol: REST (HTTPS GET with Bearer token)

7. **SnapLogic processes and sends to JPM**: SnapLogic retrieves files from the NetSuite File Cabinet folder, formats them per JPM ACH specification, and submits to JPMorgan Chase banking infrastructure.
   - From: `snapLogic`
   - To: `jpmPayments`
   - Protocol: ACH file transmission (managed by SnapLogic)

8. **Suitelet displays confirmation**: Renders confirmation form `US ACH MP Files Sent to JPM` to user. Response code and body from SnapLogic are logged via `LOGGER.debug`.
   - From: `goodsRestlets`
   - To: Finance staff (browser)
   - Protocol: HTTPS (NetSuite UI response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No files in pending folder | Sublist renders empty; no Submit action available | User sees empty list; no action taken |
| SnapLogic returns non-200 | Response code and body logged via `LOGGER.debug`; user sees confirmation form regardless | Potential silent failure; requires monitoring of SnapLogic pipeline |
| User not found in employee search | Returns `netsuiteadmin@groupon.com` as fallback email | Pipeline triggered with fallback notification address |
| `customrecord_2663_file_admin` record not found for a file | Batch/amount fields display empty for that file | User must investigate file admin record before submitting |

## Sequence Diagram

```
Finance staff -> goodsRestlets: GET Suitelet (load pending files)
goodsRestlets -> NetSuite ERP DB: Search File Cabinet folder 195312
goodsRestlets -> NetSuite ERP DB: Search customrecord_2663_file_admin per file
goodsRestlets --> Finance staff: Render payment file table with amounts and counts
Finance staff -> goodsRestlets: POST (submit selected files)
goodsRestlets -> NetSuite ERP DB: Look up user email (employee search)
goodsRestlets -> snapLogic: GET trigger URL (?Folder=195312&Email=<user>)
snapLogic -> jpmPayments: Deliver ACH files
jpmPayments --> snapLogic: ACH acknowledgement
snapLogic --> goodsRestlets: HTTP 200 (pipeline triggered)
goodsRestlets --> Finance staff: Confirmation form
```

## Related

- Architecture dynamic view: `dynamic-netsuite-integration-flows`
- Related flows: [Kyriba Treasury File Exchange](kyriba-treasury-exchange.md)
- See also: [Integrations](../integrations.md) — JPMorgan Chase and SnapLogic details
