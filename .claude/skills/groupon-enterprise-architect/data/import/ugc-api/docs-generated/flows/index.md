---
service: "ugc-api"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for UGC API.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Review Submission](review-submission.md) | synchronous | API call from consumer frontend | Customer submits a review/rating for a merchant, place, or deal |
| [Review Read (Merchant)](review-read-merchant.md) | synchronous | API call from consumer frontend or SEO API | Retrieve paginated reviews and rating summary for a merchant |
| [Image Upload](image-upload.md) | asynchronous | API call — two-phase upload | Customer submits an image via S3 pre-signed URL then records the image action |
| [Survey Lifecycle](survey-lifecycle.md) | synchronous | API calls from mobile/web app | Survey is dispatched, viewed, replied to, and marked completed |
| [Content Moderation (Admin)](content-moderation-admin.md) | synchronous | Admin API call from moderation tooling | Admin searches, reviews, and takes moderation action on UGC content |
| [UGC Transfer Between Merchants](ugc-transfer.md) | synchronous | Admin API call during merchant consolidation | All UGC is copied or transferred from a source merchant to a destination merchant |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- **Review Submission** involves `continuumUgcApiService`, `continuumUserService`, `continuumDealCatalogService`, `continuumUgcPostgresPrimary`, `continuumUgcMessageBus`, and `continuumEmailService`.
- **Survey Lifecycle** involves `continuumUgcApiService`, `continuumOrdersService`, `continuumUgcPostgresPrimary`, `continuumUgcS3`, and `continuumUgcMessageBus`.
- **Image Upload** involves `continuumUgcApiService`, `continuumUgcS3`, `continuumImageService`, and `continuumUgcPostgresPrimary`.

See the central architecture dynamic views for cross-service sequence diagrams (no dynamic views are currently defined in `architecture/views/dynamics.dsl`).
