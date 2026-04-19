---
service: "vouchercloud-idl"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [sns, sqs, mbus]
---

# Events

## Overview

Vouchercloud IDL publishes events via two async mechanisms: AWS SNS for lifecycle notifications (offer rejection, community codes, offer invalidation, user feedback, rewards failures, gift merchant mapping failures) and AWS SQS for analytics event ingestion. An optional Groupon MessageBus (STOMP/Thrift) producer client (`IDL.Api.Client.MessageBus`) is also available for publishing events to the internal STOMP broker. No event consumption from queues or topics is implemented in this service; all event processing is fire-and-publish only.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `arn:aws:sns:eu-west-1:147964333254:Vouchercloud-{env}-OfferRejection` | OfferRejection | User reports an offer as rejected/invalid | offerId, reason, userId |
| `arn:aws:sns:eu-west-1:147964333254:Vouchercloud-{env}-CommunityCodes` | CommunityCodeSubmission | User submits a community voucher code | offerId, code, userId |
| `arn:aws:sns:eu-west-1:147964333254:Vouchercloud-{env}-OfferInvalidation` | OfferInvalidation | Offer marked as invalid by internal process | offerId |
| `arn:aws:sns:eu-west-1:147964333254:Vouchercloud-{env}-UserFeedback` | UserFeedback | User submits feedback | userId, feedbackContent |
| `arn:aws:sns:eu-west-1:147964333254:Vouchercloud-{env}-RewardsInitialiseFailed` | RewardsInitialiseFailed | External reward (Giftcloud) initialisation failure | userId, rewardId, errorDetail |
| `arn:aws:sns:eu-west-1:147964333254:Vouchercloud-{env}-GiftMerchantMappingNotFoundEvent` | GiftMerchantMappingNotFound | No Giftcloud merchant mapping found for an offer | offerId, merchantId |
| `https://staging-events.vouchercloud.com/147964333254/VcEventQueue` (SQS) | AnalyticsEvent | User interaction events (clicks, redeems, affiliate visits) | eventType, userId, offerId, sessionId |

### OfferRejection Detail

- **Topic**: `arn:aws:sns:eu-west-1:147964333254:Vouchercloud-{env}-OfferRejection` (env = `Staging` or `Release` suffix differs by environment)
- **Trigger**: `POST /offers/{id}/reject` — user reports an offer as expired or invalid
- **Payload**: offerId, rejection reason, requesting userId
- **Consumers**: Downstream offer moderation pipeline (not within this repo)
- **Guarantees**: at-least-once (AWS SNS standard)

### CommunityCodeSubmission Detail

- **Topic**: `arn:aws:sns:eu-west-1:147964333254:Vouchercloud-{env}-CommunityCodes`
- **Trigger**: `POST /offers/communitycode` — authenticated user submits a voucher code
- **Payload**: offerId, submitted code string, userId
- **Consumers**: Offer community code ingestion pipeline
- **Guarantees**: at-least-once

### AnalyticsEvent Detail (SQS)

- **Topic**: SQS queue at `https://staging-events.vouchercloud.com/147964333254/VcEventQueue` (staging). Production URL configured via `analyticsSqsQueueUrl` in `Web.config`. Lambda-backed delivery configured via `analyticsUseSqsLambda="true"`.
- **Trigger**: User interaction events — affiliate clicks, offer redeems, site visits
- **Payload**: eventType, userId, offerId, sessionId, timestamp
- **Consumers**: Analytics pipeline (AWS Lambda)
- **Guarantees**: at-least-once

### MessageBus (STOMP) Events

- **Protocol**: Groupon internal STOMP 1.0 message broker, messages serialised with Apache Thrift (`messagebus.thrift`)
- **Trigger**: Configured via `MessageBusConfiguration.TopicDestination` at runtime
- **Payload structure**: `MessageInternal { messageId, payload: MessagePayload { messageFormat (JSON/BINARY/STRING), stringPayload, binaryPayload }, properties }`
- **Consumers**: Determined by topic destination at configuration time
- **Guarantees**: at-most-once (fire-and-forget STOMP send)

## Consumed Events

> No evidence found in codebase. This service does not subscribe to any message queue or topic. All event flows are publish-only.

## Dead Letter Queues

> No evidence found in codebase of DLQ configuration within this repository. Infrastructure-level DLQs may be configured in AWS.
