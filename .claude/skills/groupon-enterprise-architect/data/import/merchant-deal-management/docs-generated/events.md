---
service: "merchant-deal-management"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [resque, redis]
---

# Events

## Overview

The Merchant Deal Management service uses Redis-backed Resque as its internal async messaging system. The `continuumDealManagementApi` enqueues jobs to Resque for long-running write flows; the `continuumDealManagementApiWorker` dequeues and executes those jobs. History events are recorded in MySQL by the `dmapiHistoryAndPersistence` component. No external message bus (e.g., Kafka, RabbitMQ) is evidenced in the architecture model.

## Published Events

> No external event topics (Kafka, SQS, MBus, etc.) are evidenced in the architecture DSL. The service publishes internal Resque jobs to Redis queues as its async mechanism.

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| Resque queue (Redis-backed) | Write request job | Inbound HTTP deal write request requiring async processing | Write request parameters, deal ID, operation type |

### Write Request Job Detail

- **Topic**: Resque queue (Redis-backed via `continuumDealManagementApiRedis`)
- **Trigger**: `continuumDealManagementApi` receives an inbound deal write request that requires asynchronous processing; `dmapiAsyncDispatch` enqueues the job
- **Payload**: Write request payload including deal identifiers and operation type (specific fields not resolvable from available inventory)
- **Consumers**: `continuumDealManagementApiWorker` — `dmapiWorkerExecution` component dequeues and executes the job
- **Guarantees**: at-least-once (Resque standard behavior with Redis persistence)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| Resque queue (Redis-backed) | Write request job | `dmapiWorkerExecution` | Persists write request and history record in MySQL; calls downstream services (deal catalog, Salesforce) |

### Write Request Job Consumption Detail

- **Topic**: Resque queue backed by `continuumDealManagementApiRedis`
- **Handler**: `dmapiWorkerExecution` — Resque worker entrypoints executing request and indexed async jobs
- **Idempotency**: Not specified in available inventory
- **Error handling**: Not specified in available inventory; Resque provides built-in retry and failed-job tracking
- **Processing order**: Unordered (Resque queue semantics)

## Dead Letter Queues

> No evidence found in codebase for configured DLQ destinations. Resque provides a built-in failed queue for jobs that raise unhandled exceptions; specific DLQ configuration is not documented in available inventory.

| DLQ | Source Topic | Retention | Alert |
|-----|-------------|-----------|-------|
| Resque failed queue | Resque write request queue | Not specified | Not specified |
