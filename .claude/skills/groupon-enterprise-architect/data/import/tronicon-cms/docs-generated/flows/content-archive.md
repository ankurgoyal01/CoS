---
service: "tronicon-cms"
title: "Content Archive"
generated: "2026-03-03"
type: flow
flow_name: "content-archive"
flow_type: synchronous
trigger: "API call from content editor explicitly archiving a VALIDATED content path"
participants:
  - "troniconCmsService"
  - "continuumTroniconCmsDatabase"
architecture_ref: "tronicon-cms-cmsService-components"
---

# Content Archive

## Summary

A content editor explicitly archives a VALIDATED content path when it is no longer needed as the active live version. This operation transitions all content items under the specified path, locale, and brand from VALIDATED to ARCHIVED state. The content is then no longer returned by default queries using `status=VALIDATED`. Archiving requires the content to currently be in VALIDATED state; drafts cannot be directly archived via this endpoint.

## Trigger

- **Type**: api-call
- **Source**: Content editor or CMS tooling
- **Frequency**: On demand when a VALIDATED content path is being retired

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Content editor / tooling | Initiates the archive request | External caller |
| `TroniconCmsResource` | Receives and routes the HTTP POST request | `troniconCmsService` |
| `CMSService` | Executes the archive state transition | `troniconCmsService` |
| `CMSContentDao` | Reads VALIDATED content and updates status to ARCHIVED | `troniconCmsService` |
| `CMSContentAuditLogDao` | Writes audit log entries for the archive transitions | `troniconCmsService` |
| MySQL Database | Persists the status changes | `continuumTroniconCmsDatabase` |

## Steps

1. **Receives archive request**: Editor sends `POST /cms/archive/path/{path}?locale=<locale>&brand=<brand>`
   - From: Content editor
   - To: `TroniconCmsResource`
   - Protocol: REST

2. **Routes to service layer**: `TroniconCmsResource` delegates to `CMSService`
   - From: `TroniconCmsResource`
   - To: `CMSService`
   - Protocol: Direct (in-process)

3. **Locates VALIDATED content**: `CMSService` calls `CMSContentDao` to fetch all content items in VALIDATED state for the given path, locale, and brand
   - From: `CMSService` via `CMSContentDao`
   - To: `continuumTroniconCmsDatabase`
   - Protocol: JDBI/MySQL

4. **Updates status to ARCHIVED**: `CMSService` calls `CMSContentDao` to update all located VALIDATED items to ARCHIVED status
   - From: `CMSService` via `CMSContentDao`
   - To: `continuumTroniconCmsDatabase`
   - Protocol: JDBI/MySQL

5. **Writes audit log**: `CMSService` records audit log entries capturing the VALIDATED → ARCHIVED transition
   - From: `CMSService` via `CMSContentAuditLogDao`
   - To: `continuumTroniconCmsDatabase`
   - Protocol: JDBI/MySQL

6. **Returns archived content**: HTTP 200 with the now-ARCHIVED `CMSContent` array
   - From: `TroniconCmsResource`
   - To: Content editor
   - Protocol: REST (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No VALIDATED content found for path/locale/brand | Not found error | HTTP 404 |
| Locale parameter missing or invalid | Validation rejection | HTTP 400 |
| Brand parameter missing | Validation rejection | HTTP 400 |
| Database write failure | Exception propagated | HTTP 500 |

## Sequence Diagram

```
Editor -> TroniconCmsResource: POST /cms/archive/path/{path}?locale=en_US&brand=groupon
TroniconCmsResource -> CMSService: archiveCMSContent(path, locale, brand)
CMSService -> CMSContentDao: findByPathLocaleBrandAndStatus(path, locale, brand, VALIDATED)
CMSContentDao -> MySQL: SELECT where status='VALIDATED'
MySQL --> CMSContentDao: [VALIDATED content rows]
CMSService -> CMSContentDao: updateStatus(content, ARCHIVED)
CMSContentDao -> MySQL: UPDATE SET status='ARCHIVED'
CMSService -> CMSContentAuditLogDao: writeAuditLog(VALIDATED -> ARCHIVED)
CMSContentAuditLogDao -> MySQL: INSERT audit_log
CMSService --> TroniconCmsResource: List<CMSContent> (ARCHIVED)
TroniconCmsResource --> Editor: HTTP 200 [CMSContent[]]
```

## Related

- Architecture dynamic view: `tronicon-cms-cmsService-components`
- Related flows: [Content Publish Lifecycle](content-publish-lifecycle.md), [Content Authoring and Draft Creation](content-authoring-draft-creation.md)
