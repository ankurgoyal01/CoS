---
service: "gazebo"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Gazebo participates in Groupon's internal Message Bus (`mbusSystem_18ea34`) for asynchronous event exchange. The `continuumGazeboMbusConsumer` container subscribes to deal, opportunity, task, and notification topics produced by upstream systems. The `continuumGazeboWebApp` publishes editorial copy change events when content is updated or published. The Messagebus gem (v0.2.8) is used for both publishing and consuming.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `editorial/copy` | copy change event | Content update or publish action by editor | deal identifier, copy treatment data, change type, timestamp |

### Copy Change Event Detail

- **Topic**: `editorial/copy`
- **Trigger**: An editor saves or publishes updated deal copy via the Gazebo web application
- **Payload**: Deal identifier, updated copy treatment fields, change type (update/publish), timestamp
- **Consumers**: Known downstream consumers tracked in the central architecture model
- **Guarantees**: at-least-once (Messagebus client behavior)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `deal.updated` | Deal data change | Deal Updated Handler | Updates local deal records in MySQL |
| `opportunity.changed` | Salesforce opportunity change | Opportunity Changed Handler | Updates opportunity-linked deal data in MySQL |
| `goods_task` | New goods editorial task | Task Notification Handler | Creates or updates task records in MySQL |
| `task_notification` | General task state change | Task Notification Handler | Updates task state in MySQL |
| `contract_stage_notification` | Contract stage progression | Contract/Info Request Handler | Updates contract stage on related deal/task records |
| `information_request_notification` | Information request event | Contract/Info Request Handler | Creates or updates information request records in MySQL |

### deal.updated Detail

- **Topic**: `deal.updated`
- **Handler**: Deal Updated Handler in `continuumGazeboMbusConsumer` — updates local deal record fields in MySQL
- **Idempotency**: No explicit evidence; update-on-receipt pattern assumed
- **Error handling**: No evidence of DLQ or retry configuration in inventory
- **Processing order**: unordered

### opportunity.changed Detail

- **Topic**: `opportunity.changed`
- **Handler**: Opportunity Changed Handler — maps Salesforce opportunity changes to deal records in MySQL
- **Idempotency**: No explicit evidence
- **Error handling**: No evidence of DLQ or retry configuration in inventory
- **Processing order**: unordered

### goods_task Detail

- **Topic**: `goods_task`
- **Handler**: Task Notification Handler — creates new task entries or updates existing task records
- **Idempotency**: No explicit evidence
- **Error handling**: No evidence of DLQ or retry configuration in inventory
- **Processing order**: unordered

### task_notification Detail

- **Topic**: `task_notification`
- **Handler**: Task Notification Handler — processes general task state change notifications
- **Idempotency**: No explicit evidence
- **Error handling**: No evidence of DLQ or retry configuration in inventory
- **Processing order**: unordered

### contract_stage_notification Detail

- **Topic**: `contract_stage_notification`
- **Handler**: Contract/Info Request Handler — updates contract stage fields on deal and task records
- **Idempotency**: No explicit evidence
- **Error handling**: No evidence of DLQ or retry configuration in inventory
- **Processing order**: unordered

### information_request_notification Detail

- **Topic**: `information_request_notification`
- **Handler**: Contract/Info Request Handler — creates or updates information request records
- **Idempotency**: No explicit evidence
- **Error handling**: No evidence of DLQ or retry configuration in inventory
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found in codebase. Dead letter queue configuration not discovered in inventory.
