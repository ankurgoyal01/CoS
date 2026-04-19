---
service: "kafka"
title: "Message Produce and Replication"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "message-produce-and-replication"
flow_type: synchronous
trigger: "Producer client sends a Produce API request to the leader broker for a topic-partition"
participants:
  - "continuumKafkaBroker"
  - "kafkaBrokerNetworkApi"
  - "kafkaBrokerReplicaManager"
  - "kafkaBrokerLogManager"
  - "continuumKafkaLogStorage"
architecture_ref: "dynamic-kafka-kraft-cluster-control"
---

# Message Produce and Replication

## Summary

A producer client submits a batch of records to the leader broker for a topic-partition. The broker validates the request, appends the record batch to the local segment file, and waits for the configured number of in-sync replicas (ISR) to acknowledge replication before responding to the producer. This flow ensures durability and ordered delivery for all Continuum event streams.

## Trigger

- **Type**: api-call
- **Source**: Any Continuum service acting as a Kafka producer (via Kafka client library)
- **Frequency**: Per-request (high throughput, continuous)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kafka Producer Client | Initiates the produce request with a record batch | External (Continuum service) |
| Network API | Receives and decodes the Produce API request frame | `kafkaBrokerNetworkApi` |
| Replica Manager | Validates ISR state, coordinates append and replication acknowledgement | `kafkaBrokerReplicaManager` |
| Log Manager | Appends record batch to the active segment file | `kafkaBrokerLogManager` |
| Kafka Log Storage | Persists the segment file on disk | `continuumKafkaLogStorage` |
| Follower Brokers | Fetch and replicate the record batch from the leader | `continuumKafkaBroker` (follower instances) |

## Steps

1. **Receives produce request**: Producer sends a Produce API request (key `0`) containing the topic-partition, `acks` setting, and record batch
   - From: `Producer Client`
   - To: `kafkaBrokerNetworkApi`
   - Protocol: Kafka Wire Protocol (TCP)

2. **Validates request and ISR**: Network API hands request to Replica Manager; Replica Manager checks that the broker is the current leader for the partition and that the ISR meets the `min.insync.replicas` requirement
   - From: `kafkaBrokerNetworkApi`
   - To: `kafkaBrokerReplicaManager`
   - Protocol: direct (in-process)

3. **Appends record batch to local log**: Replica Manager instructs Log Manager to write the record batch to the active segment file for the partition
   - From: `kafkaBrokerReplicaManager`
   - To: `kafkaBrokerLogManager`
   - Protocol: direct (in-process)

4. **Persists segment to storage**: Log Manager writes the record batch bytes to `continuumKafkaLogStorage`; optionally flushes based on `log.flush.interval.messages` or `log.flush.interval.ms`
   - From: `kafkaBrokerLogManager`
   - To: `continuumKafkaLogStorage`
   - Protocol: Filesystem I/O

5. **Replicates to follower brokers**: Each follower broker's Replica Manager issues a Fetch request to the leader to pull the new records; leader responds with the record batch
   - From: `continuumKafkaBroker` (follower, via `kafkaBrokerReplicaManager`)
   - To: `continuumKafkaBroker` (leader, via `kafkaBrokerNetworkApi`)
   - Protocol: Kafka Wire Protocol (TCP)

6. **Updates ISR and acknowledges**: Once the required number of ISR followers have fetched the records (tracked by Replica Manager), the leader sends a Produce response with `error_code=0` back to the producer
   - From: `kafkaBrokerReplicaManager` -> `kafkaBrokerNetworkApi`
   - To: `Producer Client`
   - Protocol: Kafka Wire Protocol (TCP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `NOT_LEADER_OR_FOLLOWER` | Producer client receives error, refreshes metadata, retries against new leader | Producer retries transparently |
| `NOT_ENOUGH_REPLICAS` | Broker rejects produce if ISR < `min.insync.replicas` with `acks=-1` | Producer receives `NOT_ENOUGH_REPLICAS_AFTER_APPEND`; retries with backoff |
| Follower replication lag | Leader removes lagging follower from ISR; produce can still succeed if remaining ISR meets minimum | Partition becomes under-replicated; alert fires |
| Disk full on leader | Log Manager throws `KafkaStorageException`; broker shuts down affected log dir | Partition goes offline; Replica Manager on other brokers promotes a new leader |

## Sequence Diagram

```
Producer            -> kafkaBrokerNetworkApi:    Produce request (records, acks=-1)
kafkaBrokerNetworkApi -> kafkaBrokerReplicaManager: Validate and route produce request
kafkaBrokerReplicaManager -> kafkaBrokerLogManager: Append record batch to partition log
kafkaBrokerLogManager -> continuumKafkaLogStorage:  Write segment bytes to disk
continuumKafkaLogStorage --> kafkaBrokerLogManager: Write acknowledged
kafkaBrokerLogManager --> kafkaBrokerReplicaManager: Append complete, log end offset returned
FollowerBroker      -> kafkaBrokerNetworkApi:    Fetch request (replica fetch, fetchOffset)
kafkaBrokerNetworkApi --> FollowerBroker:         Record batch response
FollowerBroker      -> kafkaBrokerReplicaManager: Update follower fetch offset (ISR ack)
kafkaBrokerReplicaManager --> kafkaBrokerNetworkApi: ISR quorum met, produce acknowledged
kafkaBrokerNetworkApi --> Producer:              Produce response (error_code=0, base_offset)
```

## Related

- Architecture dynamic view: `dynamic-kafka-kraft-cluster-control`
- Related flows: [Message Consumption and Offset Commit](message-consumption-and-offset-commit.md), [Partition Leadership Failover](partition-leadership-failover.md), [Log Compaction and Retention](log-compaction-and-retention.md)
