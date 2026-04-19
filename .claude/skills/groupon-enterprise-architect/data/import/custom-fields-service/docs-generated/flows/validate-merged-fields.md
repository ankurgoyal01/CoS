---
service: "custom-fields-service"
title: "Validate Merged Fields"
generated: "2026-03-03"
type: flow
flow_name: "validate-merged-fields"
flow_type: synchronous
trigger: "API call — POST /v1/merged_fields/validate"
participants:
  - "upstream-caller"
  - "continuumCustomFieldsService"
  - "continuumCustomFieldsDatabase"
architecture_ref: "dynamic-ValidateCustomFields"
---

# Validate Merged Fields

## Summary

This flow validates purchaser-submitted field values against a merged set of custom field templates identified by the `ids` parameter. The service loads each referenced template, constructs a merged validator that knows the full set of prefixed field definitions, and checks each submitted value against its template's type-specific rules. The flow is the validation counterpart to [Retrieve Merged Field Set](retrieve-merged-fields.md) — both use the same `ids` format and prefix/separator semantics so that the submitted property names match the prefixed names returned during retrieval.

## Trigger

- **Type**: api-call
- **Source**: Upstream checkout service submitting the purchaser's filled form for a multi-product cart
- **Frequency**: Per-request — called once per checkout form submission involving merged fields

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Upstream checkout service | Submits prefixed field values for validation against merged templates | — |
| Custom Fields Service | Loads merged templates, constructs validators, validates values | `continuumCustomFieldsService` |
| Custom Fields Database | Provides each referenced field template's validation rules | `continuumCustomFieldsDatabase` |

## Steps

1. **Receive merged validate request**: Caller sends `POST /v1/merged_fields/validate?ids={ids}&locale={locale}&separator={sep}` with body `{"prefix1.fieldProperty": "value", "prefix2.fieldProperty": "value", ...}`.
   - From: `upstream-caller`
   - To: `continuumCustomFieldsService` (`CustomFieldsResource`)
   - Protocol: REST/HTTP

2. **Parse `ids` parameter**: `MergedCustomFieldsValidatorFetcher` parses the comma-separated `ids` string into `{uuid, prefix, quantity}` tuples using the same logic as the retrieve flow.
   - From: `continuumCustomFieldsService` (internal)
   - To: `continuumCustomFieldsService` (internal)
   - Protocol: in-process

3. **Load validator for each template**: For each UUID, `MergedCustomFieldsValidatorFetcher` calls `CustomFieldsDAO` to read the unlocalized template and constructs a `CustomFieldsValidator` instance per template.
   - From: `continuumCustomFieldsService` (`MergedCustomFieldsValidatorFetcher`)
   - To: `continuumCustomFieldsDatabase`
   - Protocol: JDBC (PostgreSQL)

4. **Apply prefix expansion to validators**: Each validator's field list is prefixed with `{prefix}{separator}` to align with the property names the caller submitted. Quantity expansion creates replicated validators with indexed prefixes for multi-item templates.
   - From: `continuumCustomFieldsService` (internal)
   - To: `continuumCustomFieldsService` (internal)
   - Protocol: in-process

5. **Validate submitted values across all templates**: The merged validator iterates through the combined flattened field list. For each field, checks the submitted map for a matching prefixed property name and applies type-specific validation rules (required, pattern, min/max length, min/max value, boolean, phone format, email format).
   - From: `continuumCustomFieldsService` (internal)
   - To: `continuumCustomFieldsService` (internal)
   - Protocol: in-process

6. **Return validation result**: If all fields across all merged templates are valid, responds `204 No Content`. If any are invalid, responds `400 Bad Request` with `InvalidFieldsResponse` listing each invalid prefixed field's `refersTo`, `code`, and `message`.
   - From: `continuumCustomFieldsService`
   - To: `upstream-caller`
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| One or more UUIDs not found | DAO returns empty for that UUID | Caller receives `404` with `Error` body |
| One or more fields fail validation | All invalid fields collected across all merged templates | Caller receives `400` with `InvalidFieldsResponse` containing full list |
| Required field missing in merged submission | Same required-field logic as single-template validate | `CHECKOUT_FIELD_REQUIRED` error code included for the prefixed field property |
| Invalid `ids` or `separator` format | Parsing fails | Caller receives error response |

## Sequence Diagram

```
UpstreamCaller -> CustomFieldsService: POST /v1/merged_fields/validate?ids=uuid1:prefix1:2,uuid2:prefix2&locale=en_US
UpstreamCaller -> CustomFieldsService: body: {"prefix1.firstName":"Bob","prefix1.email":"bob@example.com","prefix2.phone":"6507521234"}
CustomFieldsService -> CustomFieldsService: parse ids into [(uuid1,prefix1,qty=2),(uuid2,prefix2,qty=1)]
CustomFieldsService -> CustomFieldsDatabase: SELECT template by uuid1 (unlocalized)
CustomFieldsDatabase --> CustomFieldsService: template1 validation rules
CustomFieldsService -> CustomFieldsDatabase: SELECT template by uuid2 (unlocalized)
CustomFieldsDatabase --> CustomFieldsService: template2 validation rules
CustomFieldsService -> CustomFieldsService: apply prefix + quantity expansion to field lists
CustomFieldsService -> CustomFieldsService: validate each submitted value against merged prefixed fields
CustomFieldsService --> UpstreamCaller: 204 No Content [all valid]
  -- OR --
CustomFieldsService --> UpstreamCaller: 400 Bad Request InvalidFieldsResponse{fieldsId, fields:[{refersTo, code, message}]}
```

## Related

- Architecture dynamic view: `dynamic-ValidateCustomFields`
- Related flows: [Retrieve Merged Field Set](retrieve-merged-fields.md), [Validate Filled Fields](validate-filled-fields.md)
