---
service: "kafka"
title: "Partition Leadership Failover"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "partition-leadership-failover"
flow_type: event-driven
trigger: "Broker failure detected by KRaft controller or operator-initiated partition reassignment"
participants:
  - "continuumKafkaController"
  - "kafkaControllerQuorumManager"
  - "kafkaControllerBrokerLifecycle"
  - "kafkaControllerMetadataLoader"
  - "continuumKafkaBroker"
  - "kafkaBrokerReplicaManager"
  - "continuumKafkaMetadataLog"
architecture_ref: "dynamic-kafka-kraft-cluster-control"
---

# Partition Leadership Failover

## Summary

When a broker hosting partition leaders becomes unavailable, the KRaft controller detects the failure through its broker lifecycle tracking, selects new leaders from each partition's in-sync replica set, and propagates the leadership change to the remaining brokers. Producers and consumers experience a brief pause while their clients refresh metadata and reconnect to the new leader.

## Trigger

- **Type**: event
- **Source**: Broker heartbeat timeout detected by `kafkaControllerBrokerLifecycle`, or operator issues a partition reassignment command
- **Frequency**: On-demand (failure event or operator action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Broker Lifecycle Manager | Detects broker failure through missed heartbeats and initiates fencing | `kafkaControllerBrokerLifecycle` |
| Quorum Manager | Coordinates writing the leadership change as a metadata record to the KRaft log | `kafkaControllerQuorumManager` |
| Metadata Loader | Applies committed metadata records to the controller's in-memory state | `kafkaControllerMetadataLoader` |
| KRaft Metadata Log | Durably stores the new partition leader assignment | `continuumKafkaMetadataLog` |
| Kafka Controller | Pushes metadata update (new leader) to all alive brokers | `continuumKafkaController` |
| Kafka Broker (new leader) | Promotes itself to leader role for affected partitions | `continuumKafkaBroker` (new leader), `kafkaBrokerReplicaManager` |
| Kafka Broker (followers) | Updates in-memory partition metadata; begins fetching from new leader | `continuumKafkaBroker` (remaining replicas) |

## Steps

1. **Detects broker failure**: `kafkaControllerBrokerLifecycle` detects that the failed broker has not sent a heartbeat within the configured timeout; marks the broker as fenced
   - From: `continuumKafkaBroker` (failed broker, heartbeat stops)
   - To: `kafkaControllerBrokerLifecycle`
   - Protocol: RPC (KRaft heartbeat protocol)

2. **Selects new partition leaders**: Broker Lifecycle Manager identifies all partitions whose leader was on the failed broker; selects the first ISR member as the new leader for each partition
   - From: `kafkaControllerBrokerLifecycle`
   - To: `kafkaControllerQuorumManager`
   - Protocol: direct (in-process, within controller)

3. **Writes leadership change to metadata log**: Quorum Manager appends a `PartitionChangeRecord` (or equivalent metadata record) for each affected partition to `continuumKafkaMetadataLog`
   - From: `kafkaControllerQuorumManager`
   - To: `continuumKafkaMetadataLog`
   - Protocol: Filesystem I/O (KRaft log append)

4. **Applies metadata update to in-memory state**: `kafkaControllerMetadataLoader` reads the committed records and updates the controller's in-memory partition map to reflect the new leaders
   - From: `continuumKafkaMetadataLog`
   - To: `kafkaControllerMetadataLoader`
   - Protocol: Filesystem I/O (log replay)

5. **Publishes metadata update to brokers**: Active controller sends a `LeaderAndIsrRequest` (or metadata delta) to all alive brokers, informing them of the new partition leaders
   - From: `continuumKafkaController`
   - To: `continuumKafkaBroker` (all alive brokers)
   - Protocol: RPC

6. **New leader begins accepting requests**: The broker selected as new leader activates its local replica as leader; `kafkaBrokerReplicaManager` begins serving produce and fetch requests for the affected partitions
   - From: `kafkaBrokerReplicaManager` (on new leader broker)
   - To: `continuumKafkaLogStorage`
   - Protocol: Filesystem I/O

7. **Clients refresh metadata and reconnect**: Producer and consumer clients receive `NOT_LEADER_OR_FOLLOWER` on their next request, call `Metadata` API, and reconnect to the new leader broker
   - From: `Producer / Consumer Client`
   - To: `kafkaBrokerNetworkApi` (new leader)
   - Protocol: Kafka Wire Protocol (TCP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| ISR is empty (all replicas are down) | No new leader can be elected without `unclean.leader.election.enable=true` | Partition remains offline; alert fires on `OfflinePartitionsCount` |
| Unclean leader election enabled | Controller elects any out-of-sync replica as leader (data loss risk) | Partition comes back online but may have lost messages since last ISR member was in sync |
| Controller itself fails during failover | KRaft quorum elects a new active controller from remaining voters; failover retried | Brief additional delay; metadata log ensures no leadership state is lost |
| Network partition (broker appears dead but is alive) | Fenced broker continues serving stale data until it discovers it has been fenced | Producer clients with `acks=-1` will not lose data; fenced broker rejects further writes |

## Sequence Diagram

```
continuumKafkaBroker (failed) -> kafkaControllerBrokerLifecycle: Heartbeat timeout
kafkaControllerBrokerLifecycle -> kafkaControllerQuorumManager:  Initiate leader election for affected partitions
kafkaControllerQuorumManager -> continuumKafkaMetadataLog:       Append PartitionChangeRecord (new leader)
continuumKafkaMetadataLog --> kafkaControllerMetadataLoader:     Committed metadata records
kafkaControllerMetadataLoader -> kafkaControllerQuorumManager:   In-memory state updated
continuumKafkaController -> continuumKafkaBroker (new leader):   LeaderAndIsrRequest (become leader)
continuumKafkaController -> continuumKafkaBroker (followers):    UpdateMetadataRequest (new leader address)
kafkaBrokerReplicaManager (new leader) -> continuumKafkaLogStorage: Activate leader log
Producer/Consumer -> kafkaBrokerNetworkApi (new leader):         Metadata refresh and reconnect
```

## Related

- Architecture dynamic view: `dynamic-kafka-kraft-cluster-control`
- Related flows: [KRaft Metadata Replication](kraft-metadata-replication.md), [Message Produce and Replication](message-produce-and-replication.md)
