---
service: "custom-fields-service"
title: "Create Field Template"
generated: "2026-03-03"
type: flow
flow_name: "create-field-template"
flow_type: synchronous
trigger: "API call — POST /v1/fields"
participants:
  - "upstream-caller"
  - "continuumCustomFieldsService"
  - "continuumCustomFieldsDatabase"
architecture_ref: "dynamic-ValidateCustomFields"
---

# Create Field Template

## Summary

This flow creates a new custom field template definition in the service. An administrative or inventory-service caller submits a `CustomFieldsTemplate` payload defining the field structure (field types, localized labels, validation constraints, prepopulation sources, and optional template metadata). The service validates the template structure before persisting it. On success, the generated UUID identifying the new template is returned.

## Trigger

- **Type**: api-call
- **Source**: Administrative tooling, merchant configuration systems, or inventory services provisioning their checkout field requirements
- **Frequency**: On demand — infrequent; templates are long-lived and reused across many checkouts

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Administrative / inventory service caller | Submits the template definition JSON | — |
| Custom Fields Service | Validates structure and persists the template | `continuumCustomFieldsService` |
| Custom Fields Database | Stores the created template | `continuumCustomFieldsDatabase` |

## Steps

1. **Receive creation request**: Caller sends `POST /v1/fields` with `Content-Type: application/json` and a `CustomFieldsTemplate` body. An optional `id` UUID may be specified to use as the template identifier; if omitted the service generates one.
   - From: `upstream-caller`
   - To: `continuumCustomFieldsService` (`CustomFieldsResource`)
   - Protocol: REST/HTTP

2. **Validate template structure**: `CustomFieldsTemplateValidator` inspects the submitted template:
   - Checks each field has a required `type` and `localizedContents` with at least one locale entry containing a `label`
   - Checks each non-GROUP field has a `property` identifier
   - Validates field type constraints (e.g., PHONE fields may have `countryCodes`; numeric fields may have `minValue`/`maxValue`)
   - Returns an `InvalidTemplateResponse` listing all structural violations if validation fails
   - From: `continuumCustomFieldsService` (`CustomFieldsResource` → `CustomFieldsTemplateValidator`)
   - To: `continuumCustomFieldsService` (internal)
   - Protocol: in-process

3. **Check for ID conflict (if id supplied)**: If the caller supplied an explicit UUID, `CustomFieldsDAO` checks whether a template with that ID already exists.
   - From: `continuumCustomFieldsService` (`CustomFieldsDAO`)
   - To: `continuumCustomFieldsDatabase`
   - Protocol: JDBC (PostgreSQL)

4. **Persist template**: `CustomFieldsDAO` inserts the new field set and all child field templates into PostgreSQL.
   - From: `continuumCustomFieldsService` (`CustomFieldsDAO`)
   - To: `continuumCustomFieldsDatabase`
   - Protocol: JDBC (PostgreSQL)

5. **Return created template**: Responds `201 Created` (or `200 OK`) with a `CustomFields` response body including the generated/assigned `id`, `createdAt` timestamp, and `version`.
   - From: `continuumCustomFieldsService`
   - To: `upstream-caller`
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Template structure invalid | `CustomFieldsTemplateValidator` rejects before DB write | Caller receives `400` with `InvalidTemplateResponse{invalidFields:[{refersTo, message}]}` |
| Supplied UUID already exists | DAO detects conflict | Caller receives `409 Conflict` with the conflicting ID in the response body |
| Operation not permitted | Service configured to reject creation (operation guard) | Caller receives `405 Method Not Allowed` |

## Sequence Diagram

```
UpstreamCaller -> CustomFieldsService: POST /v1/fields
UpstreamCaller -> CustomFieldsService: body: CustomFieldsTemplate{fields:[{type,localizedContents,property,...}]}
CustomFieldsService -> CustomFieldsService: CustomFieldsTemplateValidator.validate(template)
  [if invalid] CustomFieldsService --> UpstreamCaller: 400 InvalidTemplateResponse{invalidFields:[...]}
  [if valid]
CustomFieldsService -> CustomFieldsDatabase: check UUID conflict [if id supplied]
CustomFieldsDatabase --> CustomFieldsService: exists/not-exists
  [if conflict] CustomFieldsService --> UpstreamCaller: 409 Conflict "<conflicting-uuid>"
  [if no conflict]
CustomFieldsService -> CustomFieldsDatabase: INSERT field set + field templates
CustomFieldsDatabase --> CustomFieldsService: success
CustomFieldsService --> UpstreamCaller: 201 Created CustomFields{id, createdAt, version, fields}
```

## Related

- Architecture dynamic view: `dynamic-ValidateCustomFields`
- Related flows: [Retrieve Localized Field Set](retrieve-field-set.md), [Validate Filled Fields](validate-filled-fields.md)
