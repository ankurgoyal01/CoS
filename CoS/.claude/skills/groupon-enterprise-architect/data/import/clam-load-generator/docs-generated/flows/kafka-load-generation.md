---
service: "clam-load-generator"
title: "Kafka Load Generation"
generated: "2026-03-03"
type: flow
flow_name: "kafka-load-generation"
flow_type: batch
trigger: "test-target=kafka Spring profile active at startup"
participants:
  - "kafkaStrategy"
  - "partitionSender"
  - "topicStrategy"
  - "metricLineFactory"
architecture_ref: "dynamic-clam-load-generation-flow"
---

# Kafka Load Generation

## Summary

When `test-target=kafka` is set in the active Spring profile, the `KafkaLoadGenerationStrategy` is activated. It discovers all available partitions for the configured topic (`kafka.topic`, typically `histograms_v2`), overrides the thread count to match partition count, and then — for each batch iteration — generates one JSON-encoded `Line` metric payload per partition and sends it via `KafkaTemplate`. The Kafka producer uses snappy compression, 128 KB batching, and 100 ms linger to maximize throughput. After all operations complete, producer statistics are logged and the template is flushed.

## Trigger

- **Type**: event
- **Source**: Spring Boot `ApplicationReadyEvent` with `test-target=kafka` profile active
- **Frequency**: Once per JVM execution; batch loop runs until `maxOperations` or `timeout`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| KafkaLoadGenerationStrategy | Discovers partitions, overrides thread count, implements batch generation and post-flush | `kafkaStrategy` |
| PartitionSender | Creates per-partition `Line` payloads and sends them as JSON to the `KafkaTemplate` | `partitionSender` |
| TopicStrategy | Computes the Kafka message key from the `Line`'s tag values (default: `bucket_key` tag) | `topicStrategy` |
| MetricLineFactory / LineServiceFactory | Constructs `Line` objects with metric name, dimension tags, field values, and nanosecond timestamp | `metricLineFactory` |
| Apache Kafka (external) | Receives and durably stores the metric payload messages for downstream CLAM processing | external |

## Steps

1. **Discover partitions** (`before()` phase): Calls `kafkaTemplate.partitionsFor(defaultTopic)` to obtain the list of `PartitionInfo` objects for the configured topic.
   - From: `kafkaStrategy`
   - To: Apache Kafka broker (`kafka.broker-address`)
   - Protocol: Kafka metadata request

2. **Select partitions**: Applies `partitionStrategy.select(availablePartitions)` (SEQUENTIAL or RANDOM, configurable via `test.strategies.partition-selector`; optionally limited to `test.strategies.partition-count` partitions).
   - From: `kafkaStrategy`
   - To: `PartitionStrategy` (in-process)
   - Protocol: in-process

3. **Override thread count**: Returns a new `LoadGenerationProperties` with `threads = partitions.size()` so the orchestrator creates exactly one thread per partition.
   - From: `kafkaStrategy`
   - To: `loadGenerationOrchestrator`
   - Protocol: in-process return value

4. **Generate operation batch** (`getNextBatch()`): Maps each `PartitionInfo` to an `Operation` lambda that calls `partitionSender.send(kafkaTemplate, partitionInfo)`.
   - From: `kafkaStrategy`
   - To: `partitionSender`
   - Protocol: in-process

5. **Build metric line**: `PartitionSender.send()` calls `lineServiceFactory.createLineService(partitionId).createLine()` to produce a `Line` object with randomized metric name, cluster/source dimension tags, field values, and a nanosecond timestamp.
   - From: `partitionSender`
   - To: `metricLineFactory` / `LineServiceFactory`
   - Protocol: in-process

6. **Compute message key**: Calls `topicStrategy.select(line)` to extract and join tag values for the configured `test.strategies.topic-keys` (default: `bucket_key` tag value).
   - From: `partitionSender`
   - To: `topicStrategy`
   - Protocol: in-process

7. **Serialize and publish**: Serializes the `Line` to JSON with `ObjectMapper`, then calls `kafkaTemplate.sendDefault(partitionId, key, jsonPayload + "\n")` to publish to the configured partition.
   - From: `partitionSender`
   - To: Apache Kafka (`histograms_v2` topic, specific partition)
   - Protocol: Kafka producer (snappy compression, 128 KB batch, 100 ms linger)

8. **Periodic producer stats reporting**: A background `Reporter` timer logs Kafka producer metrics (`producer-metrics`, `producer-topic-metrics`) every 120 seconds during the load run.
   - From: `KafkaLoadGenerationStrategy.Reporter`
   - To: slf4j logger (stdout)
   - Protocol: in-process

9. **Flush and report** (`after()` phase): Starts the `Reporter` (logs final stats), calls `kafkaTemplate.flush()` to drain the producer buffer, then stops the `Reporter` for a final stats print.
   - From: `kafkaStrategy`
   - To: Apache Kafka (flush), logger
   - Protocol: Kafka producer flush

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `JsonProcessingException` during `Line` serialization | Caught in `Operation` lambda; returns `OperationResult.FAILURE` | FAILURE recorded in summary; partition continues in next batch |
| Kafka broker unreachable at partition discovery | Exception propagates from `kafkaTemplate.partitionsFor()` | Application fails to start load generation |
| Kafka send failure (async producer error) | Producer error callback not explicitly configured; errors may be silent at the application level | Kafka producer internal retries apply; message may be lost |

## Sequence Diagram

```
KafkaLoadGenerationStrategy -> KafkaBroker: partitionsFor(histograms_v2)
KafkaBroker --> KafkaLoadGenerationStrategy: List<PartitionInfo>
KafkaLoadGenerationStrategy -> PartitionStrategy: select(partitions)
PartitionStrategy --> KafkaLoadGenerationStrategy: selected partitions
loop [for each batch iteration, per partition]
  KafkaLoadGenerationStrategy -> PartitionSender: send(kafkaTemplate, partitionInfo)
  PartitionSender -> LineServiceFactory: createLineService(partitionId).createLine()
  LineServiceFactory --> PartitionSender: Line (name, tags, fields, timestamp)
  PartitionSender -> TopicStrategy: select(line)
  TopicStrategy --> PartitionSender: messageKey (e.g., bucket_key value)
  PartitionSender -> ObjectMapper: writeValueAsString(line)
  ObjectMapper --> PartitionSender: jsonPayload
  PartitionSender -> KafkaTemplate: sendDefault(partitionId, key, jsonPayload)
  KafkaTemplate -> KafkaBroker: produce (snappy, 128KB batch, 100ms linger)
end
KafkaLoadGenerationStrategy -> KafkaTemplate: flush()
```

## Related

- Architecture dynamic view: `dynamic-clam-load-generation-flow`
- Related flows: [Load Generation Orchestration](load-generation-orchestration.md)
