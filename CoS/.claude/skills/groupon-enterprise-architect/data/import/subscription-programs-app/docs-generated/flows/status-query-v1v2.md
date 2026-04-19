---
service: "subscription-programs-app"
title: "Status Query (v1 and v2)"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "status-query-v1v2"
flow_type: synchronous
trigger: "API call — GET /select/{consumerId}/membership (v1) or GET /select-v2/{consumerId} (v2)"
participants:
  - "selectApi"
  - "membershipService"
  - "subscriptionRepository"
  - "continuumSubscriptionProgramsDb"
architecture_ref: "dynamic-status-query-v1v2"
---

# Status Query (v1 and v2)

## Summary

This flow retrieves the current membership state for a given consumer. The v1 endpoint (`GET /select/{consumerId}/membership`) returns the base membership record. The v2 endpoint (`GET /select-v2/{consumerId}`) returns an enhanced response that includes richer status representation and reactivation eligibility metadata, enabling UIs and downstream services to make more informed decisions about how to present Select membership options.

## Trigger

- **Type**: api-call
- **Source**: MBNXT frontend, internal tooling, or support agents
- **Frequency**: Per-request (high-frequency, called on every page load for consumers in the Select funnel)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Select API | Routes the inbound GET request to Membership Service | `selectApi` |
| Membership Service | Retrieves and assembles the membership response; applies v2 enrichment logic | `membershipService` |
| Subscription Repository | Reads membership record from database | `subscriptionRepository` |
| Subscription Programs DB | Authoritative source for membership state | `continuumSubscriptionProgramsDb` |

## Steps

### v1 — GET /select/{consumerId}/membership

1. **Receive status query**: Caller requests membership status for a consumer.
   - From: `caller`
   - To: `selectApi`
   - Protocol: REST

2. **Fetch membership record**: Subscription Repository reads the membership row for the consumer from `mm_programs`.
   - From: `subscriptionRepository`
   - To: `continuumSubscriptionProgramsDb`
   - Protocol: JDBC / MySQL

3. **Return membership status**: Select API returns the membership record (status, planId, dates) to the caller.
   - From: `selectApi`
   - To: `caller`
   - Protocol: REST

### v2 — GET /select-v2/{consumerId}

1. **Receive v2 status query**: Caller requests enhanced membership status.
   - From: `caller`
   - To: `selectApi`
   - Protocol: REST

2. **Fetch membership record**: Subscription Repository reads the membership row from `mm_programs`.
   - From: `subscriptionRepository`
   - To: `continuumSubscriptionProgramsDb`
   - Protocol: JDBC / MySQL

3. **Evaluate reactivation eligibility**: Membership Service applies business rules to determine whether the consumer is eligible to reactivate a cancelled or expired membership.
   - From: `membershipService`
   - To: `subscriptionRepository` (additional queries if needed)
   - Protocol: Direct (in-process)

4. **Assemble enriched response**: Membership Service constructs the v2 response with richer status enum, reactivation eligibility flag, and any additional context.
   - From: `membershipService`
   - To: `selectApi`
   - Protocol: Direct (in-process)

5. **Return enriched membership status**: Select API returns the v2 membership response to the caller.
   - From: `selectApi`
   - To: `caller`
   - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No membership record found | Return membership status as NOT_ENROLLED or equivalent | 404 or empty membership response per API contract |
| DB connectivity failure | Query fails; no cached fallback (cache2k does not cache individual membership records) | 503 returned to caller |

## Sequence Diagram

```
Caller         -> selectApi            : GET /select/{consumerId}/membership (v1)
selectApi      -> membershipService    : getMembership(consumerId)
membershipService -> subscriptionRepository : findByConsumerId(consumerId)
subscriptionRepository -> continuumSubscriptionProgramsDb : SELECT * FROM membership WHERE consumerId
continuumSubscriptionProgramsDb --> subscriptionRepository : membershipRecord
subscriptionRepository --> membershipService : membershipRecord
membershipService --> selectApi        : membershipRecord
selectApi      --> Caller              : 200 OK, membershipRecord

--- v2 variant ---

Caller         -> selectApi            : GET /select-v2/{consumerId}
selectApi      -> membershipService    : getMembershipV2(consumerId)
membershipService -> subscriptionRepository : findByConsumerId(consumerId)
subscriptionRepository -> continuumSubscriptionProgramsDb : SELECT * FROM membership WHERE consumerId
continuumSubscriptionProgramsDb --> subscriptionRepository : membershipRecord
membershipService -> membershipService : evaluateReactivationEligibility(membershipRecord)
membershipService --> selectApi        : enrichedMembershipV2
selectApi      --> Caller              : 200 OK, enrichedMembershipV2
```

## Related

- Architecture dynamic view: `dynamic-status-query-v1v2`
- Related flows: [Create Subscription](create-subscription.md), [Reactivate v2 Membership](reactivate-v2-membership.md), [Cancel Subscription](cancel-subscription.md)
