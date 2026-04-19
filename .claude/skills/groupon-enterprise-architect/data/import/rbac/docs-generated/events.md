---
service: "rbac"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

The RBAC service is an event consumer only. It subscribes to two MBus (Groupon internal STOMP-based message bus) topics to receive Salesforce user lifecycle events. When a Salesforce user is created or updated, the RBAC service consumes the event, resolves the user's RBAC-internal account via the Users Service, clears previously Salesforce-assigned roles, and re-assigns roles based on the configured Salesforce profile-to-role mapping. The service does not publish any async events.

## Published Events

> No evidence found in codebase. The RBAC service does not publish any async events to MBus or other messaging systems.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| MBus topic configured via `mbus.consumers.sfUserCreateListener.destinationName` | Salesforce User Created | `SFUserCreateMBusListener` → `SFMessageProcessor` → `SalesforceProfileProcessor` | Resolves user accounts in both NA and EMEA regions; clears existing SF-assigned roles; assigns new roles per profile mapping |
| MBus topic configured via `mbus.consumers.sfUserUpdateListener.destinationName` | Salesforce User Updated | `SFUserUpdateMBusListener` → `SFMessageProcessor` → `SalesforceProfileProcessor` | Same side effects as user-created event |

### Salesforce User Created Event Detail

- **Topic**: Configured at runtime via `mbus.consumers.sfUserCreateListener.destinationName`
- **Handler**: `SFUserCreateMBusListener` receives the raw MBus message; `SFMessageProcessor` deserializes it to `SFUserProfile`; `SalesforceProfileProcessor` performs the role assignment logic
- **Listener enabled by**: property `mbus.consumers.sfUserCreateListener.enabled=true`
- **Idempotency**: Re-entrant — on each event, all existing Salesforce-assigned roles are cleared before re-assigning, making repeated processing safe
- **Error handling**: On exception, `SFMessageProcessor` calls `consumer.nack(ackId)` to reject the message; no explicit dead-letter queue configuration found in codebase
- **Processing order**: Unordered (thread-pool executor with size configured via `mbus.threadPoolSize`)

### Salesforce User Updated Event Detail

- **Topic**: Configured at runtime via `mbus.consumers.sfUserUpdateListener.destinationName`
- **Handler**: `SFUserUpdateMBusListener` → `SFMessageProcessor` → `SalesforceProfileProcessor` (identical processing pipeline to create)
- **Listener enabled by**: property `mbus.consumers.sfUserUpdateListener.enabled=true`
- **Idempotency**: Same clear-and-reassign pattern as create event
- **Error handling**: `consumer.nack(ackId)` on failure
- **Processing order**: Unordered (shared thread-pool executor)

### SFUserProfile Payload Fields

The `SFUserProfile` message model includes:

| Field | JSON Key | Description |
|-------|----------|-------------|
| `profileId` | `ProfileId` | Salesforce profile identifier; used to look up the RBAC role mapping |
| `email` | `Email` | User email address; used to resolve user UUID via Users Service |
| `id` | `Id` (from MBus messageId) | Salesforce user ID |
| `isActive` | `IsActive` | Whether the user is active; inactive users have roles cleared but none assigned |
| `userRoleId` | `userroleid` | Salesforce role ID; used to filter which regions receive role assignments |
| `fullName` | `Full_Name__c` | Display name |
| `systemModstamp` | `SystemModstamp` | Last modification timestamp from Salesforce |

## Dead Letter Queues

> No evidence found in codebase of explicit dead-letter queue configuration for the MBus consumers.
