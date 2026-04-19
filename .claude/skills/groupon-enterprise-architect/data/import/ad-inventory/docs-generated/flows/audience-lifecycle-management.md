---
service: "ad-inventory"
title: "Audience Lifecycle Management"
generated: "2026-03-03"
type: flow
flow_name: "audience-lifecycle-management"
flow_type: synchronous
trigger: "Inbound HTTP API call to AiAudienceResource (create, fetch, or delete audience)"
participants:
  - "continuumAdInventoryService_aiAudienceResource"
  - "continuumAdInventoryService_amsClient"
  - "continuumAudienceManagementService"
  - "continuumAdInventoryService_abstractAudienceService"
  - "continuumAdInventoryMySQL"
  - "continuumAdInventoryService_gcpClient"
  - "continuumAdInventoryGcs"
architecture_ref: "components-continuum-ad-inventory-service-components"
---

# Audience Lifecycle Management

## Summary

Audience Lifecycle Management covers the creation, retrieval, and deletion of audience definitions that power ad targeting. When an audience is created, the service validates it against the authoritative Audience Management Service (AMS), stores the audience metadata and targeting configuration in MySQL, and manages the associated bloom filter file in GCS. The bloom filter encodes audience membership (cookied users) and is later loaded into Redis caches during the [Audience Cache Warm-Up](audience-cache-warm-up.md) flow to power real-time placement targeting.

## Trigger

- **Type**: api-call (internal ad management tooling or operator action)
- **Source**: Internal ad management clients or operators invoking the audience management API
- **Frequency**: On-demand (audience configuration changes)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Audience Management Client | Initiates audience create/fetch/delete request | External caller |
| Ai Audience Resource | JAX-RS handler; orchestrates validation, persistence, and GCS operations | `continuumAdInventoryService_aiAudienceResource` |
| AMS Client | Fetches authoritative audience details from AMS for validation | `continuumAdInventoryService_amsClient` |
| Audience Management Service (AMS) | Source of truth for audience definitions | `continuumAudienceManagementService` |
| Audience Service (JDBI) | DAO-backed CRUD for audience and target persistence | `continuumAdInventoryService_abstractAudienceService` |
| Ad Inventory MySQL | Persists audience records and targeting associations | `continuumAdInventoryMySQL` |
| GCP Client | Manages bloom filter files in GCS | `continuumAdInventoryService_gcpClient` |
| Ad Inventory GCS Bucket | Stores bloom filter binary files per audience/segment | `continuumAdInventoryGcs` |

## Steps (Create Audience)

1. **Receive create audience request**: Client submits audience definition (audience ID, segment, targeting rules, placement/country associations).
   - From: Audience Management Client
   - To: `continuumAdInventoryService_aiAudienceResource`
   - Protocol: REST / HTTP

2. **Fetch audience details from AMS**: `AiAudienceResource` calls `AMSClient.getAudienceDetails(audienceId, region)` to validate the audience exists and retrieve authoritative metadata.
   - From: `continuumAdInventoryService_aiAudienceResource`
   - To: `continuumAdInventoryService_amsClient`
   - Protocol: in-process call

3. **Call AMS**: `AMSClient` makes an outbound HTTP GET to the AMS service at `amsConfig.na.url` or `amsConfig.intl.url` depending on the region.
   - From: `continuumAdInventoryService_amsClient`
   - To: `continuumAudienceManagementService`
   - Protocol: REST / HTTP (OkHttp)

4. **Validate AMS response**: `AiAudienceResource` validates AMS returned a valid audience; returns 4xx if not found or invalid.
   - From: `continuumAdInventoryService_amsClient`
   - To: `continuumAdInventoryService_aiAudienceResource`
   - Protocol: in-process return

5. **Persist audience and targets to MySQL**: `AiAudienceResource` calls `AbstractAudienceService` to persist the audience definition and its placement-country-format targeting rules.
   - From: `continuumAdInventoryService_aiAudienceResource`
   - To: `continuumAdInventoryService_abstractAudienceService`
   - Protocol: in-process call

6. **Write audience record to MySQL**: `AbstractAudienceService` executes JDBI DAO inserts/updates for audience and audience-target records.
   - From: `continuumAdInventoryService_abstractAudienceService`
   - To: `continuumAdInventoryMySQL`
   - Protocol: JDBI / SQL

7. **Manage bloom filter in GCS**: `AiAudienceResource` calls `GCPClient` to create or update the bloom filter file for the new audience in GCS.
   - From: `continuumAdInventoryService_aiAudienceResource`
   - To: `continuumAdInventoryService_gcpClient`
   - Protocol: in-process call

8. **Upload bloom filter to GCS**: `GCPClient` uploads the bloom filter binary to the configured GCS bucket path.
   - From: `continuumAdInventoryService_gcpClient`
   - To: `continuumAdInventoryGcs`
   - Protocol: GCS SDK

9. **Return success response**: `AiAudienceResource` returns HTTP 200/201 with the created audience record.
   - From: `continuumAdInventoryService_aiAudienceResource`
   - To: Audience Management Client
   - Protocol: REST / HTTP response

## Steps (Delete Audience)

1. Receive delete request for audience ID
2. `AiAudienceResource` calls `AbstractAudienceService` to delete audience and target records from MySQL
3. `AiAudienceResource` calls `GCPClient` to delete the bloom filter file from GCS
4. Return HTTP 200

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AMS returns 404 or error | `AiAudienceResource` returns 4xx to caller | Audience not persisted |
| MySQL write failure | Exception propagated to caller | Audience definition not created; partial state possible if GCS write already occurred |
| GCS upload failure | Exception logged; audience still in MySQL without bloom filter | Cache warm-up will fail for this audience; placement targeting degraded |
| AMS service unavailable | HTTP error returned to caller | Audience creation blocked until AMS recovers |

## Sequence Diagram

```
Client -> AiAudienceResource: POST /audience (audienceId, segment, targets)
AiAudienceResource -> AMSClient: getAudienceDetails(audienceId, region)
AMSClient -> AudienceManagementService: GET audience details (HTTP)
AudienceManagementService --> AMSClient: audience metadata
AMSClient --> AiAudienceResource: validated audience details
AiAudienceResource -> AbstractAudienceService: persist audience + targets
AbstractAudienceService -> MySQL: INSERT audience, INSERT audience_target
MySQL --> AbstractAudienceService: OK
AiAudienceResource -> GCPClient: upload bloom filter
GCPClient -> GCS: PUT bloom filter file
GCS --> GCPClient: OK
AiAudienceResource --> Client: HTTP 201 created
```

## Related

- Architecture dynamic view: `components-continuum-ad-inventory-service-components`
- Related flows: [Audience Cache Warm-Up](audience-cache-warm-up.md), [Ad Placement Serving](ad-placement-serving.md)
