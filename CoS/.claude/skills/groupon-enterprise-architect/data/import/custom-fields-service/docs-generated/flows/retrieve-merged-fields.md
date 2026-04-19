---
service: "custom-fields-service"
title: "Retrieve Merged Field Set"
generated: "2026-03-03"
type: flow
flow_name: "retrieve-merged-fields"
flow_type: synchronous
trigger: "API call — GET /v1/merged_fields"
participants:
  - "upstream-caller"
  - "continuumCustomFieldsService"
  - "continuumCustomFieldsDatabase"
  - "continuumUsersService"
architecture_ref: "dynamic-ValidateCustomFields"
---

# Retrieve Merged Field Set

## Summary

This flow retrieves and combines multiple custom field templates into a single merged field set. The caller provides a comma-separated `ids` parameter containing entries in `uuid:prefix:quantity` or `uuid:prefix` format. The service loads each referenced template from PostgreSQL, applies locale translation, prefixes each field's `property` name to prevent collision, optionally multiplies fields by the specified quantity, and — when `purchaserId` is provided — prefills matching fields with user profile data. The result is a single unified `CustomFields` response.

## Trigger

- **Type**: api-call
- **Source**: Checkout service requiring combined field definitions for a cart containing multiple products with different field requirements
- **Frequency**: Per-request — called when a checkout session involves products from multiple inventory services each contributing their own field template

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Upstream checkout service | Initiates the request with multiple template IDs, optional locale and purchaserId | — |
| Custom Fields Service | Loads, merges, translates, and prefills multiple templates | `continuumCustomFieldsService` |
| Custom Fields Database | Provides each referenced field template | `continuumCustomFieldsDatabase` |
| Users Service | Provides purchaser profile data for prefill (conditional) | `continuumUsersService` |

## Steps

1. **Receive merged-fields request**: Caller sends `GET /v1/merged_fields?ids={uuid1:prefix1:qty1,uuid2:prefix2}&locale={locale}&purchaserId={purchaserId}&separator={sep}`.
   - From: `upstream-caller`
   - To: `continuumCustomFieldsService` (`CustomFieldsResource`)
   - Protocol: REST/HTTP

2. **Parse `ids` parameter**: `MergedLocalizedCustomFieldsFetcher` parses the comma-separated `ids` string into a list of `{uuid, prefix, quantity}` tuples. The `separator` (default `.`) determines how prefix is joined with the original property name.
   - From: `continuumCustomFieldsService` (internal)
   - To: `continuumCustomFieldsService` (internal)
   - Protocol: in-process

3. **Load each template from database**: For each UUID in the parsed list, `MergedLocalizedCustomFieldsFetcher` calls `CustomFieldsDAO` to read the corresponding field template.
   - From: `continuumCustomFieldsService` (`MergedLocalizedCustomFieldsFetcher`)
   - To: `continuumCustomFieldsDatabase`
   - Protocol: JDBC (PostgreSQL) — one read per unique UUID

4. **Apply locale translation per template**: Each loaded template's `localizedContents` is resolved for the requested locale, producing translated labels and hints for all fields.
   - From: `continuumCustomFieldsService` (internal)
   - To: `continuumCustomFieldsService` (internal)
   - Protocol: in-process

5. **Apply prefix and quantity expansion**: Each field's `property` is prefixed (`{prefix}{separator}{originalProperty}`). If `quantity > 1`, the field set is replicated the specified number of times with indexed prefixes to support multi-item checkout.
   - From: `continuumCustomFieldsService` (internal)
   - To: `continuumCustomFieldsService` (internal)
   - Protocol: in-process

6. **Fetch user profile data (conditional)**: If `purchaserId` is supplied, `UserDataFetcher` calls `UserServiceClient` → `GET users/v1/accounts?id={purchaserId}`. Cached per Guava cache configuration.
   - From: `continuumCustomFieldsService` (`UserDataFetcher` via `UserServiceClient`)
   - To: `continuumUsersService`
   - Protocol: REST/HTTP

7. **Apply prefill values to merged fields**: For each field in the merged set with a `prepopulationSource`, sets the `value` from the user profile data.
   - From: `continuumCustomFieldsService` (internal)
   - To: `continuumCustomFieldsService` (internal)
   - Protocol: in-process

8. **Return merged field set**: Responds `200 OK` with a single `CustomFields` response containing all merged, prefixed, translated, and optionally prefilled fields.
   - From: `continuumCustomFieldsService`
   - To: `upstream-caller`
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| One or more UUIDs not found | DAO returns empty for that UUID | Caller receives `404` with `Error` body |
| Users Service unavailable | Timeout; prefill skipped; merged fields returned without prefill values | Graceful degradation |
| Invalid `ids` format | Parsing failure; service returns error response | Caller receives error response |

## Sequence Diagram

```
UpstreamCaller -> CustomFieldsService: GET /v1/merged_fields?ids=uuid1:prefix1:2,uuid2:prefix2&locale=en_US&purchaserId={id}
CustomFieldsService -> CustomFieldsService: parse ids into [(uuid1, prefix1, qty=2), (uuid2, prefix2, qty=1)]
CustomFieldsService -> CustomFieldsDatabase: SELECT template by uuid1
CustomFieldsDatabase --> CustomFieldsService: template1 fields
CustomFieldsService -> CustomFieldsDatabase: SELECT template by uuid2
CustomFieldsDatabase --> CustomFieldsService: template2 fields
CustomFieldsService -> CustomFieldsService: apply locale translation to each template
CustomFieldsService -> CustomFieldsService: apply prefix + quantity expansion per template
CustomFieldsService -> UsersService: GET users/v1/accounts?id={purchaserId} [if present]
UsersService --> CustomFieldsService: [{firstName, lastName, email, phone}]
CustomFieldsService -> CustomFieldsService: apply prefill to matching fields
CustomFieldsService --> UpstreamCaller: 200 OK CustomFields{fields:[all merged prefixed fields]}
```

## Related

- Architecture dynamic view: `dynamic-ValidateCustomFields`
- Related flows: [Retrieve Localized Field Set](retrieve-field-set.md), [Validate Merged Fields](validate-merged-fields.md)
