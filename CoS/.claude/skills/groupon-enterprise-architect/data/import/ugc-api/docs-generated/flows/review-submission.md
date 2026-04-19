---
service: "ugc-api"
title: "Review Submission"
generated: "2026-03-03"
type: flow
flow_name: "review-submission"
flow_type: synchronous
trigger: "Customer submits a review via consumer web or mobile frontend"
participants:
  - "continuumUgcApiService"
  - "continuumUserService"
  - "continuumDealCatalogService"
  - "continuumUgcPostgresPrimary"
  - "continuumUgcRedis"
  - "continuumUgcMessageBus"
  - "continuumEmailService"
architecture_ref: "dynamic-ugcApiService"
---

# Review Submission

## Summary

When a customer submits a review or rating on Groupon, the UGC API receives the answer payload, validates the submission, enriches it with user and deal context, persists it to PostgreSQL, and then publishes a UGC event to the message bus. If a merchant has reply notifications enabled, the email service is invoked to notify the merchant of new reviews. Rate limiting is enforced via Redis to prevent abuse.

## Trigger

- **Type**: api-call
- **Source**: Consumer web or mobile frontend (or merchant MPP portal for merchant replies)
- **Frequency**: On-demand, per customer review action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer Frontend | Initiates review submission | External |
| UGC API Service | Receives, validates, enriches, and persists the review | `continuumUgcApiService` |
| User Service | Provides user identity and profile data for reviewer enrichment | `continuumUserService` |
| Deal Catalog Service | Provides deal metadata to associate with the review | `continuumDealCatalogService` |
| UGC Postgres (Primary) | Stores the submitted answer record | `continuumUgcPostgresPrimary` |
| UGC Redis | Rate limit check on submission | `continuumUgcRedis` |
| UGC Message Bus (JMS) | Receives published UGC answer event | `continuumUgcMessageBus` |
| Email Service | Sends merchant notification email (if applicable) | `continuumEmailService` |

## Steps

1. **Receive answer submission**: Consumer frontend sends `POST /{var}v1.0/answers` with an `AnswerDTO` payload containing rating, content, and reference IDs (merchant/place/deal/consumer IDs).
   - From: Consumer Frontend
   - To: `continuumUgcApiService`
   - Protocol: REST/HTTP

2. **Check rate limit**: UGC API Service checks the submission rate for the consumer against the Redis rate limit store.
   - From: `continuumUgcApiService`
   - To: `continuumUgcRedis`
   - Protocol: Redis protocol

3. **Validate consumer identity**: UGC API Service fetches user identity from the User Service to verify the reviewer exists and is in good standing.
   - From: `continuumUgcApiService`
   - To: `continuumUserService`
   - Protocol: REST/HTTP

4. **Fetch deal context** (when deal-associated review): UGC API Service calls the Deal Catalog Service to fetch deal metadata and validate the deal ID reference.
   - From: `continuumUgcApiService`
   - To: `continuumDealCatalogService`
   - Protocol: REST/HTTP

5. **Persist answer to database**: UGC API Service writes the validated and enriched answer record to the primary PostgreSQL database via JDBI DAO.
   - From: `continuumUgcApiService`
   - To: `continuumUgcPostgresPrimary`
   - Protocol: JDBC

6. **Publish UGC answer event**: UGC API Service publishes a UGC Answer event to the JMS message bus to notify downstream consumers (analytics, SEO, deal rating aggregators).
   - From: `continuumUgcApiService`
   - To: `continuumUgcMessageBus`
   - Protocol: JMS/ActiveMQ

7. **Send merchant notification** (conditional): If merchant notifications are configured for this review context, UGC API Service calls the Email Service to notify the merchant of the new review.
   - From: `continuumUgcApiService`
   - To: `continuumEmailService`
   - Protocol: REST/HTTP

8. **Return answer response**: UGC API Service returns the persisted `Answer` object as JSON (HTTP 200) to the consumer frontend.
   - From: `continuumUgcApiService`
   - To: Consumer Frontend
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Rate limit exceeded | Return HTTP 429; do not persist | Review not submitted; client must retry later |
| User Service unavailable | HTTP 500 or degraded response | Submission fails or proceeds without user enrichment (depends on JTier client config) |
| Deal Catalog unavailable | HTTP 500 or partial response | Deal context missing; review may still persist if reference validation is optional |
| PostgreSQL write failure | JDBI exception propagated | HTTP 500 returned; no event published; review not submitted |
| JMS publish failure | Logged error; write already committed | Review persisted but event not published; downstream consumers miss the event |
| Email Service unavailable | Logged error; does not affect main flow | Merchant not notified; review is still persisted |

## Sequence Diagram

```
ConsumerFrontend -> continuumUgcApiService: POST /{var}v1.0/answers (AnswerDTO)
continuumUgcApiService -> continuumUgcRedis: Check rate limit for consumer
continuumUgcRedis --> continuumUgcApiService: Rate limit OK
continuumUgcApiService -> continuumUserService: GET user identity
continuumUserService --> continuumUgcApiService: User profile
continuumUgcApiService -> continuumDealCatalogService: GET deal metadata
continuumDealCatalogService --> continuumUgcApiService: Deal data
continuumUgcApiService -> continuumUgcPostgresPrimary: INSERT answer record
continuumUgcPostgresPrimary --> continuumUgcApiService: Answer persisted
continuumUgcApiService -> continuumUgcMessageBus: Publish UGC Answer event
continuumUgcApiService -> continuumEmailService: POST merchant notification (if applicable)
continuumUgcApiService --> ConsumerFrontend: HTTP 200 Answer
```

## Related

- Architecture dynamic view: No dynamic views defined in `architecture/views/dynamics.dsl`
- Related flows: [Review Read (Merchant)](review-read-merchant.md), [Content Moderation (Admin)](content-moderation-admin.md)
