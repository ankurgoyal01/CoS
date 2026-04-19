---
service: "billing-record-service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Billing Record Service participates in the Groupon Message Bus (mbus) as both a consumer and a producer. It consumes two categories of inbound messages: GDPR Individual Rights Request (IRR) erasure commands (published by the Regulatory Consent Log Service) and token-deletion commands (published by PCI-related workflows). It publishes IRR completion acknowledgement events back to the Message Bus after successfully erasing PII from billing records. The `messagebus.enabled` configuration flag controls whether message bus connectivity is active; it can be set to `false` for local development.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| erasure completion topic (mbus) | `IndividualRightsRequestCompletion` | GDPR IRR erasure successfully applied to all purchaser billing records | `accountId`, `erasedAt`, `publishedAt`, `serviceId` |

### IndividualRightsRequestCompletion Detail

- **Topic**: Erasure completion topic on Groupon Message Bus (qualifier: `erasure`)
- **Trigger**: After the `IndividualRightsRequestHandlerScheduler` has processed an inbound IRR erasure message, scrubbed PII from all billing records for the affected purchaser, and set status to `IRR_FORGOTTEN`
- **Payload**: JSON object with fields `accountId` (UUID), `erasedAt` (ISO-8601 datetime), `publishedAt` (ISO-8601 datetime), `serviceId` (string: `"billing-record-service"`)
- **Consumers**: Downstream compliance and audit services that track GDPR erasure completion
- **Guarantees**: at-least-once (Groupon mbus STOMP/JMS delivery)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| erasure topic (mbus) | `IndividualRightsRequestPayload` | `IndividualRightsRequestHandlerScheduler` | Scrubs all PII from billing address and payment data fields; sets billing record status to `IRR_FORGOTTEN`; calls PCI-API to delete token if token is not shared with other purchasers; publishes completion event |
| token erasure topic (mbus) | `DeleteTokenMessage` | `DeleteTokenScheduler` | Checks whether the token is still required by any billing record; if not required, calls PCI-API to delete the token |

### IndividualRightsRequestPayload Detail

- **Topic**: GDPR erasure topic on Groupon Message Bus (qualifier: `erasure`)
- **Handler**: `IndividualRightsRequestHandlerScheduler` — polls the message bus, deserializes the payload, and invokes `BillingRecordResourceService` GDPR erasure logic
- **Payload fields**: `accountId` (UUID), `erasedAt` (datetime), `publishedAt` (datetime)
- **Side effects**: Replaces all PII fields in `BillingAddress` and `PaymentData` with a GDPR replacement string; sets `BillingRecordStatus` to `IRR_FORGOTTEN`; conditionally calls PCI-API to delete the associated token
- **Idempotency**: Records already in `IRR_FORGOTTEN` status are not re-processed
- **Error handling**: Message is not acknowledged on failure; Groupon mbus handles redelivery
- **Processing order**: Unordered

### DeleteTokenMessage Detail

- **Topic**: Token erasure topic on Groupon Message Bus (qualifier: `tokenerasure`)
- **Handler**: `DeleteTokenScheduler` — polls the message bus and invokes `BillingRecordResourceService.isTokenRequired()` to determine whether the token is still in use
- **Payload fields**: `action` (string), `tokenId` (string)
- **Side effects**: If the token is no longer referenced by any active billing record, calls PCI-API to delete the token; otherwise takes no action
- **Idempotency**: Token deletion check is based on current DB state, so re-delivery is safe
- **Error handling**: Groupon mbus handles redelivery on failure
- **Processing order**: Unordered

## Dead Letter Queues

> No evidence found in codebase. DLQ configuration, if any, is managed externally in the Groupon mbus infrastructure.
