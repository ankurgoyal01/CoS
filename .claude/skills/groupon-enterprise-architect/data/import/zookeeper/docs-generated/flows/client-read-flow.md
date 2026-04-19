---
service: "zookeeper"
title: "Client Read Flow"
generated: "2026-03-03"
type: flow
flow_name: "client-read-flow"
flow_type: synchronous
trigger: "Client issues getData, exists, or getChildren request via the ZooKeeper binary client protocol on TCP/2181"
participants:
  - "zookeeperCli"
  - "zookeeperServer"
  - "requestProcessorPipeline"
  - "zookeeperDataPersistence"
architecture_ref: "components-zookeeperServerComponents"
---

# Client Read Flow

## Summary

Read operations in ZooKeeper are served directly from the in-memory znode tree on the receiving server, without requiring quorum consensus. This makes reads fast and local. Clients can optionally register a watch during a read operation; the watch is stored on the server and fires once when the watched znode changes. Any server in the ensemble (leader or follower) can serve reads.

## Trigger

- **Type**: api-call
- **Source**: Any ZooKeeper client (including `zookeeperCli`, `zookeeperRestGateway`, or any Continuum service embedding the ZooKeeper client library)
- **Frequency**: On-demand, per read request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| ZooKeeper CLI / Client | Issues the read request and processes the response | `zookeeperCli` |
| ZooKeeper Server | Receives the read request and serves it from local state | `zookeeperServer` |
| Request Processor Pipeline | Routes the read through the read-path processor stages | `requestProcessorPipeline` |
| Data Persistence (in-memory tree) | Provides the authoritative in-memory znode data | `zookeeperDataPersistence` |

## Steps

1. **Sends read request**: The client sends a read operation (`getData`, `exists`, or `getChildren`) with an optional watch flag over the TCP session to port 2181.
   - From: `zookeeperCli`
   - To: `zookeeperServer`
   - Protocol: ZooKeeper binary client protocol / TCP/2181

2. **Request Processor Pipeline routes the read**: The `requestProcessorPipeline` receives the deserialized request, identifies it as a read (no leader forwarding needed), and directs it to the local data tree.
   - From: `requestProcessorPipeline`
   - To: `zookeeperDataPersistence` (in-memory tree)
   - Protocol: Internal/Java

3. **Registers watch (if requested)**: If the client included a watch flag, the server records a watch association between the client session and the target znode path. The watch is stored in memory on the server.
   - From: `requestProcessorPipeline`
   - To: in-memory watch table
   - Protocol: Internal/Java

4. **Retrieves znode data**: The in-memory data tree is queried for the requested znode's data, stat (version, timestamps, child count), or child list.
   - From: `zookeeperDataPersistence` (in-memory tree)
   - To: `requestProcessorPipeline`
   - Protocol: Internal/Java

5. **Returns response to client**: The server sends the response (znode data, stat, or child names) back to the client. The response includes the current zxid for the served data.
   - From: `zookeeperServer`
   - To: `zookeeperCli` / client
   - Protocol: ZooKeeper binary client protocol / TCP/2181

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Znode does not exist (getData / getChildren) | `requestProcessorPipeline` returns `ZNONODE` | Client receives `NoNodeException`; watch still registered if requested |
| ACL check fails | Request rejected with `ZNOAUTH` | Client receives `NoAuthException` |
| Session expired | Session invalidated before processing | Client receives `SessionExpiredException`; must reconnect |
| Server in read-only mode (no quorum) | Read may be served stale if `zookeeper.read.only.client.connect=true` | Client receives potentially stale data; write operations fail |

## Sequence Diagram

```
Client/zookeeperCli -> zookeeperServer: getData/exists/getChildren (TCP/2181, optional watch flag)
zookeeperServer -> requestProcessorPipeline: Dispatch read request
requestProcessorPipeline -> zookeeperDataPersistence: Query in-memory znode tree
requestProcessorPipeline -> WatchTable: Register watch (if watch=true)
zookeeperDataPersistence -> requestProcessorPipeline: Return znode data / stat / children
zookeeperServer -> Client/zookeeperCli: Response (data, stat, zxid)
```

## Related

- Architecture dynamic view: `dynamic-cliWriteFlow`
- Related flows: [Client Write Flow](client-write-flow.md), [Watch Notification Flow](watch-notification-flow.md)
