---
service: "zookeeper"
title: "Leader Election Flow"
generated: "2026-03-03"
type: flow
flow_name: "leader-election-flow"
flow_type: event-driven
trigger: "ZooKeeper server starts up, or the current leader becomes unreachable and servers detect session loss on the peer port"
participants:
  - "zookeeperServer"
  - "quorumProtocolEngine"
  - "requestProcessorPipeline"
  - "zookeeperDataPersistence"
architecture_ref: "components-zookeeperServerComponents"
---

# Leader Election Flow

## Summary

When a ZooKeeper ensemble starts up or the current leader fails, all servers enter the `LOOKING` state and run the Zab fast leader election algorithm to elect a new leader. Servers exchange `Vote` messages, converge on the server with the highest (epoch, zxid, server ID) tuple, and the winner becomes the new leader. Followers and observers then synchronize their state with the leader before the ensemble begins serving requests again.

## Trigger

- **Type**: event
- **Source**: Server startup; or detection of leader unavailability (peer connection loss on the quorum port; typically 2888/3888)
- **Frequency**: On startup; on leader failure; on network partition recovery

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| ZooKeeper Server (all ensemble members) | Transition to LOOKING state and exchange Vote messages | `zookeeperServer` |
| Quorum Protocol Engine | Runs the Zab fast leader election protocol; proposes and votes | `quorumProtocolEngine` |
| Request Processor Pipeline | Halted during election; resumes serving after new leader is established | `requestProcessorPipeline` |
| Data Persistence | Provides the latest committed zxid to determine vote priority | `zookeeperDataPersistence` |

## Steps

1. **Detects leader loss**: One or more servers detect that the current leader is unreachable (peer connection times out based on `tickTime` x `syncLimit`). Alternatively, all servers start simultaneously with no prior leader.
   - From: `quorumProtocolEngine` (each server)
   - To: `quorumProtocolEngine` (self-transition)
   - Protocol: Internal/Java

2. **Enters LOOKING state**: Each server transitions its own state to `LOOKING` and suspends request processing in the `requestProcessorPipeline`.
   - From: `quorumProtocolEngine`
   - To: `requestProcessorPipeline`
   - Protocol: Internal/Java

3. **Reads latest zxid**: Each server reads the highest committed transaction ID (zxid) and current epoch from `zookeeperDataPersistence` to construct its initial vote.
   - From: `quorumProtocolEngine`
   - To: `zookeeperDataPersistence`
   - Protocol: Internal/Java

4. **Broadcasts initial vote**: Each server broadcasts a vote for itself: `(epoch, zxid, serverID)` to all other ensemble members over the quorum port.
   - From: `quorumProtocolEngine` (each server)
   - To: `quorumProtocolEngine` (all peers)
   - Protocol: Zab fast leader election / TCP (peer port, default 2888)

5. **Processes incoming votes**: Each server compares incoming votes using the priority rule: highest epoch wins; tie-break by highest zxid; tie-break by highest server ID. If an incoming vote is better than the current vote, the server updates its vote and re-broadcasts.
   - From: `quorumProtocolEngine` (peer)
   - To: `quorumProtocolEngine` (self)
   - Protocol: Internal/Java

6. **Reaches quorum agreement**: Once a server observes that a majority of ensemble members have voted for the same candidate, election is complete. The candidate with the winning vote becomes the new leader; others become followers or observers.
   - From: `quorumProtocolEngine` (all)
   - To: `quorumProtocolEngine` (winner/followers)
   - Protocol: Internal/Java

7. **Leader synchronizes followers**: The new leader sends its committed log and epoch to all followers. Followers synchronize their `zookeeperDataPersistence` state with the leader (applying missing transactions or truncating divergent ones).
   - From: `quorumProtocolEngine` (leader)
   - To: `zookeeperDataPersistence` (followers)
   - Protocol: Zab synchronization / TCP

8. **Ensemble resumes serving**: Once a quorum of followers have confirmed synchronization, the leader starts a new epoch. The `requestProcessorPipeline` on all servers resumes processing client requests.
   - From: `quorumProtocolEngine`
   - To: `requestProcessorPipeline`
   - Protocol: Internal/Java

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No quorum reachable (split-brain, majority unreachable) | Servers remain in LOOKING state indefinitely; no leader elected | Ensemble is unavailable; clients receive CONNECTION_LOSS until quorum is restored |
| Network partition heals | Servers on each side resume election; side with majority wins | Losing-side servers catch up to winning leader via synchronization |
| New server joins during election | New server participates in election from the start | Counted towards quorum majority once it joins |
| Leader crashes immediately after election | New election triggered immediately | Next best candidate wins; followers re-synchronize |

## Sequence Diagram

```
ServerA -> AllPeers: Vote(epoch=E, zxid=Z_A, id=A) broadcast
ServerB -> AllPeers: Vote(epoch=E, zxid=Z_B, id=B) broadcast
ServerC -> AllPeers: Vote(epoch=E, zxid=Z_C, id=C) broadcast
ServerA -> ServerA: Compare votes — update if better
ServerB -> ServerB: Compare votes — update if better
ServerC -> ServerC: Compare votes — quorum agrees on B (highest zxid)
ServerB (Leader) -> ServerA: Synchronize state (DIFF/SNAP)
ServerB (Leader) -> ServerC: Synchronize state (DIFF/SNAP)
ServerA -> ServerB: ACK sync complete
ServerC -> ServerB: ACK sync complete
ServerB -> ServerA: NEW_LEADER epoch E+1 — begin serving
ServerB -> ServerC: NEW_LEADER epoch E+1 — begin serving
```

## Related

- Architecture dynamic view: `components-zookeeperServerComponents`
- Related flows: [Client Write Flow](client-write-flow.md), [Watch Notification Flow](watch-notification-flow.md)
