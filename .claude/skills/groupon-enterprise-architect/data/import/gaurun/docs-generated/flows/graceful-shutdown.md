---
service: "gaurun"
title: "Graceful Shutdown Flow"
generated: "2026-03-03"
type: flow
flow_name: "graceful-shutdown"
flow_type: event-driven
trigger: "SIGTERM signal from Kubernetes"
participants:
  - "continuumGaurunPushNotificationService"
  - "gaurunHttpApi"
  - "gaurunKafkaProducer"
  - "gaurunKafkaConsumer"
  - "gaurunPushWorkerManager"
  - "gaurunRetryProcessor"
architecture_ref: "GaurunComponents"
---

# Graceful Shutdown Flow

## Summary

When Kubernetes terminates a Gaurun Pod (rolling deployment, scale-down, or node eviction), it sends `SIGTERM` to the main process. Gaurun responds by stopping the HTTP server from accepting new connections, cancelling the context for Kafka producers, consumers, and the retry processor, waiting up to `core.shutdown_timeout` seconds for all push worker goroutines to complete, then exiting. The Logstash sidecar's `preStop` lifecycle hook runs a `sleep 60` to allow remaining log records to drain before the container is killed.

Additionally, `SIGHUP` triggers a log file rotation (reopens log file handles) without stopping the service.

## Trigger

- **Type**: event
- **Source**: Kubernetes `SIGTERM` signal (pod termination)
- **Frequency**: On pod restart, rolling deployment, or scale-down event

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kubernetes | Sends SIGTERM to main process | External |
| HTTP Server | Stops accepting new connections on SIGTERM | `gaurunHttpApi` |
| Kafka Producers | Stop producing on context cancellation | `gaurunKafkaProducer` |
| Kafka Consumers | Stop consuming and close queues on context cancellation | `gaurunKafkaConsumer` |
| Push Worker Manager | Finishes in-flight push goroutines; tracked by `PusherWg` | `gaurunPushWorkerManager` |
| Retry Processor | Stops consuming `mta.gaurun.retry` on context cancellation | `gaurunRetryProcessor` |
| Logstash Sidecar | Drains remaining log records before container kill | (Sidecar container) |

## Steps

1. **Kubernetes sends SIGTERM**: Pod termination sequence begins. Kubernetes routes `SIGTERM` to the Gaurun main process.
   - From: Kubernetes
   - To: `continuumGaurunPushNotificationService` (main process)
   - Protocol: OS signal

2. **Signal received by main goroutine**: `<-sigTERMChan` unblocks. Main goroutine proceeds with shutdown sequence.
   - From: Signal handler goroutine
   - To: Main goroutine
   - Protocol: Go channel

3. **Cancel context**: `ctx.Done()` is invoked, propagating cancellation to all goroutines that were started with the shared context — Kafka producer goroutines (`StartKafkaProducers`), Kafka consumer goroutines (`StartKafkaConsumer`), and the retry processor (`StartRetryQueueProcessorNew`, `StartRetryQueueWorkersNew`).
   - From: Main goroutine
   - To: Kafka producers, consumers, retry processor goroutines
   - Protocol: Go context cancellation

4. **HTTP server graceful shutdown**: `server.Shutdown(ctx)` is called with a timeout context (`core.shutdown_timeout` seconds, default 30 in production). The HTTP server stops accepting new connections and waits for active requests to complete within the timeout.
   - From: Main goroutine
   - To: `gaurunHttpApi`
   - Protocol: In-process

5. **Kafka producers stop**: Producer goroutines detect `<-ctx.Done()` in their select loop and exit. In-flight Kafka publishes complete or time out.
   - From: Context cancellation
   - To: `gaurunKafkaProducer`
   - Protocol: Go context

6. **Kafka consumers close queues**: Consumer goroutines detect `<-ctx.Done()`, call `queues.Close()`, and return. Kafka consumer connections are closed with `defer k.consumer.Close()`.
   - From: Context cancellation
   - To: `gaurunKafkaConsumer`
   - Protocol: Go context

7. **Retry processor stops**: `RetryQueueProcessorNew` goroutine detects context done; `ConsumeRetryRecord` closes `messageChan`. Processor exits its `for` loop.
   - From: Context cancellation
   - To: `gaurunRetryProcessor`
   - Protocol: Go context

8. **Wait for push workers**: Main goroutine calls `PusherWg.Wait()`, blocking until all push worker goroutines (tracked via `PusherWg.Add(1)` / `PusherWg.Done()`) complete their in-flight APNs/FCM calls.
   - From: Main goroutine
   - To: `gaurunPushWorkerManager`
   - Protocol: `sync.WaitGroup`

9. **Exit**: Once `PusherWg.Wait()` returns, main goroutine logs `"successfully shutdown"` and the process exits cleanly.
   - From: Main goroutine
   - To: OS
   - Protocol: Process exit

10. **Logstash sidecar drains**: Kubernetes runs the Logstash sidecar `preStop` hook (`sleep 60`) before killing the container. Logstash continues tailing and shipping log files for up to 60 seconds after the main container exits.
    - From: Kubernetes lifecycle hook
    - To: Logstash sidecar
    - Protocol: OS process

### SIGHUP (Log Rotation)

When `SIGHUP` is received (e.g., from a log rotation daemon), the `sigHUPChan` goroutine calls `accessLogReopener.Reopen()`, `errorLogReopener.Reopen()`, and `acceptLogReopener.Reopen()` via the `client9/reopen` library. Log file handles are reopened without restarting the service.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| HTTP server does not drain within `shutdown_timeout` | `server.Shutdown(ctx)` returns timeout error; logged | Process continues to `PusherWg.Wait()` |
| Push worker goroutines exceed shutdown timeout | `PusherWg.Wait()` blocks indefinitely until all workers finish | Pod may be force-killed by Kubernetes `terminationGracePeriodSeconds` |
| Kafka consumer cannot close cleanly | Logged; goroutine returns | In-flight Kafka messages may be redelivered on next startup (at-least-once) |
| Retry processor messageChan not drained | Unconsumed retry messages remain in Kafka topic | Consumed on next Pod startup (offset reset `earliest`) |

## Sequence Diagram

```
Kubernetes -> Gaurun process: SIGTERM
Gaurun main -> ctx: Cancel()
Gaurun main -> HTTP server: server.Shutdown(ctx, timeout=30s)
KafkaProducer goroutines -> ctx.Done(): detect cancel; exit
KafkaConsumer goroutines -> ctx.Done(): detect cancel; close queues; exit
RetryProcessor -> ctx.Done(): detect cancel; close messageChan; exit
Gaurun main -> PusherWg: Wait() (block until all push goroutines done)
PusherWg -> Gaurun main: all done
Gaurun main -> OS: exit 0
Kubernetes -> Logstash sidecar: preStop: sleep 60
Logstash -> Kafka: drain remaining send/fail log records
```

## Related

- Architecture component view: `GaurunComponents`
- Deployment: [Deployment](../deployment.md) — pod lifecycle and Logstash sidecar preStop configuration
- Runbook: [Runbook](../runbook.md) — Restart Service section
- Configuration: [Configuration](../configuration.md) — `core.shutdown_timeout`
