---
service: "breakage-reduction-service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

BRS does not publish or consume async events directly from Kafka or a message bus in its primary request path. All notification scheduling is performed synchronously by calling the RISE scheduler API over HTTPS. However, the production configuration references an mbus (message bus) topic for RISE integration, indicating that RISE may internally consume a voucher topic. BRS itself acts as a producer of scheduled jobs into RISE — not a direct event publisher.

## Published Events

> No evidence found in codebase of BRS directly publishing events to a message bus topic. Notification scheduling is delegated to RISE via HTTP POST to `/rise/v1/adhoc`.

## Consumed Events

> No evidence found in codebase of BRS consuming events from a message bus topic. BRS is triggered exclusively via inbound HTTP requests.

## RISE Scheduler Integration (Scheduled Jobs)

While not a classic event system, BRS submits ad-hoc scheduled job commands to RISE, which acts as an internal notification scheduler. This is the primary async mechanism.

| Target | Operation | Trigger | Description |
|--------|-----------|---------|-------------|
| RISE `/rise/v1/adhoc` | POST (schedule) | Reminder request or backfill call | Enqueues a notification workflow command in RISE for future delivery |
| RISE `/rise/v1/bucket/{bucket}/{type}/{key}` | GET/PUT/PATCH/DELETE | Workflow engine state updates | Reads or updates workflow bucket state for a voucher |
| RISE `/rise/v1/tracking/commands` | GET | Workflow engine initialization | Fetches existing workflow commands for a consumer/voucher |

## mbus Topic Reference (Production Config)

The production configuration (`config/stage/production.cson`) references an mbus topic:

| Topic | Purpose |
|-------|---------|
| `jms.topic.rise.voucher` | RISE voucher notification pipeline topic (referenced in `serviceClient.mbus.topics.rise`; consumed by RISE, not directly by BRS) |

## Dead Letter Queues

> No evidence found in codebase. DLQ configuration is not owned by BRS.
