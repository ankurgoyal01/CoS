---
service: "custom-fields-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Custom Fields Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Retrieve Localized Field Set](retrieve-field-set.md) | synchronous | API call — `GET /v1/fields/{uuid}` | Loads, translates, and optionally prefills a field set for a given UUID |
| [Validate Filled Fields](validate-filled-fields.md) | synchronous | API call — `POST /v1/fields/{uuid}/validate` | Validates purchaser-submitted field values against a stored template |
| [Create Field Template](create-field-template.md) | synchronous | API call — `POST /v1/fields` | Validates and persists a new custom field template definition |
| [Retrieve Merged Field Set](retrieve-merged-fields.md) | synchronous | API call — `GET /v1/merged_fields` | Loads, merges, and translates multiple field sets into a single combined response |
| [Validate Merged Fields](validate-merged-fields.md) | synchronous | API call — `POST /v1/merged_fields/validate` | Validates purchaser-submitted values against a merged set of field templates |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The validate flow (`POST /v1/fields/{uuid}/validate`) is modeled in the Structurizr architecture as a dynamic view:

- `dynamic-ValidateCustomFields` — shows `continuumCustomFieldsService` loading the template from `continuumCustomFieldsDatabase` and optionally calling `continuumUsersService`

The retrieve flow (`GET /v1/fields/{uuid}` with `purchaserId`) also crosses into `continuumUsersService` for user data prefill. See [Retrieve Localized Field Set](retrieve-field-set.md) for the full participant list.
