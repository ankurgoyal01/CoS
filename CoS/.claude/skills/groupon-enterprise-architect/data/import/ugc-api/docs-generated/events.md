---
service: "ugc-api"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus, jms, activemq]
---

# Events

## Overview

The UGC API publishes UGC lifecycle events to the `continuumUgcMessageBus` (JMS/ActiveMQ) via the `ugcApiIntegrations` component. Events are emitted when content is submitted, updated, or moderated. The service is listed as a dependency on `mbus` in `.service.yml`. No event consumption from external topics was found in the repository source; the service is primarily a publisher.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `continuumUgcMessageBus` | UGC Answer Event | Answer (review/rating) submitted or deleted | answer ID, merchant ID, place ID, consumer ID, rating, content |
| `continuumUgcMessageBus` | UGC Image Event | Image action submitted (upload, like, flag) | image ID, merchant ID, place ID, user ID, action type, status |
| `continuumUgcMessageBus` | UGC Video Event | Video action submitted or video updated | video ID, merchant ID, deal ID, user ID, action type, status |
| `continuumUgcMessageBus` | UGC Survey Event | Survey marked viewed or completed | survey ID, dispatch ID, consumer ID, status, voucher ID |

### UGC Answer Event Detail

- **Topic**: `continuumUgcMessageBus`
- **Trigger**: Successful answer submission via `POST /{var}v1.0/answers` or answer deletion via `DELETE /{var}v1.0/answers/{id}`
- **Payload**: Answer ID, associated merchant/place/deal IDs, consumer ID, rating value, review text, timestamp
- **Consumers**: Known downstream consumers include SEO pipelines, deal rating aggregators, and analytics systems (not federated into this model)
- **Guarantees**: at-least-once (JMS/ActiveMQ default)

### UGC Image Event Detail

- **Topic**: `continuumUgcMessageBus`
- **Trigger**: Image action submission via `POST /{var}v1.0/images`
- **Payload**: Image ID, merchant/place/deal IDs, user ID, action type (upload, helpfulness vote, flag), image URL, moderation status
- **Consumers**: Image moderation pipelines; CDN invalidation consumers (not federated)
- **Guarantees**: at-least-once (JMS/ActiveMQ default)

### UGC Video Event Detail

- **Topic**: `continuumUgcMessageBus`
- **Trigger**: Video action submission via `POST /v1.0/videos` or influencer video update
- **Payload**: Video ID, merchant ID, deal ID, user ID, action type, video URL, status
- **Consumers**: Video moderation pipelines (not federated)
- **Guarantees**: at-least-once (JMS/ActiveMQ default)

### UGC Survey Event Detail

- **Topic**: `continuumUgcMessageBus`
- **Trigger**: Survey marked viewed or completed via `POST /v1.0/surveys/{surveyId}/viewed` or `/completed`
- **Payload**: Survey ID, dispatch ID, consumer ID, voucher ID, completion status, timestamp
- **Consumers**: Post-redemption survey analytics, marketing systems (not federated)
- **Guarantees**: at-least-once (JMS/ActiveMQ default)

## Consumed Events

> No evidence found in codebase of the UGC API consuming events from external topics. The service initiates all processing in response to inbound HTTP requests.

## Dead Letter Queues

> No evidence found in codebase of DLQ configuration. Dead letter queue configuration is managed at the ActiveMQ broker level.
