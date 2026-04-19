---
service: "partner-attributes-mapping-service"
title: "Mapping Request Flow"
generated: "2026-03-03"
type: flow
flow_name: "mapping-request-flow"
flow_type: synchronous
trigger: "HTTP API call to a mapping endpoint (POST /v1/mapping, POST /v1/search_partner_mappings, POST /v1/search_groupon_mappings, PUT /v1/groupon_mappings, PUT /v1/partner_mappings, DELETE /v1/groupon_mapping/{grouponId})"
participants:
  - "pams_requestFilters"
  - "pams_apiResources"
  - "pams_mappingService"
  - "pams_mappingDao"
  - "continuumPartnerAttributesMappingPostgres"
architecture_ref: "dynamic-pams-mapping-request-flow"
---

# Mapping Request Flow

## Summary

This flow covers all CRUD operations on the bidirectional ID mapping table (`partner_attributes_map`). A caller submits an HTTP request with a `client-id` header and an optional `X-Brand` partner namespace header. The request passes through validation filters, is handled by the mapping resource, processed by the mapping service (which enforces business rules such as duplicate detection and single-entry update constraints), and is ultimately persisted to or read from the PostgreSQL database via the JDBI DAO.

## Trigger

- **Type**: api-call
- **Source**: Internal Groupon service (CLO distribution system) calling any mapping endpoint
- **Frequency**: On demand, per API request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Caller (internal service) | Initiates the HTTP request | (tracked in central architecture model) |
| `pams_requestFilters` | Validates `client-id` header presence; logs request payload | `pams_requestFilters` |
| `pams_apiResources` | Routes request to appropriate mapping handler; serializes response | `pams_apiResources` |
| `pams_mappingService` | Enforces mapping business rules; orchestrates DAO calls | `pams_mappingService` |
| `pams_mappingDao` | Executes SQL queries against the mappings table | `pams_mappingDao` |
| `continuumPartnerAttributesMappingPostgres` | Stores and returns mapping rows | `continuumPartnerAttributesMappingPostgres` |

## Steps

### Create Mapping (`POST /v1/mapping`)

1. **Receives request**: Caller sends `POST /v1/mapping` with `client-id` header, optional `X-Brand` header, and JSON body containing entity-type-keyed lists of `{grouponId, partnerId}` pairs.
   - From: Caller
   - To: `pams_requestFilters`
   - Protocol: REST / HTTP

2. **Validates headers and logs payload**: `HeadersValidationFilter` checks `client-id` presence (returns HTTP 403 if missing); `RequestPayloadLoggingFilter` logs the request body for observability.
   - From: `pams_requestFilters`
   - To: `pams_apiResources`
   - Protocol: Jersey filter chain

3. **Validates mapping payload**: `PartnerAttributesMappingResource.validateMappings()` checks for empty, blank, or duplicate `grouponId`/`partnerId` values within the request. Returns HTTP 400 `BadRequestException` on failure.
   - From: `pams_apiResources`
   - To: `pams_mappingService` (via `PartnerAttributesMappingService.createMapping()`)
   - Protocol: Direct (in-process)

4. **Checks for duplicates**: `PartnerAttributesMappingService` calls `PartnerAttributeMapDao.findDuplicateMappingWithIds()` to detect any existing rows matching the supplied `grouponId` or `partnerId` values for the given namespace and entity type. Throws `DuplicateMappingsException` (HTTP 409) if duplicates are found.
   - From: `pams_mappingService`
   - To: `pams_mappingDao`
   - Protocol: Direct (in-process)

5. **Persists new mappings**: `PartnerAttributeMapDao.create()` executes a batch insert into `partner_attributes_map`.
   - From: `pams_mappingDao`
   - To: `continuumPartnerAttributesMappingPostgres`
   - Protocol: JDBI / PostgreSQL

6. **Returns HTTP 200**: The resource returns an empty 200 OK response on success.
   - From: `pams_apiResources`
   - To: Caller
   - Protocol: REST / HTTP

### Search Mappings (`POST /v1/search_partner_mappings` or `POST /v1/search_groupon_mappings`)

1. **Receives request**: Caller sends search request with a list of IDs keyed by entity type.
   - From: Caller
   - To: `pams_requestFilters`
   - Protocol: REST / HTTP

2. **Validates headers and logs payload**: Same as create flow.
   - From: `pams_requestFilters`
   - To: `pams_apiResources`

3. **Dispatches lookup**: Resource calls `PartnerAttributesMappingService.getMappingsByPartnerId()` or `getMappingsByGrouponId()` with the partner namespace (from `X-Brand`) and the list of IDs.
   - From: `pams_apiResources`
   - To: `pams_mappingService`
   - Protocol: Direct (in-process)

4. **Queries database (read-only pool)**: The read-only JDBI instance executes `getMappingsByPartnerId()` or `getMappingsByGrouponId()` against `partner_attributes_map`.
   - From: `pams_mappingDao` (read-only)
   - To: `continuumPartnerAttributesMappingPostgres`
   - Protocol: JDBI / PostgreSQL

5. **Returns mapped pairs**: The service assembles an `AttributeMaps` response object and the resource returns HTTP 200 with the entity-type-keyed mapping pairs.
   - From: `pams_apiResources`
   - To: Caller
   - Protocol: REST / HTTP

### Update Mapping (`PUT /v1/groupon_mappings` or `PUT /v1/partner_mappings`)

1. **Receives request**: Caller provides a single `{grouponId, partnerId}` pair to update.
2. **Validates single mapping**: `checkIfSingle()` enforces exactly one mapping entry per request; returns HTTP 400 otherwise.
3. **Executes update**: `updateMappings()` calls `updateGrouponMapping()` or `updatePartnerMapping()` on the DAO. Returns HTTP 404 if no row is found.
4. **Returns updated mapping**: HTTP 200 with the updated `AttributeMaps` object.

### Delete Mapping (`DELETE /v1/groupon_mapping/{grouponId}`)

1. **Receives request**: Caller provides a Groupon UUID path parameter and `X-Brand` partner namespace.
2. **Checks existence**: `PartnerAttributesMappingService.exists()` calls `PartnerAttributeMapDao.exists()`. Returns HTTP 404 if not found.
3. **Deletes row**: `deleteMappingByGrouponId()` executes `DELETE ... RETURNING *` on `partner_attributes_map`.
4. **Returns result**: HTTP 200 with the deleted `AttributeMap` entity, or HTTP 404 if the delete returned null.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing `client-id` header | `HeadersValidationFilter` rejects immediately | HTTP 403 with `ErrorResponse` |
| Blank or duplicate IDs in payload | `validateMappings()` throws `BadRequestException` | HTTP 400 with list of invalid entries in payload |
| Duplicate mapping already exists | `createMapping()` throws `DuplicateMappingsException` | HTTP 409 with conflicting mappings in response payload |
| Mapping not found (update/delete) | `MappingNotFoundExceptionMapper` handles the exception | HTTP 404 with `ErrorResponse` |
| More than one entry in update request | `checkIfSingle()` throws `BadRequestException` | HTTP 400 |
| Database error | `JdbiExceptionMapper` / `GenericExceptionMapper` | HTTP 500 with `ErrorResponse` |
| Unauthorized brand for update/delete | `HeadersValidationFilter` / brand check | HTTP 401 |

## Sequence Diagram

```
Caller -> pams_requestFilters: HTTP request (client-id, X-Brand, body)
pams_requestFilters -> pams_apiResources: Validated and logged request
pams_apiResources -> pams_mappingService: Handle mapping operation
pams_mappingService -> pams_mappingDao: Create/read/update/delete mappings
pams_mappingDao -> continuumPartnerAttributesMappingPostgres: Persist/read mapping rows
continuumPartnerAttributesMappingPostgres --> pams_mappingDao: Result rows
pams_mappingDao --> pams_mappingService: Domain objects
pams_mappingService --> pams_apiResources: Result
pams_apiResources --> Caller: HTTP 200 (or error response)
```

## Related

- Architecture dynamic view: `dynamic-pams-mapping-request-flow`
- Related flows: [Signature Creation Flow](signature-creation-flow.md), [Partner Secret Management Flow](partner-secret-management-flow.md)
- See [API Surface](../api-surface.md) for full endpoint documentation
