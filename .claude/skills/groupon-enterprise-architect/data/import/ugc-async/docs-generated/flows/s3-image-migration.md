---
service: "ugc-async"
title: "S3 Image Migration"
generated: "2026-03-03"
type: flow
flow_name: "s3-image-migration"
flow_type: scheduled
trigger: "Quartz scheduler fires S3ImageMoverJob"
participants:
  - "continuumUgcAsyncService"
  - "continuumUgcPostgresDb"
  - "gimsService_9e27"
architecture_ref: "dynamic-ugc-async-s3-image-migration"
---

# S3 Image Migration

## Summary

When customers submit survey answers that include images, those images are uploaded directly from the mobile app to a Groupon-owned S3 staging bucket. ugc-async runs `S3ImageMoverJob` on a Quartz schedule to move these staged images from S3 to the centralised Image Service (GIMS). After a successful transfer, the image record is updated in PostgreSQL with the hosted Image Service URL and the file is deleted from S3. A similar flow exists for customer videos (`S3VideoMoverJob`) and influencer videos (`S3InfluencerVideoMoverJob`).

## Trigger

- **Type**: schedule (Quartz job)
- **Source**: Quartz Job Scheduler fires `S3ImageMoverJob` on a configured cron interval
- **Frequency**: Periodic (interval defined in application YAML Quartz config); throttled to 100 Image Service calls per minute within the job

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| UGC Async Service — Quartz Scheduler | Fires S3ImageMoverJob on schedule | `continuumUgcAsyncService` |
| UGC Async Service — S3ImageMoverHelper | Orchestrates S3 listing, download, Image Service upload, and cleanup | `continuumUgcAsyncService` |
| AWS S3 (image staging bucket) | Source of customer-uploaded survey images | Not in federated Structurizr model |
| Image Service (GIMS) | Receives images via multipart POST; returns hosted image URL | `gimsService_9e27` |
| UGC Postgres | Source of image metadata; updated with hosted URL and status | `continuumUgcPostgresDb` |

## Steps

1. **Quartz fires S3ImageMoverJob**: Job triggered by Quartz scheduler; `@DisallowConcurrentExecution` prevents overlapping runs
   - From: Quartz Scheduler
   - To: S3ImageMoverHelper
   - Protocol: direct (in-process)

2. **Lists all objects in S3 image bucket**: `getAllImageKeysFromS3()` calls `s3Client.listObjects(aws3Model.getImageBucket())` and paginates through all results; filters out video objects by content type
   - From: `continuumUgcAsyncService`
   - To: AWS S3
   - Protocol: AWS SDK

3. **Resolves image metadata**: For each S3 key, `getMetaDataFromImageKey()` queries `continuumUgcPostgresDb` via `ImageDao.findImages()` — if an existing image record is found (indicating a prior partial run), that record is reused; otherwise a new `Image` model is built from the survey ID extracted from the S3 key format `{surveyId}_{questionId}`
   - From: `continuumUgcAsyncService`
   - To: `continuumUgcPostgresDb`
   - Protocol: JDBI / SQL

4. **Downloads image bytes from S3**: `getImageAndPost()` downloads the image object content from S3 as a byte array
   - From: `continuumUgcAsyncService`
   - To: AWS S3
   - Protocol: AWS SDK

5. **Applies rate limit check**: `checkRateLimit()` enforces a maximum of 100 Image Service calls per minute; sleeps for 60 seconds and resets counter if threshold is reached
   - From: S3ImageMoverHelper
   - To: S3ImageMoverHelper (internal)
   - Protocol: direct (in-process)

6. **Posts image to Image Service**: `postToImageService()` sends a multipart POST request with the image bytes, `clientId`, and `apiKey` to GIMS
   - From: `continuumUgcAsyncService`
   - To: `gimsService_9e27`
   - Protocol: REST (Retrofit, multipart/form-data)

7. **Handles Image Service response**:
   - HTTP 200: Extracts `original_image_url` from response; updates image record with URL and `submitted` status; saves to Postgres
   - HTTP 415 (invalid image): Calls `cleanupAndPost()` — strips 5 header lines and 2 footer lines added by mobile upload before retrying; if still 415, marks image as `deleted` in Postgres
   - HTTP 4xx: Logs warning; does not delete from S3 (retry on next job run)
   - HTTP 5xx: Logs warning; does not delete from S3 (retry on next job run)
   - From: `gimsService_9e27`
   - To: `continuumUgcAsyncService`

8. **Updates image record in Postgres**: Saves image with `image_url` and status `submitted` (or error status if applicable)
   - From: `continuumUgcAsyncService`
   - To: `continuumUgcPostgresDb`
   - Protocol: JDBI / SQL

9. **Deletes successfully migrated images from S3**: `deleteImagesFromS3()` issues a multi-object delete request for all successfully transferred images
   - From: `continuumUgcAsyncService`
   - To: AWS S3
   - Protocol: AWS SDK

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| S3 list or download failure (SdkClientException) | Exception caught in `getImageAndPost()`; image skipped | Image remains in S3; retried on next job run |
| Image Service 415 (invalid format) | `cleanupAndPost()` strips mobile upload header/footer and retries; if still 415, marks as `deleted` in Postgres | S3 file remains (deleted on subsequent cleanup); image not hosted |
| Image Service 4xx (client error) | Warning logged; file not deleted from S3 | Retried on next job run |
| Image Service 5xx (server error) | Warning logged; file not deleted from S3 | Retried on next job run |
| S3 multi-object delete partial failure | `MultiObjectDeleteException` caught; failed keys logged | Successfully deleted keys removed; failed keys remain and will be re-attempted |
| S3 key format invalid (no `_` separator) | `getMetaDataFromImageKey()` returns empty Image model | Image skipped; not uploaded to Image Service |

## Sequence Diagram

```
Quartz Scheduler -> S3ImageMoverHelper: Fire S3ImageMoverJob (scheduled)
S3ImageMoverHelper -> AWS S3: listObjects(imageBucket) — paginated
AWS S3 --> S3ImageMoverHelper: List of S3 keys (images only)
loop for each image key
  S3ImageMoverHelper -> UGC Postgres: findImages(s3Key) — check existing record
  UGC Postgres --> S3ImageMoverHelper: Existing image record or null
  S3ImageMoverHelper -> AWS S3: getObject(imageBucket, s3Key) — download bytes
  AWS S3 --> S3ImageMoverHelper: Image byte array
  S3ImageMoverHelper -> Image Service (GIMS): POST /images (multipart, clientId, apiKey)
  Image Service --> S3ImageMoverHelper: {original_image_url} or error
  S3ImageMoverHelper -> UGC Postgres: save image (url, status=submitted)
end
S3ImageMoverHelper -> AWS S3: deleteObjects(successfullyMigratedKeys)
```

## Related

- Architecture dynamic view: `dynamic-ugc-async-s3-image-migration`
- Related flows: [S3 Video Migration](s3-image-migration.md) — same pattern applied to `S3VideoMoverJob` and `S3InfluencerVideoMoverJob`
