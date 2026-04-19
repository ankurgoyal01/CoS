---
service: "zookeeper"
title: "Snapshot and Log Purge Flow"
generated: "2026-03-03"
type: flow
flow_name: "snapshot-purge-flow"
flow_type: scheduled
trigger: "Autopurge timer fires (configured via autopurge.purgeInterval in zoo.cfg), or operator runs bin/zkCleanup.sh manually"
participants:
  - "zookeeperServer"
  - "zookeeperDataPersistence"
architecture_ref: "components-zookeeperServerComponents"
---

# Snapshot and Log Purge Flow

## Summary

ZooKeeper generates periodic snapshots and appends all write operations to transaction log files in `dataDir`. Without periodic cleanup, these files accumulate without bound and eventually exhaust disk space. The purge flow removes old snapshot and transaction log files from `dataDir` (and optionally `dataLogDir`), retaining only the most recent N snapshots (configured by `autopurge.snapRetainCount`) along with the transaction logs required to replay from those snapshots. Purge runs are either scheduled automatically or triggered manually by an operator.

## Trigger

- **Type**: schedule (autopurge) or manual (operator)
- **Source**: Internal `DatadirCleanupManager` timer when `autopurge.purgeInterval > 0` in `zoo.cfg`; or operator execution of `bin/zkCleanup.sh`
- **Frequency**: Configurable in hours via `autopurge.purgeInterval`; default disabled (0)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| ZooKeeper Server | Hosts the autopurge scheduler; continues serving requests during purge | `zookeeperServer` |
| Data Persistence | Owns the `dataDir` and `dataLogDir` filesystem directories being purged | `zookeeperDataPersistence` |

## Steps

1. **Autopurge timer fires (or operator invokes zkCleanup.sh)**: The `DatadirCleanupManager` inside `zookeeperServer` fires on the configured interval, or an operator runs `bin/zkCleanup.sh $dataDir -n <retainCount>` directly.
   - From: Internal timer / operator
   - To: `zookeeperDataPersistence` (filesystem)
   - Protocol: Internal/Java / Bash

2. **Lists existing snapshots**: The purge process lists all snapshot files in `dataDir/version-2/` ordered by the embedded zxid (most recent first).
   - From: `zookeeperDataPersistence` (purge logic)
   - To: filesystem (`dataDir/version-2/`)
   - Protocol: Filesystem read

3. **Identifies files to retain**: The process selects the most recent N snapshots to retain (where N = `autopurge.snapRetainCount`, minimum 3 recommended). For each retained snapshot, the corresponding transaction log files needed to replay from that snapshot are also marked for retention.
   - From: `zookeeperDataPersistence` (purge logic)
   - To: in-memory file list
   - Protocol: Internal/Java

4. **Deletes excess snapshots**: Snapshot files older than the Nth most recent are deleted from `dataDir/version-2/`.
   - From: `zookeeperDataPersistence` (purge logic)
   - To: filesystem (`dataDir/version-2/snapshot.*`)
   - Protocol: Filesystem delete

5. **Deletes excess transaction logs**: Transaction log files not needed for replay of any retained snapshot are deleted from `dataDir/version-2/` (or `dataLogDir/version-2/` if configured separately).
   - From: `zookeeperDataPersistence` (purge logic)
   - To: filesystem (`dataDir/version-2/log.*`)
   - Protocol: Filesystem delete

6. **Logs purge completion**: The purge run logs the number of files deleted and the files retained for recovery purposes.
   - From: `zookeeperServer`
   - To: `ZOO_LOG_DIR` (logback)
   - Protocol: Logback / Console

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `dataDir` not writable | Purge fails with `IOException`; logged as error | Files not purged; disk continues to fill; operator must fix permissions |
| Purge process running during active snapshot write | Purge skips the in-progress snapshot file | Safe — only completed snapshots are removed |
| `autopurge.snapRetainCount` set below 3 | ZooKeeper documentation recommends minimum 3; lower values risk unrecoverable state | Operator risk; server continues to operate but recovery options are reduced |
| Disk full before purge runs | Transaction log write fails; server may halt | Emergency: manually delete old files beyond the N most recent snapshots and logs; restart server |

## Sequence Diagram

```
AutopurgeTimer/Operator -> zookeeperServer: Purge triggered (interval or manual)
zookeeperServer -> Filesystem(dataDir): List snapshot files (version-2/snapshot.*)
Filesystem(dataDir) -> zookeeperServer: [snapshot.Z1, snapshot.Z2, snapshot.Z3, ...]
zookeeperServer -> zookeeperServer: Select most recent N snapshots to retain
zookeeperServer -> Filesystem(dataDir): Delete snapshots beyond N
zookeeperServer -> Filesystem(dataDir): List transaction logs (version-2/log.*)
zookeeperServer -> zookeeperServer: Identify logs needed for retained snapshots
zookeeperServer -> Filesystem(dataDir): Delete excess transaction logs
zookeeperServer -> LogbackLogger: Log purge summary
```

## Related

- Architecture context: `components-zookeeperServerComponents`
- Configuration: `autopurge.snapRetainCount`, `autopurge.purgeInterval` in `conf/zoo.cfg` — see [Configuration](../configuration.md)
- Manual purge tool: `bin/zkCleanup.sh`
- Related flows: [Client Write Flow](client-write-flow.md)
