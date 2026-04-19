---
service: "kafka"
title: "Message Consumption and Offset Commit"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "message-consumption-and-offset-commit"
flow_type: synchronous
trigger: "Consumer client sends a Fetch API request with a topic-partition and start offset"
participants:
  - "continuumKafkaBroker"
  - "kafkaBrokerNetworkApi"
  - "kafkaBrokerLogManager"
  - "continuumKafkaLogStorage"
architecture_ref: "dynamic-kafka-kraft-cluster-control"
---

# Message Consumption and Offset Commit

## Summary

A consumer client polls the leader broker for records starting at a tracked offset in a topic-partition. The broker reads the relevant segment files and returns a batch of records. The consumer processes the records and then commits the new offset back to the broker via the `OffsetCommit` API. This cycle drives all Continuum event-driven processing.

## Trigger

- **Type**: api-call
- **Source**: Any Continuum service acting as a Kafka consumer (via Kafka client library)
- **Frequency**: Per-request (continuous polling loop, typically every 100–500 ms)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kafka Consumer Client | Issues Fetch request and processes returned records | External (Continuum service) |
| Network API | Receives Fetch and OffsetCommit request frames | `kafkaBrokerNetworkApi` |
| Log Manager | Reads records from segment files at the requested offset | `kafkaBrokerLogManager` |
| Kafka Log Storage | Provides segment file data to Log Manager | `continuumKafkaLogStorage` |
| Group Coordinator (broker) | Manages consumer group membership and offset storage | `kafkaBrokerNetworkApi` (coordinator broker) |

## Steps

1. **Locates group coordinator**: Consumer calls `FindCoordinator` API (key `10`) to discover which broker hosts its consumer group
   - From: `Consumer Client`
   - To: `kafkaBrokerNetworkApi`
   - Protocol: Kafka Wire Protocol (TCP)

2. **Joins consumer group**: Consumer calls `JoinGroup` (key `11`) and `SyncGroup` (key `14`) to enter the group and receive its partition assignment
   - From: `Consumer Client`
   - To: `kafkaBrokerNetworkApi` (coordinator broker)
   - Protocol: Kafka Wire Protocol (TCP)

3. **Fetches committed offset**: Consumer calls `OffsetFetch` (key `9`) to retrieve the last committed offset for its assigned partitions
   - From: `Consumer Client`
   - To: `kafkaBrokerNetworkApi`
   - Protocol: Kafka Wire Protocol (TCP)

4. **Sends Fetch request**: Consumer sends Fetch API request (key `1`) specifying the topic-partition and `fetch_offset`; broker queues a long-poll response up to `fetch.max.wait.ms`
   - From: `Consumer Client`
   - To: `kafkaBrokerNetworkApi`
   - Protocol: Kafka Wire Protocol (TCP)

5. **Reads records from log**: Log Manager locates the starting offset via the partition index file, then reads sequential record batches from `continuumKafkaLogStorage`
   - From: `kafkaBrokerNetworkApi`
   - To: `kafkaBrokerLogManager`
   - Protocol: direct (in-process)

6. **Loads segment data**: Log Manager reads segment bytes from the filesystem (served from OS page cache for hot data)
   - From: `kafkaBrokerLogManager`
   - To: `continuumKafkaLogStorage`
   - Protocol: Filesystem I/O

7. **Returns record batch**: Broker sends Fetch response containing record batches up to `max.partition.fetch.bytes`
   - From: `kafkaBrokerNetworkApi`
   - To: `Consumer Client`
   - Protocol: Kafka Wire Protocol (TCP)

8. **Processes records**: Consumer application processes each record in the batch (business logic, not modeled here)

9. **Commits offset**: Consumer sends `OffsetCommit` request (key `8`) to the group coordinator broker with the new offset for each partition
   - From: `Consumer Client`
   - To: `kafkaBrokerNetworkApi` (coordinator broker)
   - Protocol: Kafka Wire Protocol (TCP)

10. **Stores offset**: Coordinator broker appends the offset record to the `__consumer_offsets` internal topic and responds with success
    - From: `kafkaBrokerNetworkApi`
    - To: `continuumKafkaLogStorage` (via `__consumer_offsets` partition log)
    - Protocol: Filesystem I/O

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `OFFSET_OUT_OF_RANGE` | Broker returns error if requested offset is below log start offset (data expired) | Consumer resets to `earliest` or `latest` per `auto.offset.reset` policy |
| `REBALANCE_IN_PROGRESS` | Coordinator signals consumer group rebalance; consumer rejoins | Consumer re-executes JoinGroup/SyncGroup; processing pauses briefly |
| Consumer crash before commit | Offset not updated; records reprocessed after restart | At-least-once delivery; consumer application must handle duplicates |
| Coordinator broker down | Client retries `FindCoordinator` until a new coordinator is elected | Brief delay; processing resumes after coordinator election |

## Sequence Diagram

```
Consumer            -> kafkaBrokerNetworkApi:    FindCoordinator request
kafkaBrokerNetworkApi --> Consumer:              Coordinator broker address
Consumer            -> kafkaBrokerNetworkApi:    JoinGroup / SyncGroup (partition assignment)
kafkaBrokerNetworkApi --> Consumer:              Assigned partition list
Consumer            -> kafkaBrokerNetworkApi:    OffsetFetch (last committed offset)
kafkaBrokerNetworkApi --> Consumer:              Committed offset per partition
Consumer            -> kafkaBrokerNetworkApi:    Fetch request (fetch_offset)
kafkaBrokerNetworkApi -> kafkaBrokerLogManager:  Read records at offset
kafkaBrokerLogManager -> continuumKafkaLogStorage: Read segment bytes
continuumKafkaLogStorage --> kafkaBrokerLogManager: Record batch bytes
kafkaBrokerLogManager --> kafkaBrokerNetworkApi: Record batch
kafkaBrokerNetworkApi --> Consumer:              Fetch response (record batches)
Consumer            -> kafkaBrokerNetworkApi:    OffsetCommit (new offset)
kafkaBrokerNetworkApi -> continuumKafkaLogStorage: Append to __consumer_offsets
kafkaBrokerNetworkApi --> Consumer:              OffsetCommit response (success)
```

## Related

- Architecture dynamic view: `dynamic-kafka-kraft-cluster-control`
- Related flows: [Message Produce and Replication](message-produce-and-replication.md), [Partition Leadership Failover](partition-leadership-failover.md)
