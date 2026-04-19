---
service: "reporting-service"
title: "Bulk Redemption Processing"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "bulk-redemption-processing"
flow_type: asynchronous
trigger: "API call — POST /bulkredemption/v1/uploadcsvfile"
participants:
  - "reportingService_apiControllers"
  - "mbusProducer"
  - "reportingService_mbusConsumers"
  - "reportingService_persistenceDaos"
  - "reportingService_s3Client"
  - "continuumReportingDb"
  - "continuumVouchersDb"
  - "reportingS3Bucket"
  - "mbus"
architecture_ref: "Reporting-API-Components"
---

# Bulk Redemption Processing

## Summary

A merchant uploads a CSV file containing voucher IDs to be redeemed in bulk via `POST /bulkredemption/v1/uploadcsvfile`. The `reportingService_apiControllers` component receives the multipart upload, validates and parses the CSV using SuperCSV, and publishes a `BulkVoucherRedemption` event to MBus via `mbusProducer`. The `reportingService_mbusConsumers` component also consumes the `BulkVoucherRedemption` event to persist redemption data and update voucher reporting state.

## Trigger

- **Type**: api-call
- **Source**: Merchant or internal operator calling `POST /bulkredemption/v1/uploadcsvfile` with a multipart CSV file
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Controllers | Receives CSV upload, validates, parses with SuperCSV, delegates to MBus producer | `reportingService_apiControllers` |
| MBus Producer | Publishes `BulkVoucherRedemption` event to message bus | `mbusProducer` |
| MBus Consumers | Consumes `BulkVoucherRedemption` event; persists redemption data | `reportingService_mbusConsumers` |
| Persistence Layer | Reads and writes voucher and reporting data | `reportingService_persistenceDaos` |
| S3 Client | Optionally stores the uploaded CSV file for audit purposes | `reportingService_s3Client` |
| Reporting Database | Records bulk redemption job metadata | `continuumReportingDb` |
| Vouchers Database | Voucher state data read during processing | `continuumVouchersDb` |
| Report S3 Bucket | Stores uploaded CSV for audit trail | `reportingS3Bucket` |
| MBus | Message bus transporting `BulkVoucherRedemption` event | `mbus` |

## Steps

1. **Receive CSV upload**: Merchant calls `POST /bulkredemption/v1/uploadcsvfile` with a multipart CSV containing voucher IDs.
   - From: `external client (merchant)`
   - To: `reportingService_apiControllers`
   - Protocol: REST (multipart/form-data)

2. **Parse and validate CSV**: Controllers use SuperCSV 2.2.0 to parse the CSV file and validate voucher ID format and row structure.
   - From: `reportingService_apiControllers`
   - To: internal SuperCSV library
   - Protocol: direct

3. **Store CSV to S3**: Controllers upload the raw CSV file to S3 for audit trail purposes.
   - From: `reportingService_apiControllers`
   - To: `reportingService_s3Client` → `reportingS3Bucket`
   - Protocol: AWS SDK

4. **Persist job record**: Controllers write a bulk redemption job record with the voucher list and initial status.
   - From: `reportingService_apiControllers`
   - To: `reportingService_persistenceDaos` → `continuumReportingDb`
   - Protocol: direct / JDBC

5. **Publish BulkVoucherRedemption event**: Controllers delegate to `mbusProducer` to publish the `BulkVoucherRedemption` event containing voucher IDs and merchant context.
   - From: `reportingService_apiControllers`
   - To: `mbusProducer` → `mbus`
   - Protocol: MBus

6. **Return acceptance response**: Controllers return a success response with the job ID; processing continues asynchronously.
   - From: `reportingService_apiControllers`
   - To: `external client (merchant)`
   - Protocol: REST

7. **Consume BulkVoucherRedemption event**: `reportingService_mbusConsumers` receives the published event from MBus.
   - From: `mbus`
   - To: `reportingService_mbusConsumers`
   - Protocol: MBus

8. **Read voucher state**: MBus Consumers query the Vouchers Database to validate voucher eligibility and current state.
   - From: `reportingService_mbusConsumers`
   - To: `reportingService_persistenceDaos` → `continuumVouchersDb`
   - Protocol: direct / JDBC

9. **Persist redemption results**: MBus Consumers write redemption outcome records to the Reporting Database.
   - From: `reportingService_mbusConsumers`
   - To: `reportingService_persistenceDaos` → `continuumReportingDb`
   - Protocol: direct / JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| CSV parse failure | SuperCSV throws exception in Controllers | Request rejected with 4xx; no event published |
| MBus publish failure | `mbusProducer` exception | Job may be persisted but event not delivered; downstream processing does not occur |
| Consumer processing failure | MBus consumer exception during redemption persistence | Partial redemption state; no DLQ evidence found — confirm with service owner |
| S3 upload failure for CSV | S3 Client exception | CSV not stored for audit; processing may still continue |

## Sequence Diagram

```
Merchant -> reportingService_apiControllers: POST /bulkredemption/v1/uploadcsvfile [CSV file]
reportingService_apiControllers -> SuperCSV: parse and validate CSV rows
reportingService_apiControllers -> reportingService_s3Client: upload CSV to S3
reportingService_s3Client -> reportingS3Bucket: PUT csv file
reportingService_apiControllers -> continuumReportingDb: INSERT bulk redemption job record
reportingService_apiControllers -> mbusProducer: publish(BulkVoucherRedemption)
mbusProducer -> mbus: BulkVoucherRedemption event
reportingService_apiControllers --> Merchant: 200 OK { jobId }

mbus -> reportingService_mbusConsumers: BulkVoucherRedemption event
reportingService_mbusConsumers -> continuumVouchersDb: SELECT voucher state
reportingService_mbusConsumers -> continuumReportingDb: INSERT redemption results
```

## Related

- Architecture dynamic view: `Reporting-API-Components`
- Related flows: [Report Generation](report-generation.md), [Payment Event Consumption](payment-event-consumption.md)
