---
service: "zookeeper"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Apache ZooKeeper.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Client Write Flow](client-write-flow.md) | synchronous | Client issues `create` or `setData` request | Client write is validated, forwarded to leader, replicated to quorum, persisted, and acknowledged |
| [Client Read Flow](client-read-flow.md) | synchronous | Client issues `getData`, `exists`, or `getChildren` request | Client read is served directly from in-memory state; optional watch is registered |
| [Leader Election Flow](leader-election-flow.md) | event-driven | Server startup or current leader failure detected | Ensemble members run Zab-based fast leader election to elect a new leader |
| [Watch Notification Flow](watch-notification-flow.md) | event-driven | Watched znode is created, updated, or deleted | ZooKeeper delivers a one-time watch event to the registered client over the TCP session |
| [Snapshot and Log Purge Flow](snapshot-purge-flow.md) | scheduled | Autopurge timer fires or operator runs `zkCleanup.sh` | Old snapshot and transaction log files beyond retention count are deleted from `dataDir` |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

The `cliWriteFlow` dynamic view in the architecture model (`dynamic-cliWriteFlow`) captures the interaction between `zookeeperCli` and `zookeeperServer`. See [Client Write Flow](client-write-flow.md) for the detailed step-by-step process.

All other flows are internal to the `zookeeperServer` container and its components (`requestProcessorPipeline`, `quorumProtocolEngine`, `zookeeperDataPersistence`).
