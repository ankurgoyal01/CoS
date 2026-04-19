---
service: "mx-merchant-access"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

The Merchant Access Service is a pure consumer of asynchronous events — it does not publish any events. It subscribes to three MBus topics published by the users-service, each representing an account lifecycle change. When one of these events is received, MAS deletes all merchant contacts and primary contact associations for the affected account, maintaining referential integrity of the access graph.

MBus consumers are enabled conditionally via the `mbus.enabled` configuration property. Each consumer is a durable subscriber backed by the `commons-mbus` library.

## Published Events

> No evidence found in codebase. This service does not publish async events.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `${mbus.dest.name.account_deactivated}` | account_deactivated | `AccountDeactivatedMessageHandler` | Deletes all merchant contacts and removes primary contact assignments for the deactivated account |
| `${mbus.dest.name.account_erased}` | account_erased | `AccountErasedMessageHandler` | Deletes all merchant contacts and removes primary contact assignments for the erased account |
| `${mbus.dest.name.account_merged}` | account_merged | `AccountMergedMessageHandler` | Deletes all merchant contacts for the merge-loser account (identified by `mergeLoserAccountId`) |

### account_deactivated Detail

- **Topic**: configured via `mbus.dest.name.account_deactivated` property
- **Handler**: `AccountDeactivatedMessageHandler` — extends `AbstractAccountDeletedMessageHandler`
- **Payload fields**: `accountId` (UUID), `deactivatedAt` (ISO 8601 timestamp), `publishedAt` (ISO 8601 timestamp)
- **Idempotency**: Handler looks up all contacts by account UUID before deleting; no-op if no contacts found
- **Error handling**: Exceptions are caught, logged via operations log, and the message is ACK'd to prevent redelivery loops
- **Processing order**: unordered

### account_erased Detail

- **Topic**: configured via `mbus.dest.name.account_erased` property
- **Handler**: `AccountErasedMessageHandler` — extends `AbstractAccountDeletedMessageHandler`
- **Payload fields**: `accountId` (UUID), `erasedAt` (ISO 8601 timestamp), `publishedAt` (ISO 8601 timestamp)
- **Idempotency**: Handler looks up all contacts by account UUID before deleting; no-op if none found
- **Error handling**: Exceptions are caught, logged, and ACK'd
- **Processing order**: unordered

### account_merged Detail

- **Topic**: configured via `mbus.dest.name.account_merged` property
- **Handler**: `AccountMergedMessageHandler` — extends `AbstractAccountDeletedMessageHandler`
- **Payload fields**: `mergeWinnerAccountId` (UUID), `mergeLoserAccountId` (UUID), `mergedAt` (ISO 8601 timestamp), `publishedAt` (ISO 8601 timestamp), `deviceTrackingId` (nullable)
- **Idempotency**: Operates on the merge-loser account UUID; no-op if no contacts found for that account
- **Error handling**: Exceptions are caught, logged via ops log, and ACK'd
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found in codebase for explicit DLQ configuration.
