---
service: "kafka"
title: "KRaft Metadata Replication"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "kraft-metadata-replication"
flow_type: asynchronous
trigger: "KRaft active controller appends a metadata record (topic creation, partition reassignment, broker registration, config change, etc.)"
participants:
  - "continuumKafkaController"
  - "kafkaControllerQuorumManager"
  - "kafkaControllerMetadataLoader"
  - "continuumKafkaMetadataLog"
  - "continuumKafkaBroker"
  - "kafkaBrokerReplicaManager"
architecture_ref: "dynamic-kafka-kraft-cluster-control"
---

# KRaft Metadata Replication

## Summary

The KRaft controller quorum maintains cluster metadata (topic configurations, partition assignments, broker registrations, ACLs) as a replicated Raft log stored in `continuumKafkaMetadataLog`. When the active controller processes any administrative change, it appends a metadata record; follower controllers replicate that record; and all brokers asynchronously fetch the committed metadata to update their in-memory state.

## Trigger

- **Type**: event
- **Source**: Administrative API call (create topic, delete topic, reassign partitions, alter config, broker registration) directed at `kafkaBrokerNetworkApi` and forwarded to `continuumKafkaController`
- **Frequency**: On-demand (each admin or cluster state change)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Quorum Manager (active controller) | Appends metadata record to the KRaft log; coordinates quorum acknowledgement | `kafkaControllerQuorumManager` |
| KRaft Metadata Log | Durable, ordered log of all cluster metadata changes | `continuumKafkaMetadataLog` |
| Quorum Manager (follower controllers) | Fetch and replicate metadata records from the active controller | `kafkaControllerQuorumManager` (follower instances) |
| Metadata Loader | Reads committed records and applies them to the controller's in-memory metadata cache | `kafkaControllerMetadataLoader` |
| Kafka Broker | Fetches committed metadata deltas from the controller; updates local metadata cache | `continuumKafkaBroker`, `kafkaBrokerReplicaManager` |

## Steps

1. **Receives administrative request**: A Kafka admin client (or internal controller logic) triggers a metadata change (e.g., `CreateTopics` API call)
   - From: `Admin Client / Controller Internal`
   - To: `kafkaBrokerNetworkApi` (forwarded to active controller)
   - Protocol: Kafka Wire Protocol (TCP)

2. **Validates and prepares metadata record**: Active controller's `kafkaControllerQuorumManager` validates the request and constructs the appropriate metadata record (e.g., `TopicRecord`, `PartitionRecord`) using protobuf encoding
   - From: `kafkaBrokerNetworkApi`
   - To: `kafkaControllerQuorumManager`
   - Protocol: direct (in-process)

3. **Appends to KRaft metadata log**: Active controller appends the record to `continuumKafkaMetadataLog`; the record is assigned a monotonically increasing offset
   - From: `kafkaControllerQuorumManager`
   - To: `continuumKafkaMetadataLog`
   - Protocol: Filesystem I/O

4. **Follower controllers replicate**: Follower controller nodes issue fetch requests to the active controller; active controller responds with new records since the follower's last fetch offset
   - From: `continuumKafkaController` (followers)
   - To: `continuumKafkaController` (active)
   - Protocol: RPC (KRaft fetch protocol)

5. **Follower controllers acknowledge**: Once a quorum majority (e.g., 2 of 3 controllers) has written the record, it is considered committed; active controller advances the commit offset
   - From: `kafkaControllerQuorumManager` (followers)
   - To: `kafkaControllerQuorumManager` (active)
   - Protocol: RPC

6. **Active controller applies committed record**: `kafkaControllerMetadataLoader` reads the committed record and updates the active controller's in-memory metadata state
   - From: `continuumKafkaMetadataLog`
   - To: `kafkaControllerMetadataLoader`
   - Protocol: Filesystem I/O (log replay)

7. **Controller pushes metadata delta to brokers**: Active controller sends metadata update (partition assignments, topic configs, etc.) to all registered brokers via `UpdateMetadataRequest` or metadata fetch response
   - From: `continuumKafkaController`
   - To: `continuumKafkaBroker`
   - Protocol: RPC

8. **Brokers apply metadata update**: Brokers' `kafkaBrokerReplicaManager` updates its in-memory partition and topic metadata; brokers begin serving the new state to producers and consumers
   - From: `continuumKafkaBroker` (internal)
   - To: `kafkaBrokerReplicaManager`
   - Protocol: direct (in-process)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Active controller loses quorum majority | No new records can be committed; in-flight admin operations fail | Admin requests return errors; existing cluster state is preserved; new controller elected when quorum restores |
| Broker fails to receive metadata update | Broker re-fetches full metadata on reconnect to controller | Brief window where broker has stale metadata; clients experience `NOT_LEADER_OR_FOLLOWER` and refresh |
| Metadata log corruption | Controller shuts down; operator must restore from snapshot | Requires operator-assisted KRaft disaster recovery procedure |
| Slow follower controller | Active controller may fence the slow follower from the quorum | Quorum continues with remaining voters; fenced follower must catch up before rejoining |

## Sequence Diagram

```
AdminClient         -> kafkaBrokerNetworkApi:              CreateTopics request
kafkaBrokerNetworkApi -> kafkaControllerQuorumManager:     Forward admin request to active controller
kafkaControllerQuorumManager -> continuumKafkaMetadataLog: Append TopicRecord (protobuf)
continuumKafkaMetadataLog --> kafkaControllerQuorumManager: Append acknowledged
FollowerController  -> kafkaControllerQuorumManager:       Fetch metadata records (follower fetch)
kafkaControllerQuorumManager --> FollowerController:        New metadata records
FollowerController  -> kafkaControllerQuorumManager:        Acknowledge (quorum ISR ack)
kafkaControllerQuorumManager -> kafkaControllerMetadataLoader: Apply committed record to in-memory state
kafkaControllerMetadataLoader --> kafkaControllerQuorumManager: State updated
continuumKafkaController -> continuumKafkaBroker:           UpdateMetadataRequest (new topic/partition state)
kafkaBrokerReplicaManager -> continuumKafkaBroker:          Update local metadata cache
kafkaBrokerNetworkApi --> AdminClient:                      CreateTopics response (success)
```

## Related

- Architecture dynamic view: `dynamic-kafka-kraft-cluster-control`
- Related flows: [Partition Leadership Failover](partition-leadership-failover.md), [Message Produce and Replication](message-produce-and-replication.md)
