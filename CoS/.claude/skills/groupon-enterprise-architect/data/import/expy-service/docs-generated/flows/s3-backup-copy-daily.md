---
service: "expy-service"
title: "S3 Backup Copy Daily"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "s3-backup-copy-daily"
flow_type: scheduled
trigger: "Quartz scheduler fires daily S3 copy job"
participants:
  - "quartzJobs"
  - "serviceLayer_Exp"
  - "expyService_externalClients"
  - "continuumExpyMySql"
  - "optimizelyS3Bucket_84a1"
  - "grouponS3Bucket_7c3d"
architecture_ref: "dynamic-s3-backup-copy"
---

# S3 Backup Copy Daily

## Summary

This scheduled flow creates a daily Groupon-owned backup of Optimizely datafiles stored in Optimizely's S3 bucket. The Quartz scheduler fires once per day; the job reads datafiles from `optimizelyS3Bucket_84a1` using the AWS S3 SDK and writes copies to `grouponS3Bucket_7c3d`. This ensures Groupon retains independent access to experiment configuration data, reducing dependency on Optimizely's infrastructure availability.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler (`quartzJobs` component, backed by Quartz tables in `continuumExpyMySql`)
- **Frequency**: Daily — exact time configured in JTier YAML config (not defined in architecture model)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Quartz Jobs | Initiates the daily S3 copy job | `quartzJobs` |
| Service Layer | Orchestrates read-from-source and write-to-destination logic | `serviceLayer_Exp` |
| External Clients | AWS S3 SDK operations against both buckets | `expyService_externalClients` |
| Expy MySQL | Stores Quartz job execution state | `continuumExpyMySql` |
| Optimizely S3 Bucket | Source of Optimizely-managed datafiles | `optimizelyS3Bucket_84a1` |
| Groupon S3 Bucket | Destination for Groupon-owned backup copies | `grouponS3Bucket_7c3d` |

## Steps

1. **Quartz job fires**: The Quartz scheduler triggers the daily S3 backup copy job.
   - From: Quartz scheduler (internal)
   - To: `quartzJobs`
   - Protocol: Quartz trigger (in-process)

2. **Trigger service layer copy**: Quartz job delegates the copy operation to the service layer.
   - From: `quartzJobs`
   - To: `serviceLayer_Exp`
   - Protocol: Direct (in-process)

3. **List datafiles in Optimizely S3 bucket**: Service layer uses external clients (AWS S3 SDK) to list all datafile objects in `optimizelyS3Bucket_84a1`.
   - From: `expyService_externalClients`
   - To: `optimizelyS3Bucket_84a1`
   - Protocol: AWS S3 SDK (HTTPS)

4. **Read each datafile from Optimizely S3**: For each datafile identified, the service reads the object contents from `optimizelyS3Bucket_84a1`.
   - From: `expyService_externalClients`
   - To: `optimizelyS3Bucket_84a1`
   - Protocol: AWS S3 SDK (HTTPS)

5. **Write datafile copy to Groupon S3**: Each read datafile is written to `grouponS3Bucket_7c3d`, preserving the object key structure.
   - From: `expyService_externalClients`
   - To: `grouponS3Bucket_7c3d`
   - Protocol: AWS S3 SDK (HTTPS)

6. **Update Quartz job state**: Quartz records job execution result in MySQL.
   - From: `quartzJobs`
   - To: `continuumExpyMySql`
   - Protocol: JDBC (Quartz internal)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Optimizely S3 bucket read fails (IAM, network) | Log exception; abort copy job | Backup not created for this run; primary bucketing unaffected |
| Groupon S3 bucket write fails (IAM, network) | Log exception; partial copy possible | Some files not backed up; next daily run will retry |
| Quartz job fails to fire (scheduler issue) | Quartz retry / misfire policy applies | Backup may be skipped for that day; alert on consecutive failures |
| AWS credential expiry | IAM error on S3 SDK call; log exception | All S3 operations fail; escalate to platform/infra team |

## Sequence Diagram

```
Quartz  ->  quartzJobs: fire daily S3 copy trigger
quartzJobs  ->  serviceLayer_Exp: copyDatafilesToGrouponS3()
serviceLayer_Exp  ->  expyService_externalClients: listObjects(optimizelyS3Bucket_84a1)
expyService_externalClients  ->  optimizelyS3Bucket_84a1: S3 ListObjectsV2
optimizelyS3Bucket_84a1  -->  expyService_externalClients: object list
loop for each datafile object:
  expyService_externalClients  ->  optimizelyS3Bucket_84a1: S3 GetObject(key)
  optimizelyS3Bucket_84a1  -->  expyService_externalClients: datafile bytes
  expyService_externalClients  ->  grouponS3Bucket_7c3d: S3 PutObject(key, datafile bytes)
  grouponS3Bucket_7c3d  -->  expyService_externalClients: ok
quartzJobs  ->  continuumExpyMySql: UPDATE quartz_job_details (last_fired, result)
```

## Related

- Architecture dynamic view: `dynamic-s3-backup-copy` (not yet defined in model)
- Related flows: [Datafile Update Scheduled Job](datafile-update-scheduled-job.md)
