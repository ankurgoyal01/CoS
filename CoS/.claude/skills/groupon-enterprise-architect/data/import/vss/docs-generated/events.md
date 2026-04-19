---
service: "vss"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

VSS is a consumer-only participant in the JMS message bus (mbus). It subscribes to five topics covering voucher inventory updates from two inventory sources (VIS v1 and VIS 2.0), user account updates, user email changes, and GDPR user erasures. Consumed events drive near-real-time updates to the local MySQL data store. VSS does not publish events to the message bus.

## Published Events

> No evidence found in codebase. VSS does not publish events to the message bus.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `jms.topic.InventoryUnits.Updated.Voucher_vss_vis.vss_vis` | Inventory Unit Updated (VIS v1) | `inventoryUnitsUpdatedProcessor` | Upserts voucher unit records into VSS MySQL |
| `jms.topic.InventoryUnits.Updated.Vis_vss_vis2.vss_vis2` | Inventory Unit Updated (VIS 2.0) | `inventoryUnitsUpdatedProcessor` | Upserts voucher unit records into VSS MySQL (VIS 2.0 source) |
| `jms.topic.users.account.v1.updated_vss_user.vss_user` | User Account Updated | `usersUpdatedProcessor` | Updates purchaser/consumer user data in VSS MySQL |
| `jms.topic.users.email_change.v1.completed_vss_user.vss_user` | User Email Changed | `usersEmailUpdatedProcessor` | Updates user email in VSS MySQL records |
| `jms.topic.gdpr.account.v1.erased_vss_user_deletion_dev.vss_user_deletion_dev` | GDPR User Erased | `usersDeletionProcessor` | Deletes/obfuscates user PII from VSS MySQL |

### Inventory Unit Updated (VIS v1) Detail

- **Topic**: `jms.topic.InventoryUnits.Updated.Voucher_vss_vis.vss_vis`
- **Handler**: `inventoryUnitsUpdatedProcessor` — receives unit update message, extracts unit UUID and `updatedAt` timestamp, upserts into `continuumVssMySql`
- **Idempotency**: Events are processed and upserted by unit UUID; repeated delivery results in an overwrite of the same record
- **Error handling**: JMS processor errors tracked via Wavefront metric `logging.elastic.vss.VssJMSMsgProcessorErrors.unitUpdateErrorCount`; alerts fire at WARN (400) and SEVERE (500) thresholds
- **Processing order**: Unordered (NONDURABLE subscription in staging)

### Inventory Unit Updated (VIS 2.0) Detail

- **Topic**: `jms.topic.InventoryUnits.Updated.Vis_vss_vis2.vss_vis2`
- **Handler**: `inventoryUnitsUpdatedProcessor` — same handler as VIS v1; distinguished by `inventoryServiceId` field (`vis` vs `voucher`)
- **Idempotency**: Upsert by unit UUID
- **Error handling**: Same error tracking as VIS v1 path
- **Processing order**: Unordered

### User Account Updated Detail

- **Topic**: `jms.topic.users.account.v1.updated_vss_user.vss_user`
- **Handler**: `usersUpdatedProcessor` — delegates to `usersUpdateProcessorHelper` to update purchaser/consumer name and email fields in MySQL
- **Idempotency**: Updates keyed on user account ID
- **Error handling**: JMS processor failure tracked via `logging.elastic.vss.vss-jmsmsg-processor-failure.jmsUserFailure.jmsUserFailCount`; alerts at WARN (1) and SEVERE (100)
- **Processing order**: Unordered

### User Email Changed Detail

- **Topic**: `jms.topic.users.email_change.v1.completed_vss_user.vss_user`
- **Handler**: `usersEmailUpdatedProcessor` — delegates to `usersUpdateProcessorHelper` to update email fields in MySQL records
- **Idempotency**: Updates keyed on user account ID
- **Error handling**: Same JMS error metrics as user update processor
- **Processing order**: Unordered

### GDPR User Erased Detail

- **Topic**: `jms.topic.gdpr.account.v1.erased_vss_user_deletion_dev.vss_user_deletion_dev`
- **Handler**: `usersDeletionProcessor` — removes or obfuscates user PII (first name, last name, email) from all voucher records associated with the erased user IDs
- **Idempotency**: Deletion/obfuscation is idempotent; re-processing already-erased records results in no-op
- **Error handling**: Tracked via JMS error metrics; user update error count metric `logging.elastic.vss.VssJMSMsgProcessorErrors.userUpdateErrorCount`
- **Processing order**: Unordered

## Dead Letter Queues

> No evidence found in codebase. DLQ configuration is managed by the JTier message bus platform; service-level DLQ details are not discoverable from this repository.
