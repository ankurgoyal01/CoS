---
service: "travel-inventory"
title: "Rate Plan Management"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "rate-plan-management"
flow_type: synchronous
trigger: "API call -- Extranet rate plan CRUD endpoints"
participants:
  - "continuumTravelInventoryService"
  - "continuumTravelInventoryDb"
  - "continuumTravelInventoryHotelProductCache"
  - "continuumTravelInventoryInventoryProductCache"
architecture_ref: "dynamic-rate-plan-management"
---

# Rate Plan Management

## Summary

This flow handles the creation, retrieval, and update of rate plans through the Extranet API. Rate plans define pricing, restrictions, and availability rules for specific room types within a hotel. When a rate plan is created or updated, the Extranet Domain persists the changes to MySQL, writes audit log entries, and triggers cache invalidation in the Redis caches to ensure shopping flows reflect the latest pricing.

## Trigger

- **Type**: api-call
- **Source**: Getaways Extranet UI or internal tooling calling rate plan CRUD endpoints
- **Frequency**: On-demand, as merchants manage rate plan configurations

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Extranet API | Receives rate plan CRUD requests | `continuumTravelInventoryService_extranetApi` |
| Extranet Domain Services | Validates business rules and orchestrates rate plan operations | `continuumTravelInventoryService_extranetDomain` |
| Persistence Layer | Persists rate plan data and audit log entries | `continuumTravelInventoryService_persistence` |
| Domain Entities | Represents rate plan, restriction, and fee entities | `continuumTravelInventoryService_entities` |
| Getaways Inventory DB | System of record for rate plan data | `continuumTravelInventoryDb` |
| Caching Layer | Invalidates and updates Redis caches after rate plan changes | `continuumTravelInventoryService_caching` |
| Hotel Product Detail Cache | Redis cache invalidated after changes | `continuumTravelInventoryHotelProductCache` |
| Inventory Product Cache | Redis cache invalidated after changes | `continuumTravelInventoryInventoryProductCache` |
| Audit Domain Services | Records audit log entries for rate plan changes | `continuumTravelInventoryService_auditDomain` |

## Steps

1. **Receive rate plan request**: Merchant or Extranet UI calls a rate plan endpoint (e.g., `POST /v2/getaways/inventory/roomtypes/{roomTypeId}/rateplans` to create, or `PUT /v2/getaways/inventory/rateplans/{ratePlanId}` to update).
   - From: `caller`
   - To: `continuumTravelInventoryService_extranetApi`
   - Protocol: REST

2. **Delegate to Extranet Domain**: Extranet API passes the request to Extranet Domain Services for validation and processing.
   - From: `continuumTravelInventoryService_extranetApi`
   - To: `continuumTravelInventoryService_extranetDomain`
   - Protocol: direct

3. **Validate business rules**: Extranet Domain validates the rate plan data against business rules -- verifying that the room type exists, pricing is valid, date ranges are consistent, and restrictions are well-formed.
   - From: `continuumTravelInventoryService_extranetDomain`
   - To: `continuumTravelInventoryService_entities`
   - Protocol: direct

4. **Persist rate plan to database**: Persistence Layer writes the new or updated rate plan record to MySQL, including any associated restrictions, fees, and availability overrides.
   - From: `continuumTravelInventoryService_extranetDomain`
   - To: `continuumTravelInventoryService_persistence` -> `continuumTravelInventoryDb`
   - Protocol: JDBC, Ebean ORM

5. **Write audit log entry**: Audit Domain records an audit log entry capturing the rate plan change, including the before/after state, user, and timestamp.
   - From: `continuumTravelInventoryService_extranetDomain`
   - To: `continuumTravelInventoryService_auditDomain` -> `continuumTravelInventoryService_persistence` -> `continuumTravelInventoryDb`
   - Protocol: JDBC, Ebean ORM

6. **Invalidate Redis caches**: Caching Layer invalidates affected entries in the Hotel Product Detail Cache and Inventory Product Cache to ensure shopping flows pick up the updated rate plan.
   - From: `continuumTravelInventoryService_extranetDomain`
   - To: `continuumTravelInventoryService_caching` -> `continuumTravelInventoryHotelProductCache`, `continuumTravelInventoryInventoryProductCache`
   - Protocol: Redis

7. **Return response to caller**: Extranet API returns the created or updated rate plan details to the caller.
   - From: `continuumTravelInventoryService_extranetApi`
   - To: `caller`
   - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid rate plan data | Validation error returned before persistence | HTTP 400; no changes persisted |
| Room type not found | Validation error | HTTP 404; rate plan not created |
| MySQL write failure | Transaction rolled back | HTTP 500; rate plan not created/updated |
| Cache invalidation failure | Rate plan persisted but cache stale | Shopping flows may serve stale pricing until cache TTL expires |
| Audit log write failure | Rate plan persisted but audit entry not written | Rate plan change is effective; audit gap logged for investigation |

## Sequence Diagram

```
caller -> continuumTravelInventoryService_extranetApi: POST /roomtypes/{id}/rateplans or PUT /rateplans/{id}
continuumTravelInventoryService_extranetApi -> continuumTravelInventoryService_extranetDomain: delegate request
continuumTravelInventoryService_extranetDomain -> continuumTravelInventoryService_entities: validate business rules
continuumTravelInventoryService_extranetDomain -> continuumTravelInventoryDb: persist rate plan (INSERT/UPDATE)
continuumTravelInventoryService_extranetDomain -> continuumTravelInventoryDb: write audit log entry
continuumTravelInventoryService_extranetDomain -> continuumTravelInventoryService_caching: invalidate hotel product cache (Redis)
continuumTravelInventoryService_extranetDomain -> continuumTravelInventoryService_caching: invalidate inventory product cache (Redis)
continuumTravelInventoryService_extranetApi --> caller: 200 OK / 201 Created + rate plan response
```

## Related

- Architecture dynamic view: `dynamic-rate-plan-management`
- Related flows: [Hotel Availability Check](hotel-availability-check.md), [Reservation Creation](reservation-creation.md)
