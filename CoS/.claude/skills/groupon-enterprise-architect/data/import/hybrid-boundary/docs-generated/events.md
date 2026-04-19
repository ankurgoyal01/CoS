---
service: "hybrid-boundary"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

Hybrid Boundary does not publish or consume asynchronous events via a message broker (no Kafka, RabbitMQ, SQS, or similar). Asynchronous coordination is handled through AWS Step Functions state machines for traffic shift orchestration, and through AWS Auto Scaling lifecycle notifications that trigger the RRDNS Lambda. These are AWS-native control-plane events, not domain events on a message bus.

## Published Events

> No evidence found in codebase. Hybrid Boundary does not publish domain events to a message broker.

## Consumed Events

> No evidence found in codebase. The RRDNS Lambda consumes AWS Auto Scaling lifecycle events directly via the Lambda invocation mechanism, not via a message broker.

## Dead Letter Queues

> No evidence found in codebase.

## AWS Step Functions Integration (Internal Async Coordination)

Although not a traditional message bus, the following asynchronous coordination occurs via AWS Step Functions:

| Trigger | State Machine | Effect |
|---------|--------------|--------|
| `POST /v1/services/{serviceName}/{domainName}/shift` | `continuumHybridBoundaryStepFunctions` | Starts iterative traffic shift; invokes `continuumHybridBoundaryLambdaIterator` at each step |
| Shift step completion | `continuumHybridBoundaryStepFunctions` | Invokes `continuumHybridBoundaryLambdaRrdns` for DNS sync on lifecycle events |

The `STATE_MACHINE_ARN` environment variable configures which Step Functions state machine the API Lambda targets.
