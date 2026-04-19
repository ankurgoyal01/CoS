---
service: "groupon-monorepo"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [encore-pubsub, kafka, stomp-mbus]
---

# Events

## Overview

The Encore Platform uses three asynchronous messaging patterns: (1) Encore's built-in Pub/Sub for intra-platform event-driven communication between TypeScript services, (2) Kafka consumer bridge for ingesting events from the legacy Continuum platform, and (3) STOMP-based message bus (mbus) for publishing events back to Continuum. Over 25 Encore Pub/Sub topics are defined across services, covering deal lifecycle events, notification delivery, CRM synchronization, workflow triggers, and video processing pipelines.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `unit-update` | UnitEvent | Partner order unit status change | unitId, status, orderId |
| `order-update` | OrderEvent | Partner order status change | orderId, status, partnerRef |
| `services-inferred-with-sf-data` | ServicesInferredWithSFDataEvent | AI services inference with Salesforce data complete | merchantId, services, salesforceData |
| `merchant-quality-completed` | MerchantQualityCompletedEvent | Merchant quality scoring complete | merchantId, qualityScore |
| `janus-tier3` | JanusTier3Message | Checkout event received via Janus pipeline | eventType, orderId, checkoutData |
| `send-email` | SendEmailRequest | Email delivery requested | to, subject, template, params |
| `static-video-ready` | StaticVideoReadyEvent | Video processing complete in Mux | videoId, assetId, playbackId |
| `kafka-janus-tier3` | KafkaMessageReceivedEvent | Kafka message consumed from Janus topic | topic, partition, payload |
| `tagging-job-created` | TaggingJobCreatedEvent | Tagging job submitted | jobId, entityType, tags |
| `tagging-job-item-created` | TaggingJobItemCreatedEvent | Individual tagging item queued | jobId, itemId, tag |
| `github-trigger` | GithubTriggerEvent | GitHub webhook received | repo, action, ref |
| `deployment-complete` | DeploymentCompleteEvent | Encore deployment finished | environment, version, status |
| `localhost-app-started` | Timestamp | Local dev server started | timestamp |
| `MBUSSender` | MBUSSenderEvent | Message queued for Continuum message bus | destination, body, headers |
| `sms-update-status` | SmsUpdateStatusEvent | SMS delivery status webhook from Twilio | messageId, status, to |
| `sms-incoming-message-received` | SmsIncomingMessageReceivedEvent | Inbound SMS received via Twilio | from, to, body |
| `send-notification` | CreateNotificationRequest | Push notification delivery requested | userId, title, body, type |
| `custom-field-product-updated` | CustomFieldProductUpdateJob | Custom field value changed on product | productId, fieldId, value |
| `gchat-result` | GChatResultEvent | Google Chat notification delivery result | alertId, chatSpace, status |
| `alert-created` | AlertCreatedEvent | Deal alert triggered | alertId, dealId, alertType |
| `account-updated-in-salesforce` | AccountUpdatedInSalesforceEvent | Account synced to/from Salesforce | accountId, salesforceId, fields |
| `account-updated-internal` | AccountUpdatedInSalesforceEvent | Account updated internally | accountId, fields |
| `deal-version-approval-publish` | ApprovalPublishEvent | Deal version approved for publishing | dealId, versionId, approver |
| `demo-content-created` | DemoContentCreatedEvent | Demo content created (playground) | contentId, type |
| `iq-after-import-logic` | IQAfterImportLogicEvent | IQ deal post-import processing | dealId, importBatchId |
| `iq-deal-sync-trigger-v2` | IQDealSyncTriggerV2TopicEvent | IQ deal sync triggered | dealId, syncType |
| `iq-deals-sync-dmapi` | IQSyncDMAPIEvent | IQ deal DMAPI sync queued | dealId, dmapiAction |
| `iq-deals-sync-redemptions` | IQSyncRedemptionsEvent | IQ deal redemption sync queued | dealId, redemptionData |
| `iq-deals-sync-salesforce` | IQSyncSalesforceEvent | IQ deal Salesforce sync queued | dealId, salesforceFields |

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `kafka-janus-tier3` | KafkaMessageReceivedEvent | checkout-events subscriber | Persists checkout events to PostgreSQL |
| `send-email` | SendEmailRequest | email service subscriber | Sends email via SendGrid |
| `send-notification` | CreateNotificationRequest | notifications subscriber | Persists and delivers push notification |
| `static-video-ready` | StaticVideoReadyEvent | video service subscriber | Updates video record status |
| `MBUSSender` | MBUSSenderEvent | mbus publisher subscriber | Forwards message to Continuum STOMP bus |
| `tagging-job-created` | TaggingJobCreatedEvent | tagging-worker subscriber | Processes bulk tagging job |
| `tagging-job-item-created` | TaggingJobItemCreatedEvent | tagging-worker subscriber | Applies individual tag |
| `custom-field-product-updated` | CustomFieldProductUpdateJob | custom-fields-worker subscriber | Propagates custom field changes |
| `account-updated-in-salesforce` | AccountUpdatedInSalesforceEvent | accounts subscriber | Updates local account record |
| `deal-version-approval-publish` | ApprovalPublishEvent | deal publish subscriber | Publishes deal version to live |
| `alert-created` | AlertCreatedEvent | deal_alerts subscriber | Sends alert to Google Chat |
| `iq-after-import-logic` | IQAfterImportLogicEvent | deal IQ subscriber | Runs post-import enrichment |
| `iq-deal-sync-trigger-v2` | IQDealSyncTriggerV2TopicEvent | deal_sync subscriber | Triggers deal synchronization |
| `services-inferred-with-sf-data` | ServicesInferredWithSFDataEvent | aidg subscriber | Processes AI-inferred merchant services |
| `merchant-quality-completed` | MerchantQualityCompletedEvent | aidg subscriber | Updates merchant quality records |
| `salesforce-sync` (cron) | Scheduled | aidg cron handler | Periodic Salesforce data sync |
| `unit-update` | UnitEvent | partner_order_sync subscriber | Syncs order unit to partner system |
| `order-update` | OrderEvent | partner_order_sync subscriber | Syncs order status to partner system |
| `sms-update-status` | SmsUpdateStatusEvent | sms subscriber | Updates SMS delivery record |
| `sms-incoming-message-received` | SmsIncomingMessageReceivedEvent | sms subscriber | Processes inbound SMS |

## Dead Letter Queues

Encore's built-in Pub/Sub manages retry and delivery guarantees. Failed messages are retried with exponential backoff per Encore's default configuration. No explicit DLQ configuration is visible in the codebase; undeliverable messages are handled by Encore Cloud's infrastructure.

| DLQ | Source Topic | Retention | Alert |
|-----|-------------|-----------|-------|
| Encore-managed | All Pub/Sub topics | Platform default | Encore Cloud dashboard |
