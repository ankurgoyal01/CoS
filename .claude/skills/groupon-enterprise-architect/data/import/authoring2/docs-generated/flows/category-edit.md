---
service: "authoring2"
title: "Category Edit"
generated: "2026-03-03"
type: flow
flow_name: "category-edit"
flow_type: synchronous
trigger: "User submits a category create or update from the Ember.js authoring UI"
participants:
  - "authoring2RestApi"
  - "authoring2ValidationEngine"
  - "authoring2TaxonomyService"
  - "continuumAuthoring2Postgres"
architecture_ref: "components-continuum-authoring2-authoring2TaxonomyService"
---

# Category Edit

## Summary

A taxonomy content author creates, updates, or deletes a category node in the hierarchy using the Ember.js authoring UI. The request is received by the `CategoriesRESTFacade`, validated for business rules (name uniqueness within locale, hierarchy depth limits for customer taxonomy), and persisted to PostgreSQL via JPA. An audit record is written alongside the change to track who made the modification.

## Trigger

- **Type**: api-call (user-action via browser)
- **Source**: Ember.js authoring UI at `https://taxonomy-authoringv2.groupondev.com`
- **Frequency**: On demand; multiple times per day by content authors

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Ember.js UI | Initiates REST call with category payload | — |
| REST Facades | Receives and routes the request | `authoring2RestApi` |
| Validation Engine | Enforces business rules on the category payload | `authoring2ValidationEngine` |
| Taxonomy Domain Services | Executes JPA create/edit/destroy operations | `authoring2TaxonomyService` |
| Authoring2 PostgreSQL | Persists category, relationship, and audit records | `continuumAuthoring2Postgres` |

## Steps

### Create Category

1. **Receives category payload**: Ember.js UI sends `POST /categories` with JSON body containing `name`, `description`, `taxonomyGuid`, `localesId`, `root`.
   - From: `Ember.js UI`
   - To: `authoring2RestApi` (`CategoriesRESTFacade`)
   - Protocol: REST / HTTP POST

2. **Applies default locale**: If `localesId` is absent, defaults to `1` (en_US).
   - From: `CategoriesRESTFacade`
   - To: `authoring2ValidationEngine` (`CategoryValidations`)
   - Protocol: internal

3. **Validates category**: Checks taxonomy existence, hierarchy depth (max depth enforced for customer taxonomy), name format, and parent GUID resolution.
   - From: `authoring2ValidationEngine`
   - To: `continuumAuthoring2Postgres`
   - Protocol: JPA/JDBC (parent GUID lookup)

4. **Persists category**: Writes new `Categories` row to PostgreSQL.
   - From: `authoring2TaxonomyService` (`CategoriesJpaController.create`)
   - To: `continuumAuthoring2Postgres`
   - Protocol: JPA/JDBC

5. **Returns created category**: Responds with the persisted category entity as JSON (HTTP 200).
   - From: `authoring2RestApi`
   - To: Ember.js UI
   - Protocol: REST / HTTP 200 JSON

### Update Category

Steps are identical except step 4 calls `CategoriesJpaController.edit` instead of `create`, and validation uses `validateCategoryUpdate`.

### Delete Category

1. Receives `DELETE /categories/{id}`.
2. Loads all locale variants, relationships, and attributes for the category GUID.
3. Destroys all associated records (categories by GUID, relationships, attributes) in PostgreSQL.
4. Returns the deleted category summary as JSON.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Category has children (on delete) | `GET /categories/delete/{id}` returns 400 with message | Client warned before actual delete |
| Taxonomy GUID not found | Validation throws exception | HTTP 400 with `{"error": "..."}` |
| Max hierarchy depth exceeded | `validateCategorySize` throws | HTTP 400 with `{"error": "..."}` |
| Parent GUID not resolvable | Validation exception | HTTP 400 with `{"error": "..."}` |
| Locale-specific category not found | Falls back to en_US locale, returns empty name/description fields | HTTP 200 with partial data |

## Sequence Diagram

```
Ember.js UI -> CategoriesRESTFacade: POST /categories (JSON payload)
CategoriesRESTFacade -> CategoryValidations: validateCategory(entity, parentGuid, localesId)
CategoryValidations -> CategoriesJpaController: findCategoriesByGuid(parentGuid, 1)
CategoriesJpaController -> PostgreSQL: SELECT categories WHERE guid = ?
PostgreSQL --> CategoriesJpaController: parent category
CategoriesJpaController --> CategoryValidations: parent resolved
CategoryValidations --> CategoriesRESTFacade: validated Categories entity
CategoriesRESTFacade -> CategoriesJpaController: create(cat)
CategoriesJpaController -> PostgreSQL: INSERT INTO categories ...
PostgreSQL --> CategoriesJpaController: persisted row
CategoriesRESTFacade --> Ember.js UI: HTTP 200 JSON (category entity)
```

## Related

- Architecture dynamic view: `components-continuum-authoring2-authoring2TaxonomyService`
- Related flows: [Bulk Taxonomy Import](bulk-taxonomy-import.md), [Category Export](category-export.md)
