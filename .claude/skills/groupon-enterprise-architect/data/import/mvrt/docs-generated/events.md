---
service: "mvrt"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

MVRT does not use a traditional async messaging system (no Kafka, RabbitMQ, SQS, or internal message bus). Its asynchronous processing model is implemented as a filesystem-based job queue: the web tier writes JSON files to a local directory (`CodesForOfflineSearch/Json_Files/`), and a cron-scheduled background job (every 1 minute) picks up those files and processes them. Outbound notification uses the Rocketman transactional email service for delivering search report links and error alerts to users. There is no pub/sub, event topic, or message queue infrastructure.

## Published Events

> No evidence found in codebase. MVRT does not publish events to any message broker or event topic.

## Consumed Events

> No evidence found in codebase. MVRT does not subscribe to any external event stream or message queue.

## Offline Job Queue (Filesystem-Based)

While not a standard async messaging system, the offline workflow uses a local filesystem queue:

| Queue Mechanism | Type | Trigger | Side Effects |
|----------------|------|---------|-------------|
| `CodesForOfflineSearch/Json_Files/*.json` | Filesystem file drop | `POST /createJsonFile` web request | Offline job scheduler picks up and processes within 1 minute |

### Offline Job Detail

- **Queue directory**: `CodesForOfflineSearch/Json_Files/`
- **Trigger**: `POST /createJsonFile` creates a JSON file with user context, code list, and job parameters
- **Processing**: `offlineProcessing` (Offline Job Scheduler) polls every 1 minute via `node-schedule` cron `'0/1 * * * *'`
- **Lock mechanism**: `lockfile` at `CodesForOfflineSearch/sample.lock` (4-hour stale timeout) ensures only one job runs at a time
- **Error handling**: Failed files are renamed with an error suffix; after `MAX_ATTEMPT_COUNT` (3) failures the file is deleted and an error email is sent via Rocketman
- **Completion**: On success, the report is uploaded to AWS S3 and a notification email is dispatched via Rocketman (`queue: 'cs_deal_notice'`)

## Dead Letter Queues

> Not applicable. No DLQ infrastructure. Failed offline jobs are retried up to 3 times and then deleted, with an error notification email sent to the originating user.
