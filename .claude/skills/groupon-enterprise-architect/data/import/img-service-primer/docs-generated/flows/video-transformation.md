---
service: "img-service-primer"
title: "Video Transformation"
generated: "2026-03-03"
type: flow
flow_name: "video-transformation"
flow_type: event-driven
trigger: "Video transformation update event consumed from Groupon message bus (JMS/STOMP)"
participants:
  - "videoUpdateListener"
  - "videoTransformer"
  - "videoDao"
  - "s3VideoUploader"
  - "continuumImageServicePrimerDb"
architecture_ref: "dynamic-video-transformation-flow"
---

# Video Transformation

## Summary

The video transformation flow handles inbound events signalling that a video asset needs to be processed. The `VideoUpdateListener` consumes these events from the Groupon internal message bus (JMS/STOMP) and delegates to `VideoTransformer`. The transformer downloads the source video from a GCS bucket, applies ffmpeg-based transformation (using the JavaCV/OpenCV/FFmpeg native libraries bundled in the deployment image), updates the transformation state in MySQL via `VideoDao`, and uploads the resulting transformed video payload to an AWS S3 bucket via `S3VideoUploader`. A dedicated Kubernetes CronJob (`video-transformer-cron`) runs every 5 minutes to process pending transformation records.

## Trigger

- **Type**: event
- **Source**: Video transformation update event on the Groupon message bus (topic referenced as `unknownVideoTransformationTopic` in architecture DSL — exact topic name not confirmed in source)
- **Frequency**: Event-driven; the CronJob component polls every 5 minutes

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `VideoUpdateListener` | Consumes video transformation update events from the message bus | `videoUpdateListener` |
| `VideoTransformer` | Downloads source media from GCS, runs ffmpeg transformation, prepares upload | `videoTransformer` |
| `VideoDao` | Reads current transformation state; writes updated state after each step | `videoDao` |
| `S3VideoUploader` | Uploads the completed transformed video artifact to AWS S3 | `s3VideoUploader` |
| `continuumImageServicePrimerDb` | MySQL database storing transformation state records | `continuumImageServicePrimerDb` |

## Steps

1. **Consume transformation event**: `VideoUpdateListener` receives a video transformation update event from the Groupon message bus via JMS/STOMP using the `jtier-messagebus-client`.
   - From: Message bus (video transformation topic)
   - To: `videoUpdateListener`
   - Protocol: JMS/STOMP

2. **Handle transformation request**: `VideoUpdateListener` parses the event payload and delegates to `VideoTransformer`.
   - From: `videoUpdateListener`
   - To: `videoTransformer`
   - Protocol: direct (in-process)

3. **Read transformation record**: `VideoTransformer` calls `VideoDao` to read the current transformation state from MySQL before beginning processing.
   - From: `videoTransformer`
   - To: `continuumImageServicePrimerDb` (via `videoDao`)
   - Protocol: JDBI/MySQL

4. **Download source media**: `VideoTransformer` downloads the source video file from a GCS bucket using `GCSClient`.
   - From: `videoTransformer`
   - To: GCS (source media bucket)
   - Protocol: GCS API

5. **Apply ffmpeg transformation**: `VideoTransformer` processes the source video using JavaCV/ffmpeg (bundled in the Docker image) to produce the transformed output artifact.
   - From: `videoTransformer` (in-process via native ffmpeg)

6. **Update transformation state**: `VideoTransformer` calls `VideoDao` to write the updated transformation state (in-progress or completed) to MySQL.
   - From: `videoTransformer`
   - To: `continuumImageServicePrimerDb` (via `videoDao`)
   - Protocol: JDBI/MySQL

7. **Upload transformed video**: `VideoTransformer` delegates to `S3VideoUploader` to upload the transformed video artifact to the AWS S3 bucket.
   - From: `videoTransformer`
   - To: `s3VideoUploader`
   - Protocol: direct (in-process)
   - From: `s3VideoUploader`
   - To: AWS S3
   - Protocol: S3 API (via `software.amazon.awssdk:s3`)

8. **Write final state**: `VideoDao` records the final completion state in MySQL.
   - From: `videoTransformer`
   - To: `continuumImageServicePrimerDb` (via `videoDao`)
   - Protocol: JDBI/MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Message bus event undeliverable | JMS/STOMP retry per message bus configuration | Event redelivered; no evidence of DLQ configuration in codebase |
| GCS download fails | Exception propagated; transformation state not advanced | Transformation record remains in its current state; CronJob retry picks it up in next 5-minute cycle |
| ffmpeg transformation fails | Exception propagated | Transformation state not advanced to "completed"; CronJob retry applies |
| S3 upload fails | Exception propagated | Transformation record not marked complete; CronJob retry applies |
| CronJob timeout | Kubernetes `activeDeadlineSeconds: 600` — pod terminated after 10 minutes | In-progress transformation rolled back to prior state by next CronJob run |
| MySQL connection failure | JDBI exception; transformation pipeline halts | Video transformation unavailable until DB connection restored |

## Sequence Diagram

```
MessageBus -> VideoUpdateListener: Video transformation update event (JMS/STOMP)
VideoUpdateListener -> VideoTransformer: Handle transformation request
VideoTransformer -> VideoDao: Read transformation record (current state)
VideoDao -> continuumImageServicePrimerDb: SELECT transformation state (MySQL)
continuumImageServicePrimerDb --> VideoDao: Current state
VideoDao --> VideoTransformer: Transformation record
VideoTransformer -> GCS: Download source media (GCS API)
GCS --> VideoTransformer: Source video stream
VideoTransformer -> VideoTransformer: Apply ffmpeg transformation (native)
VideoTransformer -> VideoDao: Update transformation state (in-progress)
VideoDao -> continuumImageServicePrimerDb: UPDATE state (MySQL)
VideoTransformer -> S3VideoUploader: Upload transformed video
S3VideoUploader -> S3: PutObject (AWS S3 API)
S3 --> S3VideoUploader: Upload confirmation
VideoTransformer -> VideoDao: Write completed state
VideoDao -> continuumImageServicePrimerDb: UPDATE state = completed (MySQL)
```

## Related

- Architecture dynamic view: `dynamic-video-transformation-flow`
- Related flows: [Daily Image Priming](daily-image-priming.md)
- Data stores: [Data Stores](../data-stores.md) — `continuumImageServicePrimerDb`, S3, GCS
- Events: [Events](../events.md) — video transformation update event
- Deployment: [Deployment](../deployment.md) — `video-transformer-cron` CronJob component
