---
service: "getaways-payment-reconciliation"
title: "EAN Invoice Email Import"
generated: "2026-03-03"
type: flow
flow_name: "ean-invoice-email-import"
flow_type: scheduled
trigger: "Email reader worker timer (workerPeriod interval)"
participants:
  - "emailReaderScriptExecutor"
  - "invoiceImporterScript"
  - "gmailImap_unk_7e3a"
  - "gmailSmtp_unk_7e3a"
  - "jdbiDaos"
  - "continuumGetawaysPaymentReconciliationDb"
architecture_ref: "components-getaways-payment-reconciliation-components"
---

# EAN Invoice Email Import

## Summary

This scheduled flow automates the ingestion of EAN (Expedia Affiliate Network) invoice files into the reconciliation database. The Email Reader Script Executor fires on a configurable timer and launches the Python Invoice Importer Script, which authenticates to Gmail via OAuth2, searches the inbox for unprocessed invoice emails, downloads CSV/Excel attachments, converts them to a standard delimited format, bulk-loads the rows into the `travel_ean_invoice` MySQL table, and records the run outcome in `invoice_importer_status`. An email notification is sent to the operations team regardless of success or failure.

## Trigger

- **Type**: schedule
- **Source**: `emailReaderScriptExecutor` Java component, fired on `workerPeriod` interval (configured in JTier YAML)
- **Frequency**: Periodic; configured via `workerInitialDelay` and `workerPeriod` fields in service configuration

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Email Reader Script Executor | Schedules and launches the Python script | `emailReaderScriptExecutor` |
| Invoice Importer Script | Performs all Gmail interaction, file processing, and DB loading | `invoiceImporterScript` |
| Gmail IMAP | Source of invoice email attachments | `gmailImap_unk_7e3a` |
| Gmail SMTP | Destination for import outcome notification email | `gmailSmtp_unk_7e3a` |
| JDBI DAOs / MySQL | Persistent store for invoice data and import status | `jdbiDaos` / `continuumGetawaysPaymentReconciliationDb` |

## Steps

1. **Schedule fires**: `emailReaderScriptExecutor` determines the timer has elapsed and invokes the Python `InvoiceImporter.py` script with the config YAML path.
   - From: `emailReaderScriptExecutor`
   - To: `invoiceImporterScript`
   - Protocol: process exec

2. **Parse config**: Script reads the YAML config secret file to extract Gmail OAuth2 credentials, attachment filters, and MySQL connection parameters.
   - From: `invoiceImporterScript`
   - To: config YAML (filesystem)
   - Protocol: file read

3. **Refresh OAuth2 token**: Script calls `https://accounts.google.com/o/oauth2/token` with `client_id`, `client_secret`, and `refresh_token` to obtain a fresh access token.
   - From: `invoiceImporterScript`
   - To: Google Accounts API
   - Protocol: HTTPS POST

4. **Connect to Gmail IMAP and search**: Script opens `imap.gmail.com:993` (SSL), authenticates with XOAUTH2, and searches the Inbox for emails matching `email_filter_message` (without the `label_process` label).
   - From: `invoiceImporterScript`
   - To: `gmailImap_unk_7e3a`
   - Protocol: IMAP4/SSL

5. **Download attachment**: For each matching email, fetches the message body, identifies attachments matching `attachment_regex`, saves them to `attach_dir`, and labels the email with `label_process` to prevent reprocessing.
   - From: `invoiceImporterScript`
   - To: `gmailImap_unk_7e3a`
   - Protocol: IMAP4/SSL

6. **Convert invoice file**: Calls `process_invoice_file_by_format` (FileUtils) to parse the CSV/Excel file and convert it to the expected delimited format.
   - From: `invoiceImporterScript`
   - To: filesystem
   - Protocol: file I/O

7. **Bulk-load into MySQL**: Executes `LOAD DATA LOCAL INFILE` against `travel_ean_invoice` table, mapping all EAN invoice fields. Returns inserted row count.
   - From: `invoiceImporterScript`
   - To: `continuumGetawaysPaymentReconciliationDb`
   - Protocol: MySQL

8. **Update import status**: Upserts a row in `invoice_importer_status` with the invoice date and `SUCCESS` or `FAILURE` status based on whether expected row count matches actual.
   - From: `invoiceImporterScript`
   - To: `continuumGetawaysPaymentReconciliationDb`
   - Protocol: MySQL

9. **Send outcome email**: Calls `SendEmail` via `smtp.gmail.com:587` (STARTTLS, XOAUTH2) to deliver a SUCCESS/FAILURE summary to the configured `to_email`.
   - From: `invoiceImporterScript`
   - To: `gmailSmtp_unk_7e3a`
   - Protocol: SMTP/STARTTLS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| OAuth2 token refresh fails | Script exits with code 1; logs error | No import; no DB update; `invoice_importer_status` not updated |
| No matching email found | Script exits with code 0 (not an error) | No import; no DB update |
| Attachment download fails | Script exits with code 1 | `invoice_importer_status` updated to FAILURE |
| File format conversion error | Script calls `report_failure_status`; exits | `invoice_importer_status` updated to FAILURE |
| Row count mismatch after bulk load | Script calls `report_failure_status`; exits | `invoice_importer_status` updated to FAILURE |
| MySQL bulk load exception | Script calls `report_failure_status`; exits | `invoice_importer_status` updated to FAILURE |
| SMTP send failure | Exception logged; script still exits with original status code | Notification not sent; DB status already recorded |

## Sequence Diagram

```
emailReaderScriptExecutor -> invoiceImporterScript: exec InvoiceImporter.py <config_yaml>
invoiceImporterScript -> GoogleAccountsAPI: POST /o/oauth2/token (refresh token)
GoogleAccountsAPI --> invoiceImporterScript: access_token
invoiceImporterScript -> gmailImap: IMAP4 SSL connect + XOAUTH2 authenticate
invoiceImporterScript -> gmailImap: SEARCH Inbox (email_filter_message)
gmailImap --> invoiceImporterScript: email IDs
invoiceImporterScript -> gmailImap: FETCH email + STORE label_process
gmailImap --> invoiceImporterScript: attachment file
invoiceImporterScript -> FileUtils: process_invoice_file_by_format(attach_dir, csv_file)
FileUtils --> invoiceImporterScript: (file_name, row_count, converted_path)
invoiceImporterScript -> MySQLDB: LOAD DATA LOCAL INFILE travel_ean_invoice
MySQLDB --> invoiceImporterScript: rows_inserted
invoiceImporterScript -> MySQLDB: UPSERT invoice_importer_status (SUCCESS/FAILURE)
invoiceImporterScript -> gmailSmtp: SMTP STARTTLS + XOAUTH2 send outcome email
```

## Related

- Architecture dynamic view: `components-getaways-payment-reconciliation-components`
- Related flows: [Scheduled Reconciliation Worker](scheduled-reconciliation-worker.md)
