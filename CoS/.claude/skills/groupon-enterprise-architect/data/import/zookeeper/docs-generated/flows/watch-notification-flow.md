---
service: "zookeeper"
title: "Watch Notification Flow"
generated: "2026-03-03"
type: flow
flow_name: "watch-notification-flow"
flow_type: event-driven
trigger: "A znode that a client has registered a watch on is created, updated (setData), or deleted"
participants:
  - "zookeeperServer"
  - "requestProcessorPipeline"
  - "zookeeperDataPersistence"
  - "zookeeperCli"
architecture_ref: "components-zookeeperServerComponents"
---

# Watch Notification Flow

## Summary

ZooKeeper's watch mechanism allows clients to receive a one-time asynchronous notification when a znode they are interested in changes. A client registers a watch during a read operation (`getData`, `exists`, `getChildren`). When the next qualifying change occurs on that znode, the server delivers a single `WatchedEvent` notification to the client over its existing TCP session. The watch is then consumed and must be re-registered if the client wants further notifications.

## Trigger

- **Type**: event
- **Source**: A write operation (`create`, `setData`, `delete`) committed by the `requestProcessorPipeline` that affects a znode with one or more registered watches
- **Frequency**: On-demand; triggered by qualifying write events

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| ZooKeeper Client (watcher) | Registered the watch during a prior read; receives the notification | `zookeeperCli` or any ZooKeeper client |
| ZooKeeper Server | Stores watches and delivers notifications upon commit | `zookeeperServer` |
| Request Processor Pipeline | Identifies watches to trigger after committing a write | `requestProcessorPipeline` |
| Data Persistence (in-memory tree) | Maintains the watch table associated with znodes | `zookeeperDataPersistence` |

## Steps

1. **Client registers watch during read**: During a prior `getData`, `exists`, or `getChildren` call, the client sets the watch flag to `true`. The server records an association between the client session and the target znode path in the in-memory watch table.
   - From: `zookeeperCli`
   - To: `zookeeperServer` (watch table)
   - Protocol: ZooKeeper binary client protocol / TCP/2181

2. **Qualifying write is committed**: A separate client (or the same client) issues a write (`create`, `setData`, `delete`) on the watched znode path. The write completes the full client write flow and is committed to the transaction log.
   - From: any client
   - To: `requestProcessorPipeline`
   - Protocol: ZooKeeper binary client protocol / TCP/2181

3. **Pipeline identifies triggered watches**: After committing the write, the `requestProcessorPipeline` consults the watch table in `zookeeperDataPersistence` and identifies all client sessions with watches on the affected path.
   - From: `requestProcessorPipeline`
   - To: `zookeeperDataPersistence` (watch table)
   - Protocol: Internal/Java

4. **Removes watches from table**: The watch entries for the affected path are atomically removed from the watch table. Watches in ZooKeeper are one-shot: they fire exactly once.
   - From: `requestProcessorPipeline`
   - To: watch table
   - Protocol: Internal/Java

5. **Delivers WatchedEvent to client**: The server enqueues a `WatchedEvent` message (containing the event type and path) for delivery to each watching client session. The event is sent over the client's existing TCP connection.
   - From: `zookeeperServer`
   - To: `zookeeperCli` (watcher)
   - Protocol: ZooKeeper binary client protocol / TCP/2181

6. **Client processes notification**: The client receives the `WatchedEvent`, identifies the affected path and event type (`NodeCreated`, `NodeDataChanged`, `NodeDeleted`, `NodeChildrenChanged`), and executes its watch callback. The client must re-register a watch if it wants to continue monitoring the path.
   - From: `zookeeperCli` (session)
   - To: client application code
   - Protocol: Internal client-side callback

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Watcher client session expires before notification delivery | Watch is dropped; session cleanup removes all watches for that session | Client receives `SessionExpiredException` on its next operation; must re-establish session and re-register watches |
| Network disconnection before notification delivery | Server queues the event; if client reconnects within session timeout, the event is delivered | Client receives the event after reconnection; if timeout expires, session expires and watches are lost |
| Multiple changes before client processes first notification | Only one `WatchedEvent` is delivered per registered watch (one-shot) | Client may miss intermediate state changes; it must re-read and re-register the watch to catch up |

## Sequence Diagram

```
Client/zookeeperCli -> zookeeperServer: getData("/config/feature-x", watch=true)
zookeeperServer -> WatchTable: Register watch(session=S, path="/config/feature-x")
zookeeperServer -> Client/zookeeperCli: getData response (current data)

[Later — write event occurs]

AnyClient -> zookeeperServer: setData("/config/feature-x", newData)
zookeeperServer -> requestProcessorPipeline: Commit write
requestProcessorPipeline -> WatchTable: Find watchers for "/config/feature-x"
WatchTable -> requestProcessorPipeline: [session S]
requestProcessorPipeline -> WatchTable: Remove watch (one-shot)
zookeeperServer -> Client/zookeeperCli: WatchedEvent(NodeDataChanged, "/config/feature-x")
Client/zookeeperCli -> Client/zookeeperCli: Execute watch callback
```

## Related

- Architecture dynamic view: `dynamic-cliWriteFlow`
- Related flows: [Client Write Flow](client-write-flow.md), [Client Read Flow](client-read-flow.md)
