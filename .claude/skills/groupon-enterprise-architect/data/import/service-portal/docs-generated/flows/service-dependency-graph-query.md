---
service: "service-portal"
title: "Service Dependency Graph Query"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "service-dependency-graph-query"
flow_type: synchronous
trigger: "API call — GET /api/v2/services/{id}/dependencies"
participants:
  - "continuumServicePortalWeb"
  - "continuumServicePortalDb"
---

# Service Dependency Graph Query

## Summary

A consumer (engineering team, tooling, or dashboard) queries the declared dependency graph for a specific service by calling the REST API. The web process retrieves the dependency edges for the requested service from MySQL and returns them as a structured JSON response. This enables consumers to understand service-to-service relationships for impact analysis, ORR reviews, and architecture documentation.

## Trigger

- **Type**: api-call
- **Source**: Engineering team, internal tooling, or architecture dashboard calling `GET /api/v2/services/{id}/dependencies`
- **Frequency**: On-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (engineering team / tooling) | Initiates the dependency query | external caller |
| Rails Web App | Receives and processes the API request | `continuumServicePortalWeb` |
| MySQL Database | Source of dependency graph records | `continuumServicePortalDb` |

## Steps

1. **Receive dependency query request**: Consumer sends `GET /api/v2/services/{id}/dependencies`.
   - From: Consumer
   - To: `continuumServicePortalWeb`
   - Protocol: HTTPS REST

2. **Validate service exists**: Rails controller queries `continuumServicePortalDb` to confirm the requested service ID exists.
   - From: `continuumServicePortalWeb`
   - To: `continuumServicePortalDb`
   - Protocol: MySQL (ActiveRecord)

3. **Fetch dependency edges**: Controller queries the `dependencies` table for all outbound (and optionally inbound) dependency edges for the service.
   - From: `continuumServicePortalWeb`
   - To: `continuumServicePortalDb`
   - Protocol: MySQL (ActiveRecord)

4. **Resolve dependency targets**: For each dependency edge, the controller resolves the target service record to include name, tier, and status in the response.
   - From: `continuumServicePortalWeb`
   - To: `continuumServicePortalDb`
   - Protocol: MySQL (ActiveRecord join / eager load)

5. **Return dependency list**: HTTP 200 response with JSON array of dependency records (source, target, dependency type) returned to the consumer.
   - From: `continuumServicePortalWeb`
   - To: Consumer
   - Protocol: HTTPS REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Service ID not found | ActiveRecord RecordNotFound raised | HTTP 404 Not Found |
| MySQL connectivity failure | ActiveRecord exception raised | HTTP 500; error logged via sonoma-logger |
| Service has no declared dependencies | Empty array returned | HTTP 200 with empty `dependencies` array |

## Sequence Diagram

```
Consumer -> continuumServicePortalWeb: GET /api/v2/services/{id}/dependencies
continuumServicePortalWeb -> continuumServicePortalDb: SELECT services WHERE id = {id}
continuumServicePortalDb --> continuumServicePortalWeb: service record (or not found)
continuumServicePortalWeb -> continuumServicePortalDb: SELECT dependencies WHERE source_service_id = {id}
continuumServicePortalDb --> continuumServicePortalWeb: dependency edges
continuumServicePortalWeb -> continuumServicePortalDb: SELECT services WHERE id IN (target_ids)
continuumServicePortalDb --> continuumServicePortalWeb: target service records
continuumServicePortalWeb --> Consumer: 200 OK (dependency list JSON)
```

## Related

- Architecture dynamic view: `dynamic-dependency-graph-query`
- Related flows: [Service Registration and Metadata Sync](service-registration-and-metadata-sync.md), [Operational Readiness Review](operational-readiness-review.md)
