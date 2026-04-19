---
service: "travel-inventory"
title: "Daily Inventory Report Generation"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "daily-inventory-report-generation"
flow_type: batch
trigger: "Scheduled -- Cron container triggers /v2/getaways/inventory/reporter/generate"
participants:
  - "continuumTravelInventoryCron"
  - "continuumTravelInventoryService"
  - "continuumTravelInventoryDb"
  - "continuumAwsSftpTransfer"
architecture_ref: "dynamic-daily-inventory-report-generation"
---

# Daily Inventory Report Generation

## Summary

This flow generates a daily inventory report CSV file and transfers it to the AWS SFTP endpoint for downstream consumption by finance and reporting teams. The Python cron container triggers the process by calling the Worker API on the main service. The Worker Domain reads inventory data from MySQL in large batches, assembles the CSV file, and the SFTP Client transfers the file to the AWS SFTP Transfer endpoint. Report generation state is tracked in the database for monitoring and retry purposes.

## Trigger

- **Type**: schedule
- **Source**: `continuumTravelInventoryCron` (Python cron container) fires on a daily schedule
- **Frequency**: Daily

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Daily Inventory Report Cron Job | Triggers report generation on schedule | `continuumTravelInventoryCron_dailyReportJob` |
| HTTP Client (Requests) | Invokes the Worker API endpoint on the main service | `continuumTravelInventoryCron_httpClient` |
| Worker API | Receives the report generation trigger | `continuumTravelInventoryService_workerApi` |
| Worker Domain Services | Orchestrates data extraction, CSV assembly, and SFTP transfer | `continuumTravelInventoryService_workerDomain` |
| Persistence Layer | Reads inventory data in batches and tracks report job state | `continuumTravelInventoryService_persistence` |
| Getaways Inventory DB | Source of inventory data for report generation | `continuumTravelInventoryDb` |
| AWS SFTP Client | Transfers the generated CSV file to the SFTP endpoint | `continuumTravelInventoryService_sftpClient` |
| AWS SFTP Transfer | Managed SFTP endpoint where the CSV file is deposited | `continuumAwsSftpTransfer` |

## Steps

1. **Cron fires on schedule**: The Daily Inventory Report Cron Job executes on its configured daily schedule.
   - From: `scheduler`
   - To: `continuumTravelInventoryCron_dailyReportJob`
   - Protocol: cron trigger

2. **Cron invokes Worker API**: The HTTP Client (Requests) sends `POST /v2/getaways/inventory/reporter/generate` to the Getaways Inventory Service.
   - From: `continuumTravelInventoryCron_dailyReportJob`
   - To: `continuumTravelInventoryCron_httpClient` -> `continuumTravelInventoryService_workerApi`
   - Protocol: HTTP, JSON

3. **Delegate to Worker Domain**: Worker API passes the report generation request to Worker Domain Services.
   - From: `continuumTravelInventoryService_workerApi`
   - To: `continuumTravelInventoryService_workerDomain`
   - Protocol: direct

4. **Create report job record**: Worker Domain creates a report job record in MySQL to track the generation status.
   - From: `continuumTravelInventoryService_workerDomain`
   - To: `continuumTravelInventoryService_persistence` -> `continuumTravelInventoryDb`
   - Protocol: JDBC, Ebean ORM

5. **Read inventory data in batches**: Worker Domain reads large batches of hotel inventory, room types, rate plans, and availability data from MySQL for report assembly.
   - From: `continuumTravelInventoryService_workerDomain`
   - To: `continuumTravelInventoryService_persistence` -> `continuumTravelInventoryDb`
   - Protocol: JDBC, Ebean ORM

6. **Assemble CSV report**: Worker Domain processes the inventory data and generates the daily inventory report in CSV format.
   - From: `continuumTravelInventoryService_workerDomain`
   - To: `continuumTravelInventoryService_workerDomain` (internal)
   - Protocol: direct

7. **Transfer CSV via SFTP**: The AWS SFTP Client transfers the generated CSV file to the AWS SFTP Transfer endpoint.
   - From: `continuumTravelInventoryService_workerDomain`
   - To: `continuumTravelInventoryService_sftpClient` -> `continuumAwsSftpTransfer`
   - Protocol: SFTP over SSH

8. **Update report job status**: Worker Domain updates the report job record in MySQL to reflect completion (success or failure).
   - From: `continuumTravelInventoryService_workerDomain`
   - To: `continuumTravelInventoryService_persistence` -> `continuumTravelInventoryDb`
   - Protocol: JDBC, Ebean ORM

9. **Return response to cron**: Worker API returns a success or failure response to the Cron HTTP client.
   - From: `continuumTravelInventoryService_workerApi`
   - To: `continuumTravelInventoryCron_httpClient`
   - Protocol: HTTP, JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Cron container fails to start | Platform-level monitoring detects missed cron execution | Report not generated for the day; manual trigger via Worker API |
| Worker API unreachable | Cron HTTP client receives connection error | Report not triggered; Cron logs the error; retry on next schedule |
| MySQL read failure during data extraction | Worker Domain logs error and marks report job as failed | Report job status = failed; can be retried manually |
| CSV assembly error | Worker Domain catches exception and marks report job as failed | Report job status = failed; investigation required |
| SFTP transfer failure | SFTP Client logs error; report job marked as failed | CSV generated but not delivered; can be retried |
| Partial data due to concurrent writes | Report reflects data as of query time | Acceptable -- daily report is a snapshot; next day's report will capture changes |

## Sequence Diagram

```
scheduler -> continuumTravelInventoryCron_dailyReportJob: daily cron trigger
continuumTravelInventoryCron_dailyReportJob -> continuumTravelInventoryCron_httpClient: trigger report generation
continuumTravelInventoryCron_httpClient -> continuumTravelInventoryService_workerApi: POST /reporter/generate
continuumTravelInventoryService_workerApi -> continuumTravelInventoryService_workerDomain: delegate report generation
continuumTravelInventoryService_workerDomain -> continuumTravelInventoryDb: create report job record
continuumTravelInventoryService_workerDomain -> continuumTravelInventoryDb: read inventory data (batch)
continuumTravelInventoryService_workerDomain -> continuumTravelInventoryService_workerDomain: assemble CSV
continuumTravelInventoryService_workerDomain -> continuumTravelInventoryService_sftpClient: transfer CSV
continuumTravelInventoryService_sftpClient -> continuumAwsSftpTransfer: SFTP PUT report file
continuumTravelInventoryService_workerDomain -> continuumTravelInventoryDb: update report job status
continuumTravelInventoryService_workerApi --> continuumTravelInventoryCron_httpClient: 200 OK / error
```

## Related

- Architecture dynamic view: `dynamic-daily-inventory-report-generation`
- Related flows: [Backpack Reservation Sync](backpack-reservation-sync.md)
