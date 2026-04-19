---
service: "kafka"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `kafka-broker-api-versions.sh --bootstrap-server <host>:9092` | exec | 30 s | 10 s |
| `kafka-metadata-quorum.sh --bootstrap-server <host>:9092 describe --status` | exec | 60 s | 15 s |
| Kubernetes liveness probe (TCP port 9092) | tcp | 30 s | 5 s |
| Kubernetes readiness probe (TCP port 9092) | tcp | 10 s | 5 s |
| `GET /metrics` on broker admin port | http | 15 s | 5 s |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `kafka.server:type=BrokerTopicMetrics,name=MessagesInPerSec` | gauge | Incoming message rate across all topics | Alert if drops >50% below baseline |
| `kafka.server:type=BrokerTopicMetrics,name=BytesInPerSec` | gauge | Incoming byte rate | Alert if drops >50% below baseline |
| `kafka.server:type=BrokerTopicMetrics,name=BytesOutPerSec` | gauge | Outgoing byte rate | Alert if drops >50% below baseline |
| `kafka.controller:type=KafkaController,name=ActiveControllerCount` | gauge | Number of active controllers (should be 1) | Alert if != 1 |
| `kafka.controller:type=KafkaController,name=OfflinePartitionsCount` | gauge | Number of partitions with no leader | Alert if > 0 |
| `kafka.server:type=ReplicaManager,name=UnderReplicatedPartitions` | gauge | Partitions not fully replicated | Alert if > 0 for >60 s |
| `kafka.network:type=RequestMetrics,name=TotalTimeMs,request=Produce` | histogram | End-to-end produce request latency | Alert if p99 > 500 ms |
| `kafka.network:type=RequestMetrics,name=TotalTimeMs,request=FetchConsumer` | histogram | End-to-end fetch latency for consumers | Alert if p99 > 1000 ms |
| `kafka.log:type=LogFlushStats,name=LogFlushRateAndTimeMs` | histogram | Frequency and latency of log segment flushes | Alert if p99 > 2000 ms |
| `kafka.server:type=KafkaRequestHandlerPool,name=RequestHandlerAvgIdlePercent` | gauge | Fraction of request handler threads idle | Alert if < 0.20 |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Kafka Cluster Overview | Grafana | Operational procedures to be defined by service owner |
| Kafka Connect Worker Status | Grafana | Operational procedures to be defined by service owner |
| KRaft Controller Health | Grafana | Operational procedures to be defined by service owner |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| KafkaNoActiveController | `ActiveControllerCount != 1` for >30 s | critical | Check controller pod logs; verify KRaft quorum with `kafka-metadata-quorum.sh` |
| KafkaOfflinePartitions | `OfflinePartitionsCount > 0` for >60 s | critical | Identify offline partitions with `kafka-topics.sh --describe --under-replicated`; check broker disk and connectivity |
| KafkaUnderReplicatedPartitions | `UnderReplicatedPartitions > 0` for >120 s | warning | Check if a broker is lagging; inspect broker logs for fetch errors |
| KafkaHighProduceLatency | Produce p99 > 500 ms for >5 min | warning | Check broker CPU, disk I/O, network saturation; inspect slow disk with iostat |
| KafkaRequestHandlerSaturation | `RequestHandlerAvgIdlePercent < 0.20` for >5 min | warning | Reduce client request rate; add broker capacity; inspect slow requests in broker logs |

## Common Operations

### Restart Service

1. For a Kubernetes StatefulSet, perform a rolling restart: `kubectl rollout restart statefulset/kafka-broker -n <namespace>`
2. Kafka will continue serving traffic from remaining brokers during the rolling restart — ensure replication factor and ISR allow for one broker down
3. Verify the restarted pod is healthy: `kubectl rollout status statefulset/kafka-broker -n <namespace>`
4. Confirm no under-replicated partitions remain: `kafka-topics.sh --bootstrap-server <host>:9092 --describe --under-replicated-partitions`

### Scale Up / Down

**Adding a broker:**
1. Increase `spec.replicas` on the broker StatefulSet
2. Wait for the new pod to join the cluster and appear in `kafka-broker-api-versions.sh` output
3. Reassign partitions to the new broker using `kafka-reassign-partitions.sh` with a generated reassignment JSON plan
4. Monitor `UnderReplicatedPartitions` until reassignment completes

**Removing a broker:**
1. Migrate all partition leaders and replicas off the broker using `kafka-reassign-partitions.sh`
2. Wait for `UnderReplicatedPartitions` to return to 0
3. Decrease `spec.replicas` — the StatefulSet will remove the highest-numbered pod

### Log Storage Operations

- **Increase retention**: Update `log.retention.hours` or `log.retention.bytes` in `server.properties` and restart (or use `kafka-configs.sh --alter` for dynamic update)
- **Trigger log compaction manually**: Not possible directly; set `cleanup.policy=compact` on the topic and decrease `min.cleanable.dirty.ratio`
- **Delete a topic**: `kafka-topics.sh --bootstrap-server <host>:9092 --delete --topic <topic-name>` (requires `delete.topic.enable=true`)

## Troubleshooting

### Offline Partitions

- **Symptoms**: `OfflinePartitionsCount > 0`; producers receive `LEADER_NOT_AVAILABLE` errors; consumers stop receiving records
- **Cause**: Broker hosting the partition leader is down or unreachable; no other ISR replica exists to take leadership
- **Resolution**: Restart the affected broker pod if down; if the broker disk is lost, restore from replica on another broker by increasing `unclean.leader.election.enable=true` temporarily (data loss risk) or restore from backup

### Under-Replicated Partitions

- **Symptoms**: `UnderReplicatedPartitions > 0`; ISR for affected partitions is smaller than `replication.factor`
- **Cause**: A follower broker is lagging behind the leader — typically due to network issues, slow disk I/O, or a broker restart
- **Resolution**: Identify lagging broker; check broker logs for fetch exception or disk error; if the broker recently restarted, wait for replication catch-up; if persistent, investigate disk performance with `iostat`

### Consumer Group Lag

- **Symptoms**: Consumer group offset is far behind the log end offset; downstream service processing is delayed
- **Cause**: Consumer is slower than the producer rate; consumer has stopped or crashed; partition reassignment in progress
- **Resolution**: Use `kafka-consumer-groups.sh --describe --group <group-id>` to inspect lag per partition; identify the lagging partition and its consumer member; scale consumer replicas or investigate consumer application errors

### Kafka Connect Task Failure

- **Symptoms**: `GET /connectors/{name}/status` returns `FAILED` state for a task
- **Cause**: Source/sink system unreachable; serialization error in a record; connector misconfiguration
- **Resolution**: Inspect connector task error trace via the Connect REST API (`GET /connectors/{name}/status`); fix root cause (external system, config, or bad record); restart the task with `POST /connectors/{name}/tasks/{task-id}/restart`

### KRaft Controller Quorum Loss

- **Symptoms**: `ActiveControllerCount = 0`; cluster metadata changes (topic create/delete, partition reassignment) are rejected; brokers continue serving existing partitions
- **Cause**: Majority of KRaft controller nodes are unavailable (majority lost in a 3-node quorum = 2 nodes down)
- **Resolution**: Restore at least 2 of 3 controller pods; verify quorum with `kafka-metadata-quorum.sh describe --status`; if metadata log is corrupted, follow Kafka KRaft disaster recovery procedure

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | All Continuum event flows halted (no active controller, majority offline partitions) | Immediate | Platform Engineers + SRE on-call |
| P2 | Partial event flow degradation (offline partitions for specific topics, high produce latency) | 30 min | Platform Engineers |
| P3 | Minor impact (under-replicated partitions recovering, single Connect task failed) | Next business day | Service owner team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumKafkaLogStorage` | Check PVC mount and disk I/O with `df -h` and `iostat` on broker pod | Partitions on other brokers with healthy storage continue serving; affected broker goes offline |
| `continuumKafkaMetadataLog` | `kafka-metadata-quorum.sh describe --status` | If active controller loses metadata log access, controller election triggers from remaining quorum voters |
| `continuumKafkaBroker` (from Connect) | Connect worker herder retries with exponential backoff; `GET /connectors/{name}/status` | Connect tasks pause and retry; no data loss if connector uses offset checkpointing |
