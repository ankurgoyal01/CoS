---
service: "optimus-prime-ui"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [internal-eventbus]
---

# Events

## Overview

Optimus Prime UI does not publish or consume external async messaging systems such as Kafka, RabbitMQ, or SQS. All asynchronous coordination within the browser application is handled by an internal Vue-based EventBus (`src/events/index.js`). The EventBus connects the Background Polling Tasks component to the Application State Store and the root App component, enabling decoupled update propagation when the background polling detects changes in job execution state.

## Published Events (Internal EventBus — browser only)

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `EventBus` | `onExecutionAdd` | Background task detects a new execution for a job | `execution` object |
| `EventBus` | `onExcutionUpdate` | Background task receives updated execution state | `execution` object |
| `EventBus` | `onJobsUpdate` | Background task receives updated job metadata | `jobs` array |
| `EventBus` | `onDatafetcherAdd` | Background task detects a new datafetcher run | `runId` string |
| `EventBus` | `onDatafetcherUpdate` | Background task receives updated datafetcher state | `datafetcher` object |
| `EventBus` | `onDataloaderAdd` | Background task detects a new dataloader run | `runId` string |
| `EventBus` | `onDataloaderUpdate` | Background task receives updated dataloader state | `dataloader` object |
| `EventBus` | `onEmptyResponseBody` | API client receives an empty body in a response | `exception` object |
| `EventBus` | `onHealthCheckError` | Background task detects a failed health check | none |
| `EventBus` | `onHealthCheckOk` | Background task detects health check recovery | none |
| `EventBus` | `onError` | Vue or window error handler captures a runtime error (dev mode only) | `text`, `messages` |

### Internal EventBus Detail

- **Implementation**: `src/events/index.js` — a bare Vue instance used as a pub/sub bus (`new Vue()`)
- **Trigger**: Emitted by `BackgroundTasks` browser timer loops and by the Axios error interceptor
- **Consumers**: `App.vue` `mounted()` lifecycle hook registers listeners for all events above
- **Side effects**: `onExcutionUpdate` calls `jobStore.updateJobExecution`; `onJobsUpdate` calls `jobStore.updateJobsMetaData`; `onDatafetcherUpdate` calls `datafetcherStore.updateDatafetcher`; `onDataloaderUpdate` calls `dataloaderStore.updateDataloader`; `onEmptyResponseBody` and health check events call `GA.methods.gaException`
- **Guarantees**: at-most-once (in-memory, browser-scoped; events are lost on page refresh)

## Consumed Events

> This service does not consume external async events. All event consumption is from the internal EventBus described above.

## Dead Letter Queues

> Not applicable. No external messaging system is used.
