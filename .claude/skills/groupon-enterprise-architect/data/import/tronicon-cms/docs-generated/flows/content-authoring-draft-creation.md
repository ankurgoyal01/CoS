---
service: "tronicon-cms"
title: "Content Authoring and Draft Creation"
generated: "2026-03-03"
type: flow
flow_name: "content-authoring-draft-creation"
flow_type: synchronous
trigger: "API call from content editor or tooling creating or updating a CMS content draft"
participants:
  - "troniconCmsService"
  - "continuumTroniconCmsDatabase"
architecture_ref: "tronicon-cms-cmsService-components"
---

# Content Authoring and Draft Creation

## Summary

A content editor (or automated tooling) creates or updates CMS content items in DRAFT state. Content can be created from scratch via the upsert endpoint, or cloned from an existing VALIDATED version to produce a new DRAFT with an incremented version number. Only one DRAFT per path/locale/brand combination is permitted at a time. The service validates all required fields and business rules before persisting.

## Trigger

- **Type**: api-call
- **Source**: Content editor, CMS UI tooling, or internal automation
- **Frequency**: On demand when content changes are required

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Content editor / tooling | Initiates content creation or update request | External caller |
| `TroniconCmsResource` | Receives and routes the HTTP request | `troniconCmsService` |
| `CMSService` | Coordinates content upsert or clone logic | `troniconCmsService` |
| `CMSContentValidator` | Validates payload: locale, contentType, status, brand | `troniconCmsService` |
| `CMSContentDao` | Persists new or updated content record | `troniconCmsService` |
| `CMSContentAuditLogDao` | Writes audit log entry for the change | `troniconCmsService` |
| MySQL Database | Stores content and audit log records | `continuumTroniconCmsDatabase` |

## Steps

### Path A — Create / Update via Upsert

1. **Receives upsert request**: Editor sends `POST /cms/update-all` with a JSON array of `CMSContent` objects
   - From: Content editor
   - To: `TroniconCmsResource`
   - Protocol: REST (JSON body)

2. **Routes to service layer**: `TroniconCmsResource` delegates to `CMSService`
   - From: `TroniconCmsResource`
   - To: `CMSService`
   - Protocol: Direct (in-process)

3. **Validates payload**: `CMSService` invokes `CMSContentValidator` to check locale (min 5 chars), `contentType` (`json` or `html`), `status` (`DRAFT` or `VALIDATED`), and `brand` (`groupon`, `livingsocial`, or `test`)
   - From: `CMSService`
   - To: `CMSContentValidator`
   - Protocol: Direct (in-process)

4. **Persists content**: For new items (no ID in payload), `CMSContentDao` inserts with version=1. For updates (ID present), `CMSContentDao` updates the matching record; `created`, `createdBy`, and `version` fields are not modifiable
   - From: `CMSService` via `CMSContentDao`
   - To: `continuumTroniconCmsDatabase`
   - Protocol: JDBI/MySQL

5. **Writes audit log**: `CMSService` calls `CMSContentAuditLogDao` to record the change
   - From: `CMSService` via `CMSContentAuditLogDao`
   - To: `continuumTroniconCmsDatabase`
   - Protocol: JDBI/MySQL

6. **Returns saved content**: HTTP 200 with the persisted `CMSContent` array
   - From: `TroniconCmsResource`
   - To: Content editor
   - Protocol: REST (JSON)

### Path B — Clone Existing Version as Draft

1. **Receives clone request**: Editor sends `POST /cms/path/{path}/clone?locale=<locale>&brand=<brand>&version=<version>`
   - From: Content editor
   - To: `TroniconCmsResource`
   - Protocol: REST

2. **Routes to service layer**: Delegates to `CMSService`

3. **Checks for existing draft**: `CMSService` queries `CMSContentDao` to verify no DRAFT exists for this path/locale/brand
   - From: `CMSService` via `CMSContentDao`
   - To: `continuumTroniconCmsDatabase`
   - Protocol: JDBI/MySQL

4. **Clones content records**: `CMSService` fetches the source version records and inserts new DRAFT copies with auto-incremented version number
   - From: `CMSService` via `CMSContentDao`
   - To: `continuumTroniconCmsDatabase`
   - Protocol: JDBI/MySQL

5. **Returns new draft version list**: HTTP 200 with `CMSContentShowPathVersionList`
   - From: `TroniconCmsResource`
   - To: Content editor
   - Protocol: REST (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid locale (< 5 characters) | Validation rejection | HTTP 400 |
| Invalid contentType (not json or html) | Validation rejection | HTTP 400 |
| Invalid brand | Validation rejection | HTTP 400 |
| Content ID not found (update path) | Not found error | HTTP 404 |
| JSON parsing failure | Error response | HTTP 400 |
| Draft already exists (clone path) | Conflict rejection | HTTP 406 |
| Database write failure | Exception propagated | HTTP 500 |

## Sequence Diagram

```
Editor -> TroniconCmsResource: POST /cms/update-all [CMSContent[]]
TroniconCmsResource -> CMSService: updateCMSContent(List<CMSContent>)
CMSService -> CMSContentValidator: validate(content)
CMSContentValidator --> CMSService: valid / throws ValidationException
CMSService -> CMSContentDao: insert/update(content)
CMSContentDao -> MySQL: INSERT/UPDATE cms_content
MySQL --> CMSContentDao: saved record
CMSService -> CMSContentAuditLogDao: writeAuditLog(change)
CMSContentAuditLogDao -> MySQL: INSERT audit_log
MySQL --> CMSContentAuditLogDao: ok
CMSService --> TroniconCmsResource: List<CMSContent>
TroniconCmsResource --> Editor: HTTP 200 [CMSContent[]]
```

## Related

- Architecture dynamic view: `tronicon-cms-cmsService-components`
- Related flows: [Content Publish Lifecycle](content-publish-lifecycle.md), [Content Retrieval by Path](content-retrieval-by-path.md)
