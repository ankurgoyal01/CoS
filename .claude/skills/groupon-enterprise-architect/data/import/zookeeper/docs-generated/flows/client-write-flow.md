---
service: "zookeeper"
title: "Client Write Flow"
generated: "2026-03-03"
type: flow
flow_name: "client-write-flow"
flow_type: synchronous
trigger: "Client issues a create, setData, delete, or multi operation via the ZooKeeper binary client protocol on TCP/2181"
participants:
  - "zookeeperCli"
  - "zookeeperServer"
  - "requestProcessorPipeline"
  - "quorumProtocolEngine"
  - "zookeeperDataPersistence"
architecture_ref: "dynamic-cliWriteFlow"
---

# Client Write Flow

## Summary

When a client issues a write operation (`create`, `setData`, `delete`, `multi`) to a ZooKeeper server, the request flows through an ordered processor pipeline that validates the operation, forwards it to the ensemble leader if needed, replicates it to a quorum of servers, persists it to the transaction log, and then acknowledges the client. This flow guarantees that all writes are sequentially consistent and durable across the ensemble before the client receives a success response.

## Trigger

- **Type**: api-call
- **Source**: Any ZooKeeper client (including `zookeeperCli`, `zookeeperRestGateway`, or any Continuum service embedding the ZooKeeper Java/C client library)
- **Frequency**: On-demand, per write request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| ZooKeeper CLI / Client | Issues the write request and receives acknowledgement | `zookeeperCli` |
| ZooKeeper Server | Receives, processes, and acknowledges the request | `zookeeperServer` |
| Request Processor Pipeline | Validates, sequences, and routes the request through processing stages | `requestProcessorPipeline` |
| Quorum Protocol Engine | Coordinates replication to follower servers for quorum consensus | `quorumProtocolEngine` |
| Data Persistence | Appends the operation to the transaction log and updates in-memory state | `zookeeperDataPersistence` |

## Steps

1. **Receives write request**: The client (`zookeeperCli` or any ZooKeeper client) sends a write operation (e.g., `create /my/path "data"`) to the ZooKeeper server over the established TCP session on port 2181.
   - From: `zookeeperCli`
   - To: `zookeeperServer`
   - Protocol: ZooKeeper binary client protocol / TCP/2181

2. **Session Manager dispatches request**: The `zookeeperCliSessionManager` (on the client side) or the server-side session handler dispatches the serialized request into the `requestProcessorPipeline`.
   - From: `zookeeperCliSessionManager`
   - To: `requestProcessorPipeline`
   - Protocol: Internal/Java

3. **Request Processor Pipeline validates request**: The `requestProcessorPipeline` validates the request (ACL check, znode existence, version check), assigns a transaction ID (zxid), and determines whether this server is the leader or must forward to the leader.
   - From: `requestProcessorPipeline`
   - To: `requestProcessorPipeline` (internal stages)
   - Protocol: Internal/Java

4. **Forwards to leader (if follower)**: If the receiving server is a follower, it forwards the write request to the current leader. The leader assigns the authoritative zxid.
   - From: `requestProcessorPipeline` (follower)
   - To: `requestProcessorPipeline` (leader)
   - Protocol: Internal Zab protocol / TCP (peer port)

5. **Quorum Protocol Engine replicates write**: The `quorumProtocolEngine` on the leader sends PROPOSAL messages to all follower servers and waits for `ACK` responses from a quorum (majority).
   - From: `quorumProtocolEngine`
   - To: `requestProcessorPipeline` (followers)
   - Protocol: Zab protocol / TCP

6. **Persists to transaction log**: Once a quorum of `ACK` messages is received, the leader commits the transaction. The `requestProcessorPipeline` instructs `zookeeperDataPersistence` to append the operation to the transaction log on disk.
   - From: `requestProcessorPipeline`
   - To: `zookeeperDataPersistence`
   - Protocol: Internal/Java / Filesystem write

7. **Updates in-memory znode tree**: The `zookeeperDataPersistence` component applies the committed write to the in-memory znode tree, making the new state immediately readable.
   - From: `zookeeperDataPersistence`
   - To: in-memory data tree
   - Protocol: Internal/Java

8. **Delivers watch notifications**: After committing, ZooKeeper identifies clients with watches on the affected znode path and delivers one-time `NodeDataChanged`, `NodeCreated`, or `NodeDeleted` event notifications to those clients.
   - From: `zookeeperServer`
   - To: watching clients
   - Protocol: ZooKeeper binary client protocol / TCP/2181

9. **Acknowledges the client**: The server sends a success response with the new zxid back to the originating client.
   - From: `zookeeperServer`
   - To: `zookeeperCli` / client
   - Protocol: ZooKeeper binary client protocol / TCP/2181

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Znode does not exist on `setData` | Request rejected by `requestProcessorPipeline` with `ZNONODE` error code | Client receives `NoNodeException`; no state change |
| Znode already exists on `create` | Request rejected with `ZNODEEXISTS` error code | Client receives `NodeExistsException`; no state change |
| Version mismatch on `setData` | Request rejected with `ZBADVERSION` error code | Client receives `BadVersionException`; no state change |
| ACL check fails | Request rejected with `ZNOAUTH` error code | Client receives `NoAuthException`; no state change |
| Leader not elected (quorum unavailable) | Request queued or rejected; no quorum ACK possible | Client receives `CONNECTION_LOSS` and must retry |
| Session expired during request | Session invalidated; ephemeral nodes cleaned up | Client receives `SessionExpiredException`; must re-establish session |
| Disk write failure on transaction log | Server enters error state; may stop accepting writes | Ensemble may demote server; client reconnects to another node |

## Sequence Diagram

```
Client/zookeeperCli -> zookeeperServer: create/setData/delete request (TCP/2181)
zookeeperServer -> requestProcessorPipeline: Dispatch to processor pipeline
requestProcessorPipeline -> requestProcessorPipeline: Validate ACL, zxid, znode state
requestProcessorPipeline -> quorumProtocolEngine: Forward for quorum replication (if leader)
quorumProtocolEngine -> Followers: PROPOSAL(zxid, request)
Followers -> quorumProtocolEngine: ACK(zxid)
quorumProtocolEngine -> requestProcessorPipeline: Quorum reached — commit
requestProcessorPipeline -> zookeeperDataPersistence: Append to transaction log
zookeeperDataPersistence -> zookeeperDataPersistence: Update in-memory znode tree
zookeeperServer -> WatchingClients: NodeDataChanged / NodeCreated / NodeDeleted event
zookeeperServer -> Client/zookeeperCli: Success response (zxid)
```

## Related

- Architecture dynamic view: `dynamic-cliWriteFlow`
- Related flows: [Client Read Flow](client-read-flow.md), [Watch Notification Flow](watch-notification-flow.md), [Leader Election Flow](leader-election-flow.md)
