---
service: "regulatory-consent-log"
title: "Cookie Validation"
generated: "2026-03-03"
type: flow
flow_name: "cookie-validation"
flow_type: synchronous
trigger: "GET /v1/cookie?b_cookie={uuid} from API-Lazlo or API-Torii"
participants:
  - "continuumRegulatoryConsentLogApi"
  - "continuumRegulatoryConsentLogApi_cookieResource"
  - "continuumRegulatoryConsentLogApi_cookieReadAdapter"
  - "continuumRegulatoryConsentLogDb"
architecture_ref: "dynamic-cookieValidation"
---

# Cookie Validation

## Summary

This flow allows GAPI services (API-Lazlo, API-Torii) to determine whether a given b-cookie belongs to an erased user. The RCL API looks up the cookie UUID in the erased cookie mapping table in Postgres. If a match is found, it returns the associated erased-user information (user ID, creation timestamp, event ID). If no match is found, it returns HTTP 204 with no body, indicating the cookie belongs to a non-erased user. This check is critical to prevent erased users from being re-associated with their deleted accounts via stale cookies.

## Trigger

- **Type**: api-call
- **Source**: API-Lazlo or API-Torii calling `GET /v1/cookie?b_cookie={uuid}` when validating a b-cookie during user lookup.
- **Frequency**: Per user request that involves a b-cookie lookup (SLA: 15,000 RPM in US datacenters, 10,000 RPM in EMEA; p99 10ms, p95 6ms).

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API-Lazlo | Issues `GET /v1/cookie` request to validate a b-cookie | External caller |
| API-Torii | Issues `GET /v1/cookie` request to validate a b-cookie | External caller |
| Get Cookie Resource | Receives the HTTP request; delegates to read adapter | `continuumRegulatoryConsentLogApi_cookieResource` |
| Cookie Read Adapter | Queries Postgres for erased cookie mapping | `continuumRegulatoryConsentLogApi_cookieReadAdapter` |
| Regulatory Consent Log Postgres | Stores erased cookie-to-user mappings | `continuumRegulatoryConsentLogDb` |

## Steps

1. **Receive request**: API-Lazlo (or API-Torii) sends `GET /v1/cookie?b_cookie={uuid}` with `X-API-KEY` header.
   - From: API-Lazlo / API-Torii
   - To: `continuumRegulatoryConsentLogApi_cookieResource`
   - Protocol: REST / HTTP/JSON

2. **Fetch erased cookie mapping**: The `Cookie Read Adapter` queries the erased cookie mapping table in Postgres for the provided `b_cookie` UUID.
   - From: `continuumRegulatoryConsentLogApi_cookieResource`
   - To: `continuumRegulatoryConsentLogApi_cookieReadAdapter` → `continuumRegulatoryConsentLogDb`
   - Protocol: JDBI / SQL

3a. **Cookie belongs to erased user (match found)**: The adapter returns a `CookieDbRow` containing the erased user's ID, event ID, creation timestamp, and metadata. The endpoint returns `HTTP 200 OK` with `GetErasedUserInfoForBCookieResponse`.
   - From: `continuumRegulatoryConsentLogApi_cookieResource`
   - To: API-Lazlo / API-Torii
   - Protocol: REST / HTTP/JSON

3b. **Cookie does not belong to erased user (no match)**: The adapter returns no row. The endpoint returns `HTTP 204 No Content`.
   - From: `continuumRegulatoryConsentLogApi_cookieResource`
   - To: API-Lazlo / API-Torii
   - Protocol: REST / HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| RCL service unavailable | Upstream caller (API-Lazlo/Torii) treats as non-erased user | Cookie treated as valid; corrected when RCL recovers |
| Postgres read failure | `HTTP 500 Internal Server Error` | Upstream treats as non-erased user per documented fallback |
| Invalid or missing `b_cookie` query param | `HTTP 400 Bad Request` | No query executed |
| Invalid API key | `HTTP 401 Unauthorized` | No query executed |
| Postgres replication lag | Stale `HTTP 204` returned (cookie appears valid when it should be 200) | Corrected when replication catches up |

## Sequence Diagram

```
APILazlo -> GetCookieResource: GET /v1/cookie?b_cookie={uuid} (X-API-KEY)
GetCookieResource -> CookieReadAdapter: Fetch erased cookie mapping for uuid
CookieReadAdapter -> Postgres: SELECT FROM erased_cookie_mapping WHERE b_cookie={uuid}
Postgres --> CookieReadAdapter: Row (if found) or empty

alt Cookie belongs to erased user
    CookieReadAdapter --> GetCookieResource: CookieDbRow { userId, eventId, createdAt, metadata }
    GetCookieResource --> APILazlo: HTTP 200 OK { userId, eventId, createdAt, metadata }
else No erased user for this cookie
    CookieReadAdapter --> GetCookieResource: Empty result
    GetCookieResource --> APILazlo: HTTP 204 No Content
end
```

## Related

- Architecture dynamic view: `dynamic-cookieValidation`
- Related flows: [User Erasure Pipeline](user-erasure-pipeline.md)
