---
service: "clo-service"
title: "Card Network File Transfer and Settlement"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "card-network-file-transfer-settlement"
flow_type: batch
trigger: "FileTransfer event from Message Bus or scheduled batch job"
participants:
  - "continuumCloServiceWorker"
  - "cloWorkerMessageConsumers"
  - "cloWorkerAsyncJobs"
  - "cloWorkerPartnerProcessors"
  - "continuumCloServicePostgres"
  - "continuumCloServiceRedis"
  - "messageBus"
architecture_ref: "components-clo-service-worker"
---

# Card Network File Transfer and Settlement

## Summary

Visa and Mastercard use file-based protocols to deliver settlement records and initiate bulk statement credit operations. CLO Service receives notification of available files via `FileTransfer` events on Message Bus, then processes these files through network-specific batch processors. Processed settlement records are reconciled against claim records in PostgreSQL and statement credit outcomes are written back. This flow is a critical SOX in-scope financial reconciliation path.

## Trigger

- **Type**: event (Message Bus) or schedule
- **Source**: `FileTransfer` event on Message Bus signalling that a card network settlement file is ready for processing; or a scheduled batch job that polls for pending files
- **Frequency**: Batch (typically daily or per-network settlement cycle)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CLO Service Worker | Processes file transfer notifications and batch settlement | `continuumCloServiceWorker` |
| Message Consumers | Receives FileTransfer events | `cloWorkerMessageConsumers` |
| Async Job Processors | Orchestrates file retrieval and processing jobs | `cloWorkerAsyncJobs` |
| Partner Processors | Implements network-specific file parsing and settlement logic | `cloWorkerPartnerProcessors` |
| CLO Service PostgreSQL | Stores settlement records and updates claim state | `continuumCloServicePostgres` |
| CLO Service Redis | Job queue for batch processing steps | `continuumCloServiceRedis` |
| Message Bus | Delivers FileTransfer events | `messageBus` |

## Steps

1. **Receives file transfer notification**: `cloWorkerMessageConsumers` receives a `FileTransfer` event from Message Bus indicating a settlement or statement credit file is available from a card network.
   - From: `messageBus`
   - To: `cloWorkerMessageConsumers`
   - Protocol: Message Bus

2. **Dispatches file processing job**: `cloWorkerMessageConsumers` dispatches the file processing task to `cloWorkerAsyncJobs` with file metadata (network, file location, type).
   - From: `cloWorkerMessageConsumers`
   - To: `cloWorkerAsyncJobs`
   - Protocol: Direct (Sidekiq)

3. **Delegates to partner processor**: `cloWorkerAsyncJobs` delegates to the appropriate `cloWorkerPartnerProcessors` implementation (Visa or Mastercard) for network-specific file retrieval and parsing.
   - From: `cloWorkerAsyncJobs`
   - To: `cloWorkerPartnerProcessors`
   - Protocol: Direct

4. **Retrieves settlement file**: `cloWorkerPartnerProcessors` retrieves the file from the card network via SFTP or the network's file delivery API.
   - From: `cloWorkerPartnerProcessors`
   - To: Card network file delivery endpoint (Visa or Mastercard)
   - Protocol: SFTP / REST (file-based)

5. **Parses and validates file records**: `cloWorkerPartnerProcessors` parses the file format (CSV, fixed-width, or network-specific format) and validates each settlement record.
   - From: `cloWorkerPartnerProcessors`
   - To: (internal processing)
   - Protocol: Direct

6. **Reconciles records against claims**: `cloWorkerAsyncJobs` queries `continuumCloServicePostgres` to match each settlement record to an existing claim by transaction id or card token/merchant/amount.
   - From: `cloWorkerAsyncJobs`
   - To: `continuumCloServicePostgres`
   - Protocol: ActiveRecord / SQL

7. **Updates claim and statement credit state**: For each matched record, `cloWorkerAsyncJobs` transitions claim state and creates or updates the statement credit record in `continuumCloServicePostgres`.
   - From: `cloWorkerAsyncJobs`
   - To: `continuumCloServicePostgres`
   - Protocol: ActiveRecord / SQL

8. **Publishes settlement outcome events**: `cloWorkerAsyncJobs` publishes `clo.claims` status update events to Message Bus for downstream consumers (e.g., Orders Service, reporting).
   - From: `cloWorkerAsyncJobs`
   - To: `messageBus`
   - Protocol: Message Bus

9. **Acknowledges file processing completion**: `cloWorkerPartnerProcessors` records file processing completion (e.g., moves file to processed location or sends acknowledgement to card network if required).
   - From: `cloWorkerPartnerProcessors`
   - To: Card network / internal state
   - Protocol: SFTP / REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| File unavailable on retrieval | Sidekiq retry with backoff | Processing delayed; alert on repeated failure |
| File parse error (malformed record) | Skip malformed record; log; continue batch | Partial settlement processed; alert for manual review |
| No matching claim found for settlement record | Log unmatched record; write to reconciliation exceptions table | Manual reconciliation required |
| Database transaction failure during update | Rollback; Sidekiq retry | No partial state; batch retried cleanly |
| Duplicate file processing | Idempotency check on file identifier or record ids | Duplicate records not created |

## Sequence Diagram

```
messageBus -> cloWorkerMessageConsumers: FileTransfer event (Mastercard settlement)
cloWorkerMessageConsumers -> cloWorkerAsyncJobs: dispatch file processing job
cloWorkerAsyncJobs -> cloWorkerPartnerProcessors: delegate to Mastercard processor
cloWorkerPartnerProcessors -> MastercardFileEndpoint: retrieve settlement file (SFTP)
MastercardFileEndpoint --> cloWorkerPartnerProcessors: settlement file
cloWorkerPartnerProcessors -> cloWorkerPartnerProcessors: parse and validate records
cloWorkerAsyncJobs -> continuumCloServicePostgres: reconcile records against claims
continuumCloServicePostgres --> cloWorkerAsyncJobs: matched claims
cloWorkerAsyncJobs -> continuumCloServicePostgres: update claim and statement credit state
cloWorkerAsyncJobs -> messageBus: publish clo.claims settlement events
cloWorkerPartnerProcessors -> MastercardFileEndpoint: acknowledge file processed
```

## Related

- Architecture dynamic view: `dynamic-clo-claim-processing`
- Related flows: [Claim Processing and Statement Credit](claim-processing-statement-credit.md), [Scheduled Health Reporting](scheduled-health-reporting.md)
