---
service: "custom-fields-service"
title: "Validate Filled Fields"
generated: "2026-03-03"
type: flow
flow_name: "validate-filled-fields"
flow_type: synchronous
trigger: "API call — POST /v1/fields/{uuid}/validate"
participants:
  - "upstream-caller"
  - "continuumCustomFieldsService"
  - "continuumCustomFieldsDatabase"
architecture_ref: "dynamic-ValidateCustomFields"
---

# Validate Filled Fields

## Summary

This flow validates a set of purchaser-provided field values against the stored custom field template identified by UUID. The service loads the template's validation rules from PostgreSQL, iterates over all field definitions (flattening any GROUP fields), and checks each submitted value against its type-specific rules (required, pattern, min/max length/value, boolean acceptance). If all values are valid the service responds `204 No Content`; otherwise it returns `400` with a detailed list of invalid fields and error codes.

## Trigger

- **Type**: api-call
- **Source**: Upstream checkout service or inventory service submitting the purchaser's filled form
- **Frequency**: Per-request — called once per checkout form submission

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Upstream checkout/inventory service | Submits filled field values for validation | — |
| Custom Fields Service | Loads template, validates values, returns result | `continuumCustomFieldsService` |
| Custom Fields Database | Provides the stored field template and validation rules | `continuumCustomFieldsDatabase` |

## Steps

1. **Receive validation request**: Upstream caller sends `POST /v1/fields/{uuid}/validate?locale={locale}` with body `{"fieldProperty": "value", ...}`.
   - From: `upstream-caller`
   - To: `continuumCustomFieldsService` (`CustomFieldsResource`)
   - Protocol: REST/HTTP

2. **Load validator for template**: `CustomFieldsValidatorFetcher` calls `CustomFieldsDAO` to load the unlocalized field template by UUID. Constructs a `CustomFieldsValidator` from the template's field definitions.
   - From: `continuumCustomFieldsService` (`CustomFieldsValidatorFetcher`)
   - To: `continuumCustomFieldsDatabase`
   - Protocol: JDBC (PostgreSQL)

3. **Flatten field hierarchy**: `CustomFieldsValidator` recursively flattens any GROUP-typed fields into a flat list of validatable leaf fields.
   - From: `continuumCustomFieldsService` (internal)
   - To: `continuumCustomFieldsService` (internal)
   - Protocol: in-process

4. **Validate each field value**: For each field template in the flattened list, the validator checks the submitted value:
   - If value is present: delegates to a type-specific `AbstractValidator` via `ValidatorFactory` (checks pattern, min/max length for TEXT; phone format via libphonenumber for PHONE; email format via commons-validator for EMAIL; numeric range for NUMBER; boolean acceptance for BOOLEAN)
   - If value is absent and field is `required`: marks field invalid with `CHECKOUT_FIELD_REQUIRED` (or `CHECKOUT_FIELD_MUST_BE_TRUE` for BOOLEAN)
   - From: `continuumCustomFieldsService` (internal)
   - To: `continuumCustomFieldsService` (internal)
   - Protocol: in-process

5. **Return validation result**: If all fields are valid, responds `204 No Content`. If any fields are invalid, responds `400 Bad Request` with `InvalidFieldsResponse` containing the list of invalid fields, their `refersTo` property names, error `code` values, and human-readable `message` strings.
   - From: `continuumCustomFieldsService`
   - To: `upstream-caller`
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| UUID not found in database | `CustomFieldsDAO` returns empty; service returns `404` | Caller receives `{"httpCode": 404, "message": "custom field not found"}` |
| One or more fields fail validation | Collect all invalid fields into `InvalidFieldsResponse` | Caller receives `400` with full list of `InvalidField` entries |
| Required field not submitted | Treated as validation failure with `CHECKOUT_FIELD_REQUIRED` code | Included in `400` response `fields` array |
| Boolean field not accepted | Treated as validation failure with `CHECKOUT_FIELD_MUST_BE_TRUE` code | Included in `400` response `fields` array |

## Sequence Diagram

```
UpstreamCaller -> CustomFieldsService: POST /v1/fields/{uuid}/validate?locale=en_US
UpstreamCaller -> CustomFieldsService: body: {"firstName":"Bob","email":"bob@example.com",...}
CustomFieldsService -> CustomFieldsDatabase: SELECT field template by UUID (unlocalized)
CustomFieldsDatabase --> CustomFieldsService: field template with validation rules
CustomFieldsService -> CustomFieldsService: flatten GROUP fields into leaf field list
CustomFieldsService -> CustomFieldsService: for each field: check required + type-specific rules
CustomFieldsService --> UpstreamCaller: 204 No Content [all valid]
  -- OR --
CustomFieldsService --> UpstreamCaller: 400 Bad Request InvalidFieldsResponse{fields:[{refersTo,code,message}]}
```

## Related

- Architecture dynamic view: `dynamic-ValidateCustomFields`
- Related flows: [Retrieve Localized Field Set](retrieve-field-set.md), [Validate Merged Fields](validate-merged-fields.md)
