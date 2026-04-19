---
service: "regulatory-consent-log"
title: "Consent Retrieval"
generated: "2026-03-03"
type: flow
flow_name: "consent-retrieval"
flow_type: synchronous
trigger: "GET /v1/consents from a consumer or administrative service"
participants:
  - "continuumRegulatoryConsentLogApi"
  - "continuumRegulatoryConsentLogApi_getConsentsEndpoint"
  - "continuumRegulatoryConsentLogApi_getConsentsService"
  - "continuumRegulatoryConsentLogApi_getConsentsDbAdapter"
  - "continuumRegulatoryConsentLogDb"
architecture_ref: "dynamic-consentRetrieval"
---

# Consent Retrieval

## Summary

This flow retrieves consent records for a given user identifier. A caller provides an `identifierValue` (user UUID or b-cookie value) and an optional `workflowType` filter; the service queries Postgres and returns all matching consent records. This endpoint is primarily used for debugging and audit purposes.

## Trigger

- **Type**: api-call
- **Source**: Debugging tools, audit scripts, or administrative services calling `GET /v1/consents`.
- **Frequency**: On demand (not in a primary consumer-facing request path per the OpenAPI documentation).

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Caller | Issues `GET /v1/consents` with query parameters | External caller |
| Get Consents Endpoint | Receives the HTTP request; routes to service | `continuumRegulatoryConsentLogApi_getConsentsEndpoint` |
| Get Consents Service | Executes the lookup with optional workflow filter | `continuumRegulatoryConsentLogApi_getConsentsService` |
| Get Consents DB Adapter | Reads consent rows from Postgres using JDBI mappers | `continuumRegulatoryConsentLogApi_getConsentsDbAdapter` |
| Regulatory Consent Log Postgres | Source of consent records | `continuumRegulatoryConsentLogDb` |

## Steps

1. **Receive request**: Caller sends `GET /v1/consents?identifierValue={value}[&workflowType={type}][&isConsumerId={bool}]` with `X-API-KEY` header.
   - From: caller
   - To: `continuumRegulatoryConsentLogApi_getConsentsEndpoint`
   - Protocol: REST / HTTP/JSON

2. **Route to service**: The endpoint delegates the lookup to the `Get Consents Service`, passing the query parameters.
   - From: `continuumRegulatoryConsentLogApi_getConsentsEndpoint`
   - To: `continuumRegulatoryConsentLogApi_getConsentsService`
   - Protocol: direct (Java function composition)

3. **Query Postgres**: The `Get Consents DB Adapter` executes a read query against the `regulatory_consent_logs` table, filtering by `identifierValue` and optionally by `workflowType`.
   - From: `continuumRegulatoryConsentLogApi_getConsentsService`
   - To: `continuumRegulatoryConsentLogApi_getConsentsDbAdapter` → `continuumRegulatoryConsentLogDb`
   - Protocol: JDBI / SQL

4. **Map results**: JDBI mappers (`ConsentDbMapper`) convert DB rows into `ConsentsDbModel` objects.
   - From: `continuumRegulatoryConsentLogApi_getConsentsDbAdapter`
   - To: `continuumRegulatoryConsentLogApi_getConsentsService`
   - Protocol: direct

5. **Return 200**: The endpoint returns `HTTP 200 OK` with a `GetConsentResponseBody` containing the `legalConsents` array.
   - From: `continuumRegulatoryConsentLogApi_getConsentsEndpoint`
   - To: caller
   - Protocol: REST / HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `identifierValue` not provided | `HTTP 400 Bad Request` | No query executed |
| No records found | `HTTP 200 OK` with empty `legalConsents` array | Empty result returned |
| Postgres read failure | `HTTP 500 Internal Server Error` | Error surfaced to caller |
| Invalid API key | `HTTP 401 Unauthorized` | No query executed |

## Sequence Diagram

```
Caller -> GetConsentsEndpoint: GET /v1/consents?identifierValue=...&workflowType=... (X-API-KEY)
GetConsentsEndpoint -> GetConsentsService: Lookup request with params
GetConsentsService -> GetConsentsDbAdapter: Execute consent query
GetConsentsDbAdapter -> Postgres: SELECT regulatory_consent_logs WHERE identifierValue=... [AND workflowType=...]
Postgres --> GetConsentsDbAdapter: Rows
GetConsentsDbAdapter --> GetConsentsService: List<ConsentsDbModel>
GetConsentsService --> GetConsentsEndpoint: Mapped consent items
GetConsentsEndpoint --> Caller: HTTP 200 OK { legalConsents: [...] }
```

## Related

- Architecture dynamic view: `dynamic-consentRetrieval`
- Related flows: [Consent Creation](consent-creation.md)
