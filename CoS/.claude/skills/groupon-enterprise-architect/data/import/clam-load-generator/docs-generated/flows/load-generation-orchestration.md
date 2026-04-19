---
service: "clam-load-generator"
title: "Load Generation Orchestration"
generated: "2026-03-03"
type: flow
flow_name: "load-generation-orchestration"
flow_type: batch
trigger: "ApplicationReadyEvent at JVM startup"
participants:
  - "loadGenerationOrchestrator"
  - "strategySelector"
  - "kafkaStrategy"
  - "influxStrategy"
  - "smaStrategy"
architecture_ref: "dynamic-clam-load-generation-flow"
---

# Load Generation Orchestration

## Summary

This is the core execution flow of the CLAM Load Generator. When the Spring Boot application reaches `ApplicationReadyEvent`, `LoadGeneratorApplication.afterApplicationStart()` invokes `LoadGenerator.start()`. The orchestrator resolves the active `LoadGenerationStrategy` (selected by Spring conditional beans based on the `test-target` property), creates a fixed thread pool and a rate limiter, then loops through operation batches until `maxOperations` is reached or the configured `timeout` elapses. After the loop completes, a `LoadGenerationDoneEvent` is published and a summary of SUCCESS/FAILURE counts and operation latency is printed to stdout.

## Trigger

- **Type**: event
- **Source**: Spring Boot `ApplicationReadyEvent` (JVM startup completion)
- **Frequency**: Once per JVM execution (one-shot batch)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| LoadGeneratorApplication | Entry point; listens for `ApplicationReadyEvent` and delegates to `LoadGenerator.start()` | `continuumMetricsClamLoadGenerator` |
| LoadGenerationOrchestrator (`LoadGenerator`) | Manages thread pool, semaphore backpressure, `RateLimiter`, operation loop, timeout, and summary | `loadGenerationOrchestrator` |
| LoadGenerationStrategy Selector | Spring context selects exactly one concrete strategy bean based on `test-target` property | `strategySelector` |
| Active Strategy (`KafkaLoadGenerationStrategy` / `InfluxDbLoadGenerationStrategy` / `SmaLoadGenerationStrategy`) | Implements `before()`, `getNextBatch()`, and `after()` lifecycle | `kafkaStrategy` / `influxStrategy` / `smaStrategy` |

## Steps

1. **Receive application-ready event**: Spring publishes `ApplicationReadyEvent`; `LoadGeneratorApplication.afterApplicationStart()` is invoked.
   - From: `Spring Boot runtime`
   - To: `LoadGeneratorApplication`
   - Protocol: in-process Spring event

2. **Invoke strategy `before()`**: `LoadGenerator.start()` calls `generationStrategy.before(defaultConfig)`, allowing the strategy to initialize connections, discover partitions, and optionally override thread counts.
   - From: `loadGenerationOrchestrator`
   - To: `strategySelector` (active strategy)
   - Protocol: in-process method call

3. **Initialize concurrency controls**: Creates `ExecutorService.newFixedThreadPool(config.getThreads())`, `Semaphore(config.getThreads())` for backpressure, and `RateLimiter.create(config.getRatePerSecond())`.
   - From: `loadGenerationOrchestrator`
   - To: internal JVM concurrency primitives
   - Protocol: in-process

4. **Set timeout timer**: Starts a `Timer` that sets `timeoutExceeded = true` after `config.getTimeout()` milliseconds.
   - From: `loadGenerationOrchestrator`
   - To: internal `Timer`
   - Protocol: in-process

5. **Execute operation batch loop**: While `counter < maxOperations` and `!timeoutExceeded`:
   - Calls `generationStrategy.getNextBatch()` to obtain a list of `Operation` lambdas.
   - For each operation: acquires the semaphore (backpressure), increments counter, submits to the executor.
   - Within the executor thread: acquires a `RateLimiter` permit, records start time, executes `operation.execute()`, measures duration in microseconds, records result in `LoadGenerationSummary`, releases semaphore.
   - From: `loadGenerationOrchestrator`
   - To: active strategy `getNextBatch()`, then backend write operations
   - Protocol: in-process + backend-specific protocol

6. **Shut down executor**: After the loop, calls `executor.shutdown()` and waits up to 10 seconds for termination. If not terminated, calls `executor.shutdownNow()` and logs a warning.
   - From: `loadGenerationOrchestrator`
   - To: `ExecutorService`
   - Protocol: in-process

7. **Invoke strategy `after()`**: Calls `generationStrategy.after()` for final flush/close operations (e.g., Kafka `template.flush()`, InfluxDB `connection.close()`).
   - From: `loadGenerationOrchestrator`
   - To: active strategy
   - Protocol: in-process

8. **Publish completion event**: Publishes `LoadGenerationDoneEvent` via `ApplicationEventPublisher`. `WireMockService` (if enabled) listens and stops the WireMock server.
   - From: `loadGenerationOrchestrator`
   - To: Spring event bus → `WireMockService`
   - Protocol: in-process Spring event

9. **Print summary**: `LoadGenerationSummary.print()` outputs operation counts, success/failure rates, and duration to stdout.
   - From: `loadGenerationOrchestrator`
   - To: stdout
   - Protocol: in-process

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Individual operation returns `OperationResult.FAILURE` | Recorded in `LoadGenerationSummary`; loop continues | FAILURE count incremented; other operations proceed |
| `generator.timeout` elapses | `timeoutExceeded` flag set by `Timer`; loop exits naturally | "Timed out." logged; `after()` and summary still execute |
| Executor does not terminate within 10 seconds | `executor.shutdownNow()` called | Warning logged: "Executor terminated by force." |
| Strategy `before()` throws | Exception propagates up to `afterApplicationStart()` | Application terminates with exception |

## Sequence Diagram

```
SpringBoot -> LoadGeneratorApplication: ApplicationReadyEvent
LoadGeneratorApplication -> LoadGenerator: start()
LoadGenerator -> ActiveStrategy: before(defaultConfig)
ActiveStrategy --> LoadGenerator: effective LoadGenerationProperties
LoadGenerator -> LoadGenerator: create ThreadPool + Semaphore + RateLimiter + Timer
loop [while counter < maxOps AND !timeout]
  LoadGenerator -> ActiveStrategy: getNextBatch()
  ActiveStrategy --> LoadGenerator: List<Operation>
  loop [for each Operation]
    LoadGenerator -> ExecutorThread: submit(operation)
    ExecutorThread -> RateLimiter: acquire()
    ExecutorThread -> Backend: execute write
    Backend --> ExecutorThread: result
    ExecutorThread -> LoadGenerationSummary: addResult(result, durationMicros)
  end
end
LoadGenerator -> ActiveStrategy: after()
LoadGenerator -> SpringEventBus: publish LoadGenerationDoneEvent
LoadGenerator -> stdout: summary.print()
```

## Related

- Architecture dynamic view: `dynamic-clam-load-generation-flow`
- Related flows: [Kafka Load Generation](kafka-load-generation.md), [Telegraf Load Generation](telegraf-load-generation.md), [SMA Load Generation](sma-load-generation.md), [Post-Load Verification](post-load-verification.md)
