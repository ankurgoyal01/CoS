---
service: "arbitration-service"
title: "Best-For Selection"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "best-for-selection"
flow_type: synchronous
trigger: "POST /best-for API call from marketing delivery client"
participants:
  - "marketingDeliveryClients"
  - "continuumArbitrationService"
  - "apiHandlers"
  - "bestForLogic"
  - "campaignMetaAccess"
  - "absPostgres"
  - "absCassandra"
  - "absRedis"
architecture_ref: "dynamic-bestForSelection"
---

# Best-For Selection

## Summary

The best-for selection flow receives a user context and a list of available campaigns from a marketing delivery client, then evaluates each campaign against eligibility rules, send history, frequency caps, and real-time counters to produce a ranked list of eligible campaigns. This ranked list is the input to the subsequent [Arbitration Decision](arbitration-decision.md) flow. The flow runs entirely synchronously and is on the hot path of the campaign delivery pipeline.

## Trigger

- **Type**: api-call
- **Source**: `marketingDeliveryClients` — marketing delivery systems invoking `POST /best-for`
- **Frequency**: per-request, on demand during campaign send workflows

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Marketing Delivery Clients | Initiates the flow by calling `POST /best-for` with user + campaign context | `marketingDeliveryClients` |
| API Handlers | Receives and validates the HTTP request; routes to best-for logic | `apiHandlers` |
| Best-For Logic | Orchestrates eligibility evaluation, filtering, scoring, and ranking | `bestForLogic` |
| Campaign Metadata Access | Reads eligibility rules and user attributes from PostgreSQL | `campaignMetaAccess` |
| PostgreSQL | Stores delivery rules and user attributes for eligibility evaluation | `absPostgres` |
| Cassandra | Stores send history and frequency cap records | `absCassandra` |
| Redis | Stores real-time decisioning counters and cached campaign data | `absRedis` |

## Steps

1. **Receive best-for request**: Marketing delivery client sends user context and available campaign list.
   - From: `marketingDeliveryClients`
   - To: `apiHandlers`
   - Protocol: REST/HTTPS

2. **Route to best-for logic**: API handler validates the request payload and invokes the best-for logic component.
   - From: `apiHandlers`
   - To: `bestForLogic`
   - Protocol: direct (in-process)

3. **Query eligibility rules and user attributes**: Best-for logic reads delivery rules and user-level attributes from PostgreSQL (or in-memory cache if preloaded).
   - From: `bestForLogic` via `campaignMetaAccess`
   - To: `absPostgres`
   - Protocol: PostgreSQL

4. **Check send history and frequency caps**: Best-for logic queries Cassandra for each candidate campaign to determine whether the user has already received it and whether frequency caps are exhausted.
   - From: `bestForLogic` via `campaignMetaAccess`
   - To: `absCassandra`
   - Protocol: CQL

5. **Query real-time decisioning counters**: Best-for logic reads current counter state from Redis for fine-grained rate limit and quota checks.
   - From: `bestForLogic`
   - To: `absRedis`
   - Protocol: Redis

6. **Run scoring algorithm**: Best-for logic combines eligibility rule evaluation, cap status, and counter data to score and rank eligible campaigns; ineligible campaigns are filtered out.
   - From: `bestForLogic`
   - To: `bestForLogic`
   - Protocol: direct (in-process)

7. **Return ranked eligible campaign list**: API handler serializes the ranked list and returns it to the caller.
   - From: `apiHandlers`
   - To: `marketingDeliveryClients`
   - Protocol: REST/HTTPS (JSON response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| PostgreSQL unavailable | Fall back to in-memory cached delivery rules if preloaded | Partial eligibility evaluation; rule changes since last load not reflected |
| Cassandra unavailable | Cannot verify send history or frequency caps | Request fails; send history check cannot be skipped safely |
| Redis unavailable | Cannot read real-time counters | Request fails; counter-dependent eligibility cannot be evaluated |
| No eligible campaigns found | Return empty ranked list | Caller receives empty result; no campaigns to arbitrate |
| Invalid request payload | Return HTTP 400 with error detail | Request rejected before any data store access |

## Sequence Diagram

```
marketingDeliveryClients -> apiHandlers: POST /best-for (user context + campaign list)
apiHandlers -> bestForLogic: invoke best-for evaluation
bestForLogic -> absPostgres: query delivery rules and user attributes
absPostgres --> bestForLogic: eligibility rules and user attribute data
bestForLogic -> absCassandra: query send history and frequency caps per campaign
absCassandra --> bestForLogic: send history records and cap state
bestForLogic -> absRedis: query real-time decisioning counters
absRedis --> bestForLogic: counter values
bestForLogic -> bestForLogic: score and rank eligible campaigns
bestForLogic --> apiHandlers: ranked eligible campaign list
apiHandlers --> marketingDeliveryClients: HTTP 200 (ranked campaign list JSON)
```

## Related

- Architecture dynamic view: `dynamic-bestForSelection`
- Related flows: [Arbitration Decision](arbitration-decision.md) — consumes best-for output
- Related flows: [Startup Cache Loading](startup-cache-loading.md) — preloads delivery rules used in step 3
