---
service: "arbitration-service"
title: "Arbitration Decision"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "arbitration-decision"
flow_type: synchronous
trigger: "POST /arbitrate API call from marketing delivery client"
participants:
  - "marketingDeliveryClients"
  - "continuumArbitrationService"
  - "apiHandlers"
  - "arbitrationLogic"
  - "campaignMetaAccess"
  - "absCassandra"
  - "absRedis"
architecture_ref: "dynamic-arbitrationDecisionFlow"
---

# Arbitration Decision

## Summary

The arbitration decision flow receives the output of a best-for selection (a ranked list of eligible campaigns) and applies final quota enforcement, winner selection, and de-duplication to identify the single winning campaign to deliver to a user. The winning send record is persisted to Cassandra, and the winner campaign is returned to the caller. This is the core decisioning step in the campaign delivery pipeline.

## Trigger

- **Type**: api-call
- **Source**: `marketingDeliveryClients` — marketing delivery systems invoking `POST /arbitrate` after receiving best-for results
- **Frequency**: per-request, on demand during campaign send workflows

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Marketing Delivery Clients | Initiates the flow by calling `POST /arbitrate` with best-for output | `marketingDeliveryClients` |
| API Handlers | Receives and validates the HTTP request; routes to arbitration logic | `apiHandlers` |
| Arbitration Logic | Applies quota enforcement, winner selection, and de-duplication | `arbitrationLogic` |
| Campaign Metadata Access | Persists the winning send record to Cassandra | `campaignMetaAccess` |
| Cassandra | Stores the committed send record for the winning campaign | `absCassandra` |
| Redis | Updated with incremented counters for the winning campaign send | `absRedis` |

## Steps

1. **Receive arbitration request**: Marketing delivery client sends the best-for ranked campaign list along with user context.
   - From: `marketingDeliveryClients`
   - To: `apiHandlers`
   - Protocol: REST/HTTPS

2. **Route to arbitration logic**: API handler validates the request and invokes the arbitration logic component.
   - From: `apiHandlers`
   - To: `arbitrationLogic`
   - Protocol: direct (in-process)

3. **Apply quota enforcement**: Arbitration logic verifies that global and per-campaign quota limits are not exceeded for the current send window.
   - From: `arbitrationLogic`
   - To: `absRedis`
   - Protocol: Redis

4. **Select winner and de-duplicate**: Arbitration logic applies winner selection rules to the ranked candidate list; removes duplicates and campaigns that fail quota checks to identify the single winning campaign.
   - From: `arbitrationLogic`
   - To: `arbitrationLogic`
   - Protocol: direct (in-process)

5. **Persist send record**: The winning campaign send is written to Cassandra as a committed send record to update send history and support future frequency cap checks.
   - From: `arbitrationLogic` via `campaignMetaAccess`
   - To: `absCassandra`
   - Protocol: CQL

6. **Increment Redis counters**: Decisioning counters in Redis are incremented for the winning campaign to reflect the committed send.
   - From: `arbitrationLogic`
   - To: `absRedis`
   - Protocol: Redis

7. **Return winner decision**: API handler serializes the single winning campaign and returns it to the caller.
   - From: `apiHandlers`
   - To: `marketingDeliveryClients`
   - Protocol: REST/HTTPS (JSON response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No candidates pass quota enforcement | Return no-winner response | Caller receives empty/null winner; no send record persisted |
| Cassandra write failure | Cannot persist send record | Request fails; winner cannot be committed without send history persistence |
| Redis counter increment failure | Counter state inconsistent | Send record may be persisted without counter update; cap enforcement may drift |
| Invalid request payload | Return HTTP 400 with error detail | Request rejected before arbitration logic executes |
| All candidates de-duplicated | Return no-winner response | Caller receives empty/null winner |

## Sequence Diagram

```
marketingDeliveryClients -> apiHandlers: POST /arbitrate (ranked campaign list + user context)
apiHandlers -> arbitrationLogic: invoke arbitration evaluation
arbitrationLogic -> absRedis: check and enforce quota limits
absRedis --> arbitrationLogic: quota status
arbitrationLogic -> arbitrationLogic: select winner, apply de-duplication
arbitrationLogic -> absCassandra: persist winning send record
absCassandra --> arbitrationLogic: write confirmation
arbitrationLogic -> absRedis: increment counters for winning send
absRedis --> arbitrationLogic: counter update confirmation
arbitrationLogic --> apiHandlers: single winner campaign
apiHandlers --> marketingDeliveryClients: HTTP 200 (winner campaign JSON)
```

## Related

- Architecture dynamic view: `dynamic-arbitrationDecisionFlow` (currently disabled — empty view, all references commented out)
- Related flows: [Best-For Selection](best-for-selection.md) — produces the ranked input consumed by this flow
- Related flows: [Campaign Revoke](campaign-revoke.md) — can undo a committed send produced by this flow
