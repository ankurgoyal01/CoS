---
service: "marketing-and-editorial-content-service"
title: "Text Content Create with Profanity Check"
generated: "2026-03-03"
type: flow
flow_name: "text-content-create"
flow_type: synchronous
trigger: "POST /mecs/text with JSON body"
participants:
  - "mecs_api"
  - "mecs_business"
  - "mecs_dataAccess"
  - "continuumMarketingEditorialContentPostgresWrite"
architecture_ref: "components-continuum-marketing-editorial-content-service"
---

# Text Content Create with Profanity Check

## Summary

An internal client submits a JSON text content record for storage. Before persisting, MECS runs a language-aware profanity check using the Groupon `ProfanityChecker` library. If profanities are detected, the request is rejected with a 422 response listing the offending terms. If the content is clean, MECS assigns a system-generated UUID, saves the record to PostgreSQL, and a database trigger records the INSERT action in the `text_audit` table.

## Trigger

- **Type**: api-call
- **Source**: Internal client (e.g., editorial authoring tool) via `POST /mecs/text`
- **Frequency**: On demand, triggered when a marketing author creates a new text content asset

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Internal client | Initiates text content creation | — |
| API Resources | Receives, validates, and orchestrates the create request | `mecs_api` |
| Content Services | Applies profanity check and delegates to data access | `mecs_business` |
| Data Access Layer | Persists text content record to PostgreSQL | `mecs_dataAccess` |
| MECS Postgres (Write) | Stores text record and triggers audit insertion | `continuumMarketingEditorialContentPostgresWrite` |

## Steps

1. **Receive JSON request**: Client sends `POST /mecs/text` with `Content-Type: application/json`. The body is a `TextContent` object with a component type (one of `TESTING`, `PUSH_NOTIFICATION`, `EMAIL_CONTENT`, `WH_TEXT`, `WH_JSON`) and associated metadata.
   - From: Internal client
   - To: `mecs_api` (TextResource)
   - Protocol: HTTP/JSON

2. **Validate ClientId authentication**: The jtier auth bundle validates the `clientId` query parameter.
   - From: `mecs_api`
   - To: ClientId auth store (PostgreSQL)
   - Protocol: JDBC

3. **Deserialize and validate**: Dropwizard/Jersey deserializes the JSON body into a `TextContent` object and runs Bean Validation (`@Valid @NotNull`).
   - From: `mecs_api`
   - To: `mecs_api` (internal)
   - Protocol: direct

4. **Assign system UUID**: `TextResource` overrides any caller-supplied UUID with a freshly generated `UUID.randomUUID()` to ensure system-controlled identifiers.
   - From: `mecs_api`
   - To: `mecs_api` (internal)
   - Protocol: direct

5. **Profanity check**: `TextResource` calls `ProfanityService.checkForProfanity(content)`. `GrouponProfanityService` serializes the content to JSON and invokes `ProfanityChecker.listProfanities(sentence, language)` using the locale derived from the content's `Locale` field. Falls back to `en` if the specific language is not found.
   - From: `mecs_api`
   - To: `mecs_business` (GrouponProfanityService)
   - Protocol: direct

6. **Reject if profanity found**: If `listProfanities` returns a non-empty list, `GrouponProfanityService` throws a `ProfanityException`, which the `ProfanityExceptionMapper` maps to a 422 response containing the list of detected terms.
   - From: `mecs_business`
   - To: Internal client
   - Protocol: HTTP/JSON (422 Unprocessable Entity)

7. **Persist text record**: If clean, `TextResource` calls `TextContentService.save(content)`, which writes the record to PostgreSQL via the data access layer. A PostgreSQL trigger (`text_audit`) automatically inserts an `INSERT` row into `text_audit`.
   - From: `mecs_dataAccess`
   - To: `continuumMarketingEditorialContentPostgresWrite`
   - Protocol: JDBC

8. **Return created response**: `TextResource` returns a `201 Created` response with the persisted `TextContent` entity and a `Location` header.
   - From: `mecs_api`
   - To: Internal client
   - Protocol: HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Profanity detected in content | `ProfanityException` thrown by `GrouponProfanityService`; mapped by `ProfanityExceptionMapper` | 422 Unprocessable Entity with list of profane terms |
| Language not found in profanity checker | Falls back to `fallbackLanguage: en` | Profanity check continues with English word list |
| Fallback language also not found | `UnsupportedOperationException` thrown | 500 Internal Server Error |
| Bean validation failure | `JerseyViolationExceptionMapper` or `ConstraintViolationExceptionMapper` | 422 Unprocessable Entity |
| Missing UUID in body | UUID is always replaced by system-generated value | Not an error; handled transparently |
| PostgreSQL write failure | JDBI exception propagates | 500 Internal Server Error |

## Sequence Diagram

```
Client -> TextResource: POST /mecs/text (JSON TextContent)
TextResource -> AuthBundle: validate clientId
AuthBundle --> TextResource: authenticated
TextResource -> TextResource: deserialize, validate, assign UUID
TextResource -> GrouponProfanityService: checkForProfanity(content)
GrouponProfanityService -> ProfanityChecker: listProfanities(json, language)
ProfanityChecker --> GrouponProfanityService: [] (no profanities)
GrouponProfanityService --> TextResource: (no exception)
TextResource -> TextContentService: save(content)
TextContentService -> DataAccessLayer: save(TextContent)
DataAccessLayer -> PostgresWrite: INSERT INTO text; trigger INSERT INTO text_audit
PostgresWrite --> DataAccessLayer: saved TextContent
DataAccessLayer --> TextContentService: saved TextContent
TextContentService --> TextResource: saved TextContent
TextResource --> Client: 201 Created, Location: /mecs/text/{uuid}, body: TextContent
```

## Related

- Architecture component view: `components-continuum-marketing-editorial-content-service`
- Related flows: [Content Search and Retrieval](content-search-and-retrieval.md), [Content Delete with Audit](content-delete.md)
