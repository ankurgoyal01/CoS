---
service: "custom-fields-service"
title: "Retrieve Localized Field Set"
generated: "2026-03-03"
type: flow
flow_name: "retrieve-field-set"
flow_type: synchronous
trigger: "API call — GET /v1/fields/{uuid}"
participants:
  - "upstream-caller"
  - "continuumCustomFieldsService"
  - "continuumCustomFieldsDatabase"
  - "continuumUsersService"
architecture_ref: "dynamic-ValidateCustomFields"
---

# Retrieve Localized Field Set

## Summary

This flow handles a consumer requesting the localized definition of a custom field set by UUID. The service loads the template from PostgreSQL, applies locale-based label translation, and — when a `purchaserId` is supplied — calls the Users Service to fetch profile data and prefill matching field values. The combined field definition is returned to the caller as a JSON response.

## Trigger

- **Type**: api-call
- **Source**: Upstream inventory service (TPIS, GLive, VIS, Getaways, Goods) or checkout frontend
- **Frequency**: Per-request — called at checkout time when the product's custom fields need to be displayed to the purchaser

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Upstream inventory service | Initiates the request; passes `uuid`, `locale`, and optional `purchaserId` | — |
| Custom Fields Service | Orchestrates the retrieval, translation, and prefill | `continuumCustomFieldsService` |
| Custom Fields Database | Provides the stored field template | `continuumCustomFieldsDatabase` |
| Users Service | Provides purchaser profile data for prefill (conditional) | `continuumUsersService` |

## Steps

1. **Receive field retrieval request**: Upstream caller sends `GET /v1/fields/{uuid}?locale={locale}&purchaserId={purchaserId}`.
   - From: `upstream-caller`
   - To: `continuumCustomFieldsService` (`CustomFieldsResource`)
   - Protocol: REST/HTTP

2. **Load template from database**: `LocalizedCustomFieldsFetcher` calls `CustomFieldsDAO` to read the field template by UUID.
   - From: `continuumCustomFieldsService` (`LocalizedCustomFieldsFetcher`)
   - To: `continuumCustomFieldsDatabase`
   - Protocol: JDBC (PostgreSQL)

3. **Apply locale translation**: `LocalizedCustomFieldsFetcher` applies the requested `locale` to resolve localized labels and hints from the template's `localizedContents` map (defaults to `en_US` if not found).
   - From: `continuumCustomFieldsService` (internal)
   - To: `continuumCustomFieldsService` (internal)
   - Protocol: in-process

4. **Fetch user profile data (conditional)**: If `purchaserId` is present, `UserDataFetcher` calls `UserServiceClient` → `GET users/v1/accounts?id={purchaserId}` with `X-Request-Id` header. Response is cached in Guava (10,000 entries, 5-unit TTL in production).
   - From: `continuumCustomFieldsService` (`UserDataFetcher` via `UserServiceClient`)
   - To: `continuumUsersService`
   - Protocol: REST/HTTP

5. **Apply prefill values**: For each field template with a `prepopulationSource` (`firstName`, `lastName`, `email`, `phone`), copy the matching value from the user profile into the field's `value` property.
   - From: `continuumCustomFieldsService` (internal)
   - To: `continuumCustomFieldsService` (internal)
   - Protocol: in-process

6. **Return localized (and optionally prefilled) field set**: Responds `200 OK` with a `CustomFields` JSON object containing the translated fields and any prefilled values.
   - From: `continuumCustomFieldsService`
   - To: `upstream-caller`
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| UUID not found in database | `CustomFieldsDAO` returns empty; service returns `404` with `Error` body | Caller receives `{"httpCode": 404, "message": "custom field not found"}` |
| Users Service unavailable or slow | `UserServiceClient` times out (connect 1s, read 0.5s); field returned without prefill | Caller receives fields with no prefilled values; flow degrades gracefully |
| Users Service returns no user for `purchaserId` | Empty user data; prefill skipped | Caller receives fields with no prefilled values |
| Invalid `locale` | Locale not found in `localizedContents`; falls back to base locale | Caller receives fields in fallback locale |

## Sequence Diagram

```
UpstreamCaller -> CustomFieldsService: GET /v1/fields/{uuid}?locale=en_US&purchaserId={id}
CustomFieldsService -> CustomFieldsDatabase: SELECT field template by UUID
CustomFieldsDatabase --> CustomFieldsService: field template rows
CustomFieldsService -> CustomFieldsService: apply locale translation to labels/hints
CustomFieldsService -> UsersService: GET users/v1/accounts?id={purchaserId} [if purchaserId present]
UsersService --> CustomFieldsService: [{ firstName, lastName, email, phone }]
CustomFieldsService -> CustomFieldsService: apply prepopulation values to matching fields
CustomFieldsService --> UpstreamCaller: 200 OK CustomFields{id, fields[{label, type, value, ...}]}
```

## Related

- Architecture dynamic view: `dynamic-ValidateCustomFields`
- Related flows: [Validate Filled Fields](validate-filled-fields.md), [Retrieve Merged Field Set](retrieve-merged-fields.md)
