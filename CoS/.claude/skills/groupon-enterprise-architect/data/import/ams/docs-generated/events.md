---
service: "ams"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [kafka]
---

# Events

## Overview

AMS uses Kafka as its sole async messaging system. It publishes audience lifecycle events when published audiences are created and does not consume any Kafka topics. The `ams_integrationClients` component owns the Kafka producer adapter, invoked by `ams_jobLaunchers` at the completion of a published audience Spark workflow.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `audience_ams_pa_create` | Published Audience Create | Successful completion of a published audience Spark job | Audience ID, audience metadata, creation timestamp |

### `audience_ams_pa_create` Detail

- **Topic**: `audience_ams_pa_create`
- **Trigger**: A sourced or joined audience Spark job completes successfully, resulting in a newly available published audience record
- **Payload**: Audience identifier, audience metadata, and creation timestamp; full schema managed by the Audience Service / CRM team
- **Consumers**: Ads targeting systems, CRM pipelines, reporting workloads — tracked in the central architecture model
- **Guarantees**: at-least-once

## Consumed Events

> Not applicable. AMS does not consume any Kafka topics.

## Dead Letter Queues

> No evidence found for configured DLQs associated with the `audience_ams_pa_create` producer. Contact the Audience Service / CRM team for retry and error handling policy.
