---
service: "ingestion-service"
title: "Merchant-Approved Refund Processing"
generated: "2026-03-03"
type: flow
flow_name: "merchant-approved-refund"
flow_type: scheduled
trigger: "Quartz scheduler — internal schedule (also manually triggerable via GET /odis/api/v1/merchantApprovedRefunds/triggerJob)"
participants:
  - "continuumIngestionService"
  - "salesForce"
  - "extCaapApi_85f2db0d"
  - "continuumIngestionServiceMysql"
architecture_ref: "dynamic-ticketEscalationFlow"
---

# Merchant-Approved Refund Processing

## Summary

The `RefundMerchantApprovedOrdersJob` is a Quartz scheduled job that retrieves merchant-approved refund records from Salesforce and processes each corresponding order refund via the CAAP API. It records each refund attempt in the MySQL audit table. This flow automates the processing of refunds that a merchant has explicitly approved, removing the need for manual intervention by a Customer Support agent.

## Trigger

- **Type**: Schedule (Quartz job) and manual API trigger
- **Source**: Internal Quartz scheduler (`jtier-quartz-bundle`) on schedule; also triggerable via `GET /odis/api/v1/merchantApprovedRefunds/triggerJob`
- **Frequency**: Configured via `quartz` YAML block (exact cron schedule managed in environment-specific config)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Ingestion Service (Background Jobs) | Executes the scheduled refund processing job | `continuumIngestionService` (`ingestionService_backgroundJobs`) |
| Salesforce | Source of merchant-approved refund records (`FetchMerchantApprovedRefundsResponse`) | `salesForce` |
| CAAP API | Receives and executes order refund requests | `extCaapApi_85f2db0d` |
| Ingestion Service MySQL | Stores Salesforce OAuth token; records refund audit entries | `continuumIngestionServiceMysql` |

## Steps

1. **Job fires on schedule**: The Quartz scheduler triggers `RefundMerchantApprovedOrdersJob.execute()`.
   - From: Quartz scheduler (in-process)
   - To: `ingestionService_backgroundJobs`
   - Protocol: Quartz (in-process)

2. **Calls RefundOrdersService**: Delegates to `RefundOrdersService.refundMerchantApprovedOrders()`.
   - From: `ingestionService_backgroundJobs`
   - To: `coreServices`
   - Protocol: Java (in-process)

3. **Reads SF OAuth token**: Fetches cached Salesforce OAuth token from MySQL; refreshes if expired.
   - From: `coreServices`
   - To: `continuumIngestionServiceMysql`
   - Protocol: JDBI/MySQL

4. **Fetches merchant-approved refund orders from Salesforce**: Calls the Salesforce API to retrieve records of orders that merchants have approved for refund (`FetchMerchantApprovedRefundsResponse`).
   - From: `continuumIngestionService` (`ingestionService_integrationClients`)
   - To: `salesForce`
   - Protocol: HTTPS/REST (Salesforce REST API)

5. **Processes each refund order via CAAP**: For each merchant-approved refund record, submits a `RefundOrdersRequestBody` to the CAAP API to execute the actual order refund.
   - From: `continuumIngestionService` (`ingestionService_integrationClients`)
   - To: `extCaapApi_85f2db0d`
   - Protocol: HTTPS/REST

6. **Records audit entry**: After each refund attempt (success or failure), writes an audit record to `MerchantApprovedRefundsAuditDBI` in MySQL.
   - From: `coreServices` → `ingestionService_persistenceLayer`
   - To: `continuumIngestionServiceMysql`
   - Protocol: JDBI/MySQL

7. **Logs outcome**: Logs `MERCHANT_APPROVED_REFUNDS_JOB` event with `started`, `completed`, or `failed` status.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce API error fetching refund records | `InternalServerErrorException` or `IOException` caught; `JobExecutionException` thrown | Job fails; Quartz records failure; retried on next fire |
| CAAP API refund execution error | `refundStatus` returned as failed; `failedInventoryUnitIds` populated in response | Audit record written with failure state; job continues to next record |
| MySQL write error (audit) | Exception propagated | Job may fail partway; Quartz records failure |
| Salesforce OAuth token expired | Token refreshed transparently | Additional latency; flow continues |

## Sequence Diagram

```
QuartzScheduler -> RefundMerchantApprovedOrdersJob: execute()
RefundMerchantApprovedOrdersJob -> RefundOrdersService: refundMerchantApprovedOrders()
RefundOrdersService -> MySQL: Read SF OAuth token
MySQL --> RefundOrdersService: Token (or empty)
RefundOrdersService -> Salesforce: Fetch merchant-approved refund orders
Salesforce --> RefundOrdersService: FetchMerchantApprovedRefundsResponse (list of orders)
loop for each merchant-approved refund order
  RefundOrdersService -> CAAP API: RefundOrdersRequestBody (execute refund)
  CAAP API --> RefundOrdersService: RefundOrdersResponseBody (success/failure + inventory unit IDs)
  RefundOrdersService -> MySQL: Write MerchantApprovedRefundsAudit record
end
RefundMerchantApprovedOrdersJob -> Logger: Log COMPLETED or FAILED
```

## Related

- Related flows: [Customer Refund Request](customer-refund.md)
- See also: [Data Stores](../data-stores.md) — merchant-approved refunds audit table
- Manual trigger: `GET /odis/api/v1/merchantApprovedRefunds/triggerJob`
