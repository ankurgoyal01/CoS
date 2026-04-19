---
service: "tronicon-cms"
title: "Content Publish Lifecycle"
generated: "2026-03-03"
type: flow
flow_name: "content-publish-lifecycle"
flow_type: synchronous
trigger: "API call from content editor to promote a DRAFT to live VALIDATED state"
participants:
  - "troniconCmsService"
  - "continuumTroniconCmsDatabase"
architecture_ref: "tronicon-cms-cmsService-components"
---

# Content Publish Lifecycle

## Summary

When a content editor is ready to make a draft live, they call the publish endpoint. The service transitions all content items under the specified path, locale, and brand from DRAFT to VALIDATED state, and simultaneously demotes any previously VALIDATED content for that path/locale/brand to ARCHIVED. This ensures exactly one VALIDATED version exists at any time per path/locale/brand combination. After publishing, the content is immediately visible to consumers querying with `status=VALIDATED`.

## Trigger

- **Type**: api-call
- **Source**: Content editor or CMS tooling
- **Frequency**: On demand when draft content is ready to go live

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Content editor / tooling | Initiates the publish request | External caller |
| `TroniconCmsResource` | Receives and routes the HTTP POST request | `troniconCmsService` |
| `CMSService` | Executes the publish state transition logic | `troniconCmsService` |
| `CMSContentDao` | Updates content status in the database | `troniconCmsService` |
| `CMSContentAuditLogDao` | Writes audit log entries for status transitions | `troniconCmsService` |
| MySQL Database | Persists the status changes | `continuumTroniconCmsDatabase` |

## Steps

1. **Receives publish request**: Editor sends `POST /cms/publish/path/{path}?locale=<locale>&brand=<brand>`
   - From: Content editor
   - To: `TroniconCmsResource`
   - Protocol: REST

2. **Routes to service layer**: `TroniconCmsResource` delegates to `CMSService`
   - From: `TroniconCmsResource`
   - To: `CMSService`
   - Protocol: Direct (in-process)

3. **Checks for existing DRAFT**: `CMSService` calls `CMSContentDao` to locate content in DRAFT state for the given path, locale, and brand
   - From: `CMSService` via `CMSContentDao`
   - To: `continuumTroniconCmsDatabase`
   - Protocol: JDBI/MySQL

4. **Demotes existing VALIDATED to ARCHIVED**: If a VALIDATED version exists for the path/locale/brand, `CMSService` calls `CMSContentDao` to update its status to ARCHIVED
   - From: `CMSService` via `CMSContentDao`
   - To: `continuumTroniconCmsDatabase`
   - Protocol: JDBI/MySQL

5. **Promotes DRAFT to VALIDATED**: `CMSService` calls `CMSContentDao` to update all DRAFT items for the path/locale/brand to VALIDATED status
   - From: `CMSService` via `CMSContentDao`
   - To: `continuumTroniconCmsDatabase`
   - Protocol: JDBI/MySQL

6. **Writes audit log**: `CMSService` records audit log entries for the status transitions
   - From: `CMSService` via `CMSContentAuditLogDao`
   - To: `continuumTroniconCmsDatabase`
   - Protocol: JDBI/MySQL

7. **Returns published content**: HTTP 200 with the newly VALIDATED `CMSContent` array
   - From: `TroniconCmsResource`
   - To: Content editor
   - Protocol: REST (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No DRAFT found for path/locale/brand | Not found error | HTTP 404 |
| Locale parameter missing or too short | Validation rejection | HTTP 400 |
| Brand parameter missing | Validation rejection | HTTP 400 |
| Database write failure during status update | Exception propagated | HTTP 500 |

## Sequence Diagram

```
Editor -> TroniconCmsResource: POST /cms/publish/path/{path}?locale=en_US&brand=groupon
TroniconCmsResource -> CMSService: publishCMSContent(path, locale, brand)
CMSService -> CMSContentDao: findByPathLocaleBrandAndStatus(path, locale, brand, DRAFT)
CMSContentDao -> MySQL: SELECT where status='DRAFT'
MySQL --> CMSContentDao: [DRAFT content rows]
CMSService -> CMSContentDao: updateStatus(existingValidated, ARCHIVED)
CMSContentDao -> MySQL: UPDATE SET status='ARCHIVED'
CMSService -> CMSContentDao: updateStatus(draft, VALIDATED)
CMSContentDao -> MySQL: UPDATE SET status='VALIDATED'
CMSService -> CMSContentAuditLogDao: writeAuditLog(transitions)
CMSContentAuditLogDao -> MySQL: INSERT audit_log entries
CMSService --> TroniconCmsResource: List<CMSContent> (VALIDATED)
TroniconCmsResource --> Editor: HTTP 200 [CMSContent[]]
```

## Related

- Architecture dynamic view: `tronicon-cms-cmsService-components`
- Related flows: [Content Authoring and Draft Creation](content-authoring-draft-creation.md), [Content Archive](content-archive.md), [Content Retrieval by Path](content-retrieval-by-path.md)
