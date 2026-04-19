---
service: "arbitration-service"
title: "Campaign Revoke"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "campaign-revoke"
flow_type: synchronous
trigger: "POST /revoke API call from marketing delivery client"
participants:
  - "marketingDeliveryClients"
  - "continuumArbitrationService"
  - "apiHandlers"
  - "arbitrationLogic"
  - "campaignMetaAccess"
  - "absCassandra"
  - "absRedis"
architecture_ref: "dynamic-campaignRevoke"
---

# Campaign Revoke

## Summary

The campaign revoke flow marks a previously committed campaign send as revoked, reversing the send record in Cassandra and adjusting the associated quota counters in Redis. This allows the system to undo a campaign delivery commitment — for example, if a campaign is cancelled after arbitration has already selected it as the winner.

## Trigger

- **Type**: api-call
- **Source**: `marketingDeliveryClients` — marketing delivery systems invoking `POST /revoke` after a previously committed send needs to be cancelled
- **Frequency**: on demand, infrequent relative to arbitrate/best-for traffic

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Marketing Delivery Clients | Initiates the revoke by calling `POST /revoke` with send reference | `marketingDeliveryClients` |
| API Handlers | Receives and validates the HTTP request; routes to arbitration logic | `apiHandlers` |
| Arbitration Logic | Orchestrates the revoke operation across Cassandra and Redis | `arbitrationLogic` |
| Campaign Metadata Access | Marks the send record as revoked in Cassandra | `campaignMetaAccess` |
| Cassandra | Stores the updated send record with revoked status | `absCassandra` |
| Redis | Updated with decremented counters to reverse the revoked send | `absRedis` |

## Steps

1. **Receive revoke request**: Marketing delivery client sends a revoke request referencing the previously committed send.
   - From: `marketingDeliveryClients`
   - To: `apiHandlers`
   - Protocol: REST/HTTPS

2. **Route to revoke logic**: API handler validates the request and invokes the arbitration logic component to execute the revoke.
   - From: `apiHandlers`
   - To: `arbitrationLogic`
   - Protocol: direct (in-process)

3. **Mark send record as revoked in Cassandra**: The send record in Cassandra corresponding to the referenced campaign and user is updated to a revoked state, removing it from active send history for future frequency cap checks.
   - From: `arbitrationLogic` via `campaignMetaAccess`
   - To: `absCassandra`
   - Protocol: CQL

4. **Adjust Redis quota counters**: The decisioning counters in Redis are decremented to reverse the effect of the now-revoked send on quota and frequency cap state.
   - From: `arbitrationLogic`
   - To: `absRedis`
   - Protocol: Redis

5. **Return revoke confirmation**: API handler returns a success confirmation to the caller.
   - From: `apiHandlers`
   - To: `marketingDeliveryClients`
   - Protocol: REST/HTTPS (JSON response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Send record not found in Cassandra | Return HTTP 404 or appropriate error | Revoke not executed; caller notified |
| Cassandra write failure | Cannot mark send as revoked | Request fails; send record remains in committed state |
| Redis counter decrement failure | Counter state becomes inconsistent | Send record may be revoked in Cassandra without counter adjustment; cap enforcement may overcount |
| Invalid request payload | Return HTTP 400 with error detail | Request rejected before any data store access |

## Sequence Diagram

```
marketingDeliveryClients -> apiHandlers: POST /revoke (send reference + user context)
apiHandlers -> arbitrationLogic: invoke revoke operation
arbitrationLogic -> absCassandra: mark send record as revoked
absCassandra --> arbitrationLogic: write confirmation
arbitrationLogic -> absRedis: decrement quota counters for revoked send
absRedis --> arbitrationLogic: counter update confirmation
arbitrationLogic --> apiHandlers: revoke result
apiHandlers --> marketingDeliveryClients: HTTP 200 (revoke confirmation JSON)
```

## Related

- Architecture dynamic view: `dynamic-campaignRevoke`
- Related flows: [Arbitration Decision](arbitration-decision.md) — creates the committed send record that this flow revokes
- Related flows: [Best-For Selection](best-for-selection.md) — revoked sends are excluded from future frequency cap checks
