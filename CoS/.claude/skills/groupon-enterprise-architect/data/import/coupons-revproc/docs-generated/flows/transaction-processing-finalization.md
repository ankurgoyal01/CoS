---
service: "coupons-revproc"
title: "Transaction Processing and Finalization"
generated: "2026-03-03"
type: flow
flow_name: "transaction-processing-finalization"
flow_type: synchronous
trigger: "Each UnprocessedTransaction record after AffJet ingestion or HTTP submission"
participants:
  - "continuumCouponsRevprocService"
  - "revproc_transactionProcessor"
  - "revproc_finalizer"
  - "revproc_clickService"
  - "revproc_voucherCloudClient"
  - "continuumCouponsRevprocDatabase"
  - "messageBus"
architecture_ref: "dynamic-coupons-revproc-transaction-processing"
---

# Transaction Processing and Finalization

## Summary

Transaction Processing and Finalization is the core revenue processing flow of coupons-revproc. For each `UnprocessedTransaction`, `TransactionProcessor` validates and enriches the record by optionally fetching click details from the VoucherCloud API, deduplicates against existing revenue records, resolves the merchant slug, and then delegates to `ProcessedTransactionFinalizer`. The finalizer standardizes the merchant slug, inserts the processed transaction into MySQL, and — for qualifying core coupon transactions — publishes a paired `click` and `redemption` message to the Groupon message bus (Mbus). Non-core-coupon transactions or those lacking a deal UUID or bcookie are persisted without Mbus messages.

## Trigger

- **Type**: per-record invocation
- **Source**: `AffJetIngestionService` after AffJet poll, or HTTP POST to `/unprocessed_transactions/trigger_affjet_ingestion`
- **Frequency**: Per transaction; approximately 100 RPM at steady state

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Transaction Processor | Orchestrates validation, enrichment, and deduplication | `revproc_transactionProcessor` |
| Click Service | Fetches click details from VoucherCloud for a given clickId | `revproc_clickService` |
| VoucherCloud API Client | HTTP client for VoucherCloud click endpoint | `revproc_voucherCloudClient` |
| VoucherCloud API | External source of click, merchant, deal enrichment data | `voucherCloudApi` |
| Merchant Slug Mapping Manager | Resolves and updates the canonical merchant slug for the transaction | `revproc_transactionProcessor` |
| MySQL (processed_transactions) | Persists the final processed transaction record | `continuumCouponsRevprocDatabase` |
| Processed Transaction Finalizer | Standardizes slug, inserts to DB, and sends Mbus messages | `revproc_finalizer` |
| Message Bus Client | Publishes click and redemption messages to Mbus | `revproc_messageBusClient` |
| Mbus | Receives and delivers click/redemption messages to downstream consumers | `messageBus` |

## Steps

1. **Receive unprocessed transaction**: `TransactionProcessor.process(unprocessedTransaction)` is invoked. Emits `transaction/process` metric counter.
   - From: `AffJetIngestionService` or HTTP resource
   - To: `revproc_transactionProcessor`
   - Protocol: Direct

2. **Apply default country code**: If the transaction has a blank country code, it is defaulted to `"US"`.
   - From: `revproc_transactionProcessor`
   - To: Internal
   - Protocol: Direct

3. **Fetch click details**: `ClickService.getClick(clickId)` calls the VoucherCloud API to retrieve the `Click` record (attribution ID, bcookie, deal UUID, source, event ID, merchant slug).
   - From: `revproc_clickService`
   - To: `voucherCloudApi`
   - Protocol: HTTPS (Retrofit2)

4. **Update merchant slug mapping**: If a click and merchant slug are found, `MerchantSlugMappingManager.updateMerchantSlugMapping` updates the local merchant slug mapping in MySQL.
   - From: `revproc_transactionProcessor`
   - To: `continuumCouponsRevprocDatabase`
   - Protocol: JDBC

5. **Deduplicate revenue**: If a merchant slug is known and the transaction has no transactionId, `ProcessedTransactionDAO.revenueExistsWithoutTransaction` checks for an existing record matching merchant slug, transaction time, totalSale, and amount. If a duplicate is found, the transaction is skipped and `transaction/duplicate_revenue_found` is emitted.
   - From: `revproc_transactionProcessor`
   - To: `continuumCouponsRevprocDatabase`
   - Protocol: JDBC

6. **Build processed transaction**: `ProcessedTransactionFactory.build(unprocessedTransaction, click)` maps the enriched data into a `ProcessedTransaction` model. If no click is available, the factory builds the record from raw transaction data only.
   - From: `revproc_transactionProcessor`
   - To: Internal
   - Protocol: Direct

7. **Populate merchant slug**: If the `ProcessedTransaction` has no merchant slug yet, `MerchantSlugMappingManager.getSlug` resolves it from the mapping table.
   - From: `revproc_transactionProcessor`
   - To: `continuumCouponsRevprocDatabase`
   - Protocol: JDBC

8. **Standardize merchant slug**: `ProcessedTransactionFinalizer.merchantSlugStandardization` checks `MerchantSlugMigrationDAO.findVCapiMerchantSlug` to normalize the slug to the VoucherCloud API canonical form. Emits `transaction/merchant_slug_vcapi` or `transaction/merchant_slug_capi` metric.
   - From: `revproc_finalizer`
   - To: `continuumCouponsRevprocDatabase`
   - Protocol: JDBC

9. **Persist processed transaction**: `ProcessedTransactionDAO.insert(processedTransaction)` writes the final record to `processed_transactions`. Logs `[TRANSACTION-SUCCESSFULLY-PROCESSED]`.
   - From: `revproc_finalizer`
   - To: `continuumCouponsRevprocDatabase`
   - Protocol: JDBC

10. **Qualify for messaging**: If the transaction is a core coupon (`coreCouponTransaction = true`), has a deal UUID, and has a bcookie, proceed to message publishing. Otherwise, log a warning and skip messaging.
    - From: `revproc_finalizer`
    - To: Internal
    - Protocol: Direct

11. **Build and publish click message**: `mapTransactionToClickMbusPayload` builds a `ClickMbusPayload` (with a `JanusClick`). The serialized JSON is sent to the Mbus destination for `"click"` messages.
    - From: `revproc_messageBusClient`
    - To: `messageBus`
    - Protocol: JMS

12. **Build and publish redemption message**: `mapTransactionToRedemptionMbusPayload` builds a `RedemptionMbusPayload` (with a `Redemption` containing commission as `Money`, totalSale as `Money`, and the clickPayloadId linking to the paired click message). The serialized JSON is sent to the Mbus destination for `"redemption"` messages.
    - From: `revproc_messageBusClient`
    - To: `messageBus`
    - Protocol: JMS

13. **Return result**: `TransactionProcessor.process` emits `transaction/finalize` metric and returns the `ProcessedTransaction`. On any exception, emits `transaction/failed` and returns null.
    - From: `revproc_transactionProcessor`
    - To: Caller
    - Protocol: Direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| VoucherCloud API unavailable | `VoucherCloudException` — click is absent; transaction built without enrichment | Transaction persisted without click data; Mbus messages not sent (no deal UUID / bcookie) |
| Duplicate revenue detected | Skip transaction silently; emit `transaction/duplicate_revenue_found` | No record inserted; no Mbus message |
| MySQL insert fails | Exception caught by outer try/catch in `process()`; `transaction/failed` emitted | Transaction not persisted; logged with clickId |
| Mbus `MessageException` | Caught and logged as `sendMessages.error`; not re-thrown | Transaction already persisted; message lost; no rollback |
| JSON serialization failure | `serialize()` returns `Optional.empty()`; both messages skipped if either fails to serialize | Messages not sent; logged |

## Sequence Diagram

```
TransactionProcessor -> ClickService: getClick(clickId)
ClickService -> VoucherCloudAPI: GET /clicks/{clickId} HTTPS
VoucherCloudAPI --> ClickService: VoucherCloudClick
ClickService --> TransactionProcessor: Optional<Click>
TransactionProcessor -> MySQL: updateMerchantSlugMapping JDBC
TransactionProcessor -> MySQL: revenueExistsWithoutTransaction JDBC
TransactionProcessor -> ProcessedTransactionFactory: build(unprocessedTx, click)
ProcessedTransactionFactory --> TransactionProcessor: ProcessedTransaction
TransactionProcessor -> ProcessedTransactionFinalizer: finalizeTransaction(processedTx)
ProcessedTransactionFinalizer -> MySQL: findVCapiMerchantSlug JDBC
ProcessedTransactionFinalizer -> MySQL: INSERT processed_transactions JDBC
alt coreCouponTransaction && dealUUID && bcookie
  ProcessedTransactionFinalizer -> MessageBusClient: send(clickPayload) JMS
  MessageBusClient -> Mbus: click message JMS
  ProcessedTransactionFinalizer -> MessageBusClient: send(redemptionPayload) JMS
  MessageBusClient -> Mbus: redemption message JMS
end
ProcessedTransactionFinalizer --> TransactionProcessor: (complete)
TransactionProcessor --> Caller: ProcessedTransaction
```

## Related

- Architecture dynamic view: `dynamic-coupons-revproc-transaction-processing`
- Related flows: [AffJet Scheduled Ingestion](affjet-scheduled-ingestion.md), [Manual AffJet Ingestion Trigger](manual-affjet-ingestion.md)
