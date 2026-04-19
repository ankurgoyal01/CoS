---
service: "coupons-revproc"
title: "AffJet Scheduled Ingestion"
generated: "2026-03-03"
type: flow
flow_name: "affjet-scheduled-ingestion"
flow_type: scheduled
trigger: "Quartz cron job fires per country/network variant on a configurable schedule"
participants:
  - "continuumCouponsRevprocService"
  - "revproc_affJetIngestion"
  - "revproc_transactionProcessor"
  - "continuumCouponsRevprocDatabase"
architecture_ref: "dynamic-coupons-revproc-affjet-ingestion"
---

# AffJet Scheduled Ingestion

## Summary

The AffJet Scheduled Ingestion flow is the primary data acquisition path for coupons-revproc. Quartz cron jobs fire independently for each of 19 country/network variants (US, GB, AU, DE, ES, FR, IT, NL, PL, IE, VC_GB, VC_AU, VC_BR, VC_DE, VC_FR, VC_IE, VC_NL, WL_GB, WL_IE). Each job uses `AffJetAdapter` to build a date range query (defaulting to a 30-day lookback window) and pages through the AffJet API until all available transactions are retrieved. Retrieved transactions are passed to `AffJetIngestionService`, which creates `UnprocessedTransaction` records in MySQL for subsequent processing by `TransactionProcessor`.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler (configured in `quartz` block of JTIER_RUN_CONFIG YAML)
- **Frequency**: Per country — schedule is configurable per job in the Quartz config; the default lookback is 30 days back to 2 days ago

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Quartz Scheduler | Fires per-country ingestion jobs on schedule | `continuumCouponsRevprocService` |
| AffJet Adapter (`revproc_affJetIngestion`) | Builds date range, pages through AffJet API, delegates to ingestion service | `revproc_affJetIngestion` |
| AffJet API | External source of affiliate transaction data | External (not in federated model) |
| AffJet Ingestion Service | Converts raw AffJet transactions to `UnprocessedTransaction` records | `revproc_affJetIngestion` |
| MySQL | Stores unprocessed transactions for downstream processing | `continuumCouponsRevprocDatabase` |

## Steps

1. **Quartz job fires**: The Quartz scheduler triggers a per-country `AffJetXXIngestionJob` (e.g., `AffJetUSIngestionJob`, `AffJetGBIngestionJob`).
   - From: `Quartz Scheduler`
   - To: `AffJetAdapter`
   - Protocol: Direct (Quartz job execution)

2. **Build date range**: `AffJetAdapter.process()` constructs an `AffJetRequest` with `lastUpdateFrom` = start of 2 days ago, `dateTo` = start of 2 days ago, `dateFrom` = 30 days ago. Date format is `yyyyMMddHHmmss`.
   - From: `AffJetAdapter`
   - To: Internal date computation
   - Protocol: Direct

3. **Generate date list**: `createDatesForRange` expands the date range into a list of individual dates (newest-first) to iterate over.
   - From: `AffJetAdapter`
   - To: Internal
   - Protocol: Direct

4. **Fetch transactions page**: For each date, `AffJetService.getTransactionsForDate(date, pageIndex)` calls the AffJet REST API for that date and page.
   - From: `revproc_affJetIngestion`
   - To: AffJet API
   - Protocol: HTTPS (Retrofit2)

5. **Page until empty**: Increments `pageIndex` and repeats the API call until the returned transaction list is empty. Each non-empty page increments the `transaction/page_ingest` metric counter.
   - From: `revproc_affJetIngestion`
   - To: AffJet API
   - Protocol: HTTPS

6. **Ingest transaction batch**: `AffJetIngestionService.ingest(transactionList, countryCode)` converts the raw `AffJetTransaction` DTOs into `UnprocessedTransaction` records and writes them to MySQL.
   - From: `revproc_affJetIngestion`
   - To: `continuumCouponsRevprocDatabase`
   - Protocol: JDBC

7. **Process unprocessed transactions**: After ingestion, the `TransactionProcessor` picks up the unprocessed transactions (this may happen inline or as a subsequent step depending on the processor implementation).
   - From: `revproc_transactionProcessor`
   - To: `continuumCouponsRevprocDatabase`
   - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AffJet API returns error or times out | `AffJetAdapter.process()` catches exception, logs `AffJetAdapter.process.failed` error with countryCode and returns 0 | Job marked as failed in Quartz; retried on next scheduled run; no transactions written for failed pages |
| Empty page returned | Pagination loop exits (`do...while (!transactionList.isEmpty())`) | Normal termination; moves to next date |
| MySQL write failure | Exception propagates from `AffJetIngestionService` | Logged; Quartz marks job as failed |

## Sequence Diagram

```
QuartzScheduler -> AffJetXXIngestionJob: fire (per country schedule)
AffJetXXIngestionJob -> AffJetAdapter: process()
AffJetAdapter -> AffJetAdapter: buildDateRange(30 days ago to 2 days ago)
loop for each date
  loop until empty page
    AffJetAdapter -> AffJetAPI: getTransactionsForDate(date, pageIndex) HTTPS
    AffJetAPI --> AffJetAdapter: List<AffJetTransaction>
    AffJetAdapter -> AffJetIngestionService: ingest(transactions, countryCode)
    AffJetIngestionService -> MySQL: INSERT unprocessed_transactions JDBC
  end
end
AffJetAdapter --> QuartzScheduler: return (success=1 / failure=0)
```

## Related

- Architecture dynamic view: `dynamic-coupons-revproc-affjet-ingestion`
- Related flows: [Transaction Processing and Finalization](transaction-processing-finalization.md), [Manual AffJet Ingestion Trigger](manual-affjet-ingestion.md)
