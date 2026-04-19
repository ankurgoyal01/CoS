---
service: "reporting-service"
title: "Report Retry Cleanup"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "report-retry-cleanup"
flow_type: scheduled
trigger: "Scheduled cleanup job (Spring Scheduler + ShedLock)"
participants:
  - "campaignScheduler"
  - "reportGenerationService"
  - "reportingService_persistenceDaos"
  - "reportingService_s3Client"
  - "continuumReportingDb"
  - "continuumFilesDb"
  - "reportingS3Bucket"
architecture_ref: "Reporting-API-Components"
---

# Report Retry Cleanup

## Summary

The report retry cleanup flow detects and resolves report generation requests that have become stale due to partial failures — for example, records stuck in `PENDING` status beyond the expected generation SLA, orphaned file metadata, or failed report attempts that were not fully cleaned up. The flow scans the Reporting Database for stale records, retries eligible reports via `reportGenerationService`, removes orphaned S3 artifacts and file metadata, and marks unrecoverable requests as `FAILED`. This ensures the report backlog does not grow unboundedly and merchants can resubmit requests cleanly.

## Trigger

- **Type**: schedule
- **Source**: `campaignScheduler` component (Spring Scheduler with ShedLock 1.2.0 distributed lock; shares scheduler infrastructure with campaign summary jobs)
- **Frequency**: Scheduled (exact interval not evidenced in architecture model; to be confirmed with service owner)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Campaign Scheduler | Initiates the cleanup job; holds ShedLock to prevent concurrent runs | `campaignScheduler` |
| Report Generation | Retries eligible failed report generation attempts | `reportGenerationService` |
| Persistence Layer | Reads stale report records; updates statuses; deletes orphaned metadata | `reportingService_persistenceDaos` |
| S3 Client | Removes orphaned report artifacts from S3 | `reportingService_s3Client` |
| Reporting Database | Source of stale/pending report records and status updates | `continuumReportingDb` |
| Files Database | Source of orphaned file metadata records | `continuumFilesDb` |
| Report S3 Bucket | Target for orphaned artifact deletion | `reportingS3Bucket` |

## Steps

1. **Acquire distributed lock**: Cleanup job acquires a ShedLock to prevent concurrent execution.
   - From: `campaignScheduler`
   - To: `continuumReportingDb` (ShedLock table)
   - Protocol: JDBC

2. **Scan for stale report records**: Persistence Layer queries the Reporting Database for records in `PENDING` or `IN_PROGRESS` status beyond the expected SLA threshold.
   - From: `campaignScheduler`
   - To: `reportingService_persistenceDaos` → `continuumReportingDb`
   - Protocol: direct / JDBC

3. **Classify stale records**: For each stale record, determine if it is eligible for retry (recent enough, within retry limit) or should be marked as permanently failed.
   - From: `campaignScheduler`
   - To: internal classification logic
   - Protocol: direct

4. **Retry eligible reports**: For retryable records, delegate to `reportGenerationService` to re-execute report generation from scratch.
   - From: `campaignScheduler`
   - To: `reportGenerationService`
   - Protocol: direct

5. **Mark unrecoverable reports as FAILED**: For records exceeding retry limits or too old for retry, update status to `FAILED` in the Reporting Database.
   - From: `campaignScheduler`
   - To: `reportingService_persistenceDaos` → `continuumReportingDb`
   - Protocol: direct / JDBC

6. **Scan for orphaned file metadata**: Persistence Layer queries the Files Database for file metadata records with no corresponding completed report.
   - From: `campaignScheduler`
   - To: `reportingService_persistenceDaos` → `continuumFilesDb`
   - Protocol: direct / JDBC

7. **Delete orphaned S3 artifacts**: S3 Client removes S3 objects identified as orphaned (file metadata exists but parent report is failed or deleted).
   - From: `campaignScheduler`
   - To: `reportingService_s3Client` → `reportingS3Bucket`
   - Protocol: AWS SDK

8. **Delete orphaned file metadata**: Persistence Layer deletes orphaned records from the Files Database.
   - From: `campaignScheduler`
   - To: `reportingService_persistenceDaos` → `continuumFilesDb`
   - Protocol: direct / JDBC

9. **Release distributed lock**: ShedLock releases the cleanup job lock.
   - From: `campaignScheduler`
   - To: `continuumReportingDb` (ShedLock table)
   - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| ShedLock already held | Lock not acquired; cleanup skipped | Stale records remain until next scheduled run |
| Retry generation fails again | `reportGenerationService` exception | Record retry count incremented; will be marked `FAILED` on next run if limit exceeded |
| S3 delete failure | S3 Client exception | Orphaned artifact remains; metadata deletion may be skipped to maintain consistency |
| Database scan error | Hibernate exception | Cleanup aborts; stale records remain until next scheduled run |

## Sequence Diagram

```
campaignScheduler -> continuumReportingDb: ACQUIRE ShedLock
campaignScheduler -> continuumReportingDb: SELECT stale PENDING/IN_PROGRESS reports
campaignScheduler -> campaignScheduler: classify: retryable vs failed
campaignScheduler -> reportGenerationService: retryReport(staleReportId) [for retryable]
reportGenerationService -> continuumReportingDb: UPDATE status=COMPLETE (on success)
campaignScheduler -> continuumReportingDb: UPDATE status=FAILED [for unrecoverable]
campaignScheduler -> continuumFilesDb: SELECT orphaned file metadata
campaignScheduler -> reportingService_s3Client: DELETE orphaned S3 objects
reportingService_s3Client -> reportingS3Bucket: DELETE artifact
campaignScheduler -> continuumFilesDb: DELETE orphaned metadata records
campaignScheduler -> continuumReportingDb: RELEASE ShedLock
```

## Related

- Architecture dynamic view: `Reporting-API-Components`
- Related flows: [Report Generation](report-generation.md), [Weekly Campaign Summary](weekly-campaign-summary.md), [Deal Cap Enforcement](deal-cap-enforcement.md)
