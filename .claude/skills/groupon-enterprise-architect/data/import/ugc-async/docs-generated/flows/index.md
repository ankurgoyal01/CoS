---
service: "ugc-async"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for the UGC Async Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Survey Creation from MBus Event](survey-creation-mbus.md) | event-driven | MBus order/purchase event | Creates a survey record when an eligible order/voucher redemption event is received |
| [Survey Sending — Notification Dispatch](survey-sending-notification.md) | scheduled | Quartz scheduler | Fetches pending surveys, evaluates sending eligibility, dispatches email/push/inbox notifications |
| [Goods Survey Creation from Teradata](goods-survey-creation-teradata.md) | scheduled | Quartz scheduler | Batch-reads Goods redemption records from Teradata and creates surveys for eligible orders |
| [S3 Image Migration](s3-image-migration.md) | scheduled | Quartz scheduler | Migrates customer-uploaded images from S3 staging bucket to Image Service |
| [Essence Aspect Aggregation](essence-aspect-aggregation.md) | event-driven | MBus Essence NLP output event | Processes NLP aspect tagging output and updates aggregated place/merchant rating aspect summaries |
| [GDPR Erasure Processing](gdpr-erasure-processing.md) | event-driven | MBus erasure request event | Anonymises user data across surveys, answers, and images in response to GDPR erasure requests |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 3 |
| Batch / Scheduled | 3 |

## Cross-Service Flows

- **Survey Creation from MBus** spans `mbusPlatform_9b1a`, `continuumUgcAsyncService`, `continuumDealCatalogService`, `continuumVoucherInventoryService`, `continuumUsersService`, and `continuumUgcPostgresDb`
- **Survey Sending** spans `continuumUgcAsyncService`, `continuumUgcPostgresDb`, `continuumUsersService`, `rocketmanTransactionalService_1c55`, `rocketmanCommercialService_2d66`, and `crmMessageService_7a44`
- **Essence Aspect Aggregation** spans `essenceAspectTaggingService_4a88`, `continuumUgcAsyncService`, `continuumM3MerchantService`, and `continuumUgcPostgresDb`
