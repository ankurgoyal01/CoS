---
service: "kafka"
title: "Log Compaction and Retention"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "log-compaction-and-retention"
flow_type: scheduled
trigger: "Log Manager background cleaner thread wakes on a configurable interval"
participants:
  - "continuumKafkaBroker"
  - "kafkaBrokerLogManager"
  - "continuumKafkaLogStorage"
architecture_ref: "dynamic-kafka-kraft-cluster-control"
---

# Log Compaction and Retention

## Summary

The Log Manager runs a background cleaner thread that periodically scans each topic-partition log for segments eligible for deletion or compaction. Time-based and size-based retention deletes old segments to reclaim disk space. Log compaction retains only the most recent record per message key, enabling compacted topics (like `__consumer_offsets` and Kafka Streams changelog topics) to serve as indefinitely readable key-value snapshots.

## Trigger

- **Type**: schedule
- **Source**: `kafkaBrokerLogManager` background cleaner thread
- **Frequency**: Controlled by `log.cleaner.backoff.ms` (default 15 seconds) and `log.retention.check.interval.ms` (default 5 minutes)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Log Manager | Orchestrates cleaner thread; decides which segments to delete or compact | `kafkaBrokerLogManager` |
| Kafka Log Storage | Stores segment files that are read, rewritten, and deleted during cleanup | `continuumKafkaLogStorage` |
| Kafka Broker | Hosts the Log Manager; ensures partitions remain accessible during background cleanup | `continuumKafkaBroker` |

## Steps

### Delete Retention Path

1. **Cleaner thread wakes**: `kafkaBrokerLogManager`'s retention checker wakes after `log.retention.check.interval.ms` and evaluates all partition logs on this broker
   - From: `kafkaBrokerLogManager` (scheduled thread)
   - To: `continuumKafkaLogStorage` (read segment metadata)
   - Protocol: Filesystem I/O

2. **Identifies deletable segments**: For each partition, Log Manager computes the total log size and the age of each closed segment; segments older than `log.retention.ms` or causing the log to exceed `log.retention.bytes` are marked for deletion
   - From: `kafkaBrokerLogManager` (internal)
   - To: `kafkaBrokerLogManager` (internal)
   - Protocol: direct (in-process)

3. **Deletes eligible segments**: Log Manager removes the `.log`, `.index`, and `.timeindex` files for each deletable segment from `continuumKafkaLogStorage`; the log start offset advances to the base offset of the oldest remaining segment
   - From: `kafkaBrokerLogManager`
   - To: `continuumKafkaLogStorage`
   - Protocol: Filesystem I/O (file delete)

### Compaction Path (for `cleanup.policy=compact` topics)

4. **Compaction thread wakes**: Log cleaner thread wakes and selects the partition with the highest `dirty ratio` (proportion of uncompacted records) that exceeds `min.cleanable.dirty.ratio`
   - From: `kafkaBrokerLogManager` (cleaner thread)
   - To: `continuumKafkaLogStorage`
   - Protocol: Filesystem I/O

5. **Builds offset map**: Cleaner reads the dirty (uncompacted) portion of the log and builds an in-memory key-to-latest-offset map, identifying which records are superseded by a newer record with the same key
   - From: `kafkaBrokerLogManager` (internal)
   - To: `continuumKafkaLogStorage`
   - Protocol: Filesystem I/O (sequential read)

6. **Writes compacted segments**: Cleaner rewrites each dirty segment, emitting only the latest record per key (tombstone records with null values are retained for `delete.retention.ms` before final removal); new segments are written to temporary files, then atomically swapped in
   - From: `kafkaBrokerLogManager`
   - To: `continuumKafkaLogStorage`
   - Protocol: Filesystem I/O (write new segment, atomic rename)

7. **Removes superseded segments**: Original dirty segment files are deleted; the partition's log start offset and cleaned offset are updated
   - From: `kafkaBrokerLogManager`
   - To: `continuumKafkaLogStorage`
   - Protocol: Filesystem I/O (file delete)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Disk full during compaction | Compaction pauses and logs error; broker continues serving reads/writes but cannot compact | `log.cleaner.io.max.bytes.per.second` throttle can relieve disk pressure; operator must free disk space |
| Compaction running too slow | `min.compaction.lag.ms` prevents compaction of recently written records; cleaner skips ahead | Dirty ratio may grow; no data loss but disk usage increases |
| Segment file corrupted | Log Manager marks the partition offline for that broker; replicas on other brokers continue serving | Partition leader moves to another broker via leadership failover |
| Tombstone premature deletion | Tombstones are held for at least `delete.retention.ms`; consumers that have not caught up may miss deletes | Consumers must process tombstones before they expire to maintain a consistent view |

## Sequence Diagram

```
kafkaBrokerLogManager (cleaner) -> continuumKafkaLogStorage: Read segment metadata (sizes, timestamps)
kafkaBrokerLogManager           -> kafkaBrokerLogManager:    Evaluate retention rules (age, size)
kafkaBrokerLogManager           -> continuumKafkaLogStorage: Delete expired segments (.log/.index/.timeindex)

kafkaBrokerLogManager (compactor) -> continuumKafkaLogStorage: Sequential read of dirty segments
kafkaBrokerLogManager             -> kafkaBrokerLogManager:   Build key-to-latest-offset map
kafkaBrokerLogManager             -> continuumKafkaLogStorage: Write compacted segment to temp files
kafkaBrokerLogManager             -> continuumKafkaLogStorage: Atomic rename (replace dirty with compacted)
kafkaBrokerLogManager             -> continuumKafkaLogStorage: Delete old dirty segment files
```

## Related

- Architecture dynamic view: `dynamic-kafka-kraft-cluster-control`
- Related flows: [Message Produce and Replication](message-produce-and-replication.md), [Kafka Streams Stateful Processing](kafka-streams-stateful-processing.md)
