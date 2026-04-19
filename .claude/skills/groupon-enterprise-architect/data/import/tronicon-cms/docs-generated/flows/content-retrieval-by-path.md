---
service: "tronicon-cms"
title: "Content Retrieval by Path"
generated: "2026-03-03"
type: flow
flow_name: "content-retrieval-by-path"
flow_type: synchronous
trigger: "API call from downstream consumer (frontend or service) requesting live content"
participants:
  - "troniconCmsService"
  - "continuumTroniconCmsDatabase"
architecture_ref: "tronicon-cms-cmsService-components"
---

# Content Retrieval by Path

## Summary

A downstream consumer (such as a frontend renderer serving legal pages) calls the Tronicon CMS API to retrieve the current live content for a given path, locale, and brand. The service queries its MySQL database for content in VALIDATED state and returns the matching content items. This is the primary read path for legal page content served to end users.

## Trigger

- **Type**: api-call
- **Source**: Downstream consumer service or frontend (e.g., legal page renderer)
- **Frequency**: On demand per page request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer service / frontend | Initiates HTTP GET request | External caller |
| `TroniconCmsResource` | Receives and routes the HTTP request | `troniconCmsService` |
| `CMSService` | Executes content lookup business logic | `troniconCmsService` |
| `CMSContentDao` | Queries MySQL for matching content records | `troniconCmsService` |
| MySQL Database | Stores and returns VALIDATED content records | `continuumTroniconCmsDatabase` |

## Steps

1. **Receives content request**: Consumer sends `GET /cms/path/{path}?locale=<locale>&status=VALIDATED` with `X-Brand` header
   - From: Consumer service
   - To: `TroniconCmsResource`
   - Protocol: REST

2. **Routes request to service layer**: `TroniconCmsResource` delegates to `CMSService`
   - From: `TroniconCmsResource`
   - To: `CMSService`
   - Protocol: Direct (in-process)

3. **Queries database for validated content**: `CMSService` calls `CMSContentDao` to fetch all content items matching path, locale, brand, and status=VALIDATED
   - From: `CMSService` via `CMSContentDao`
   - To: `continuumTroniconCmsDatabase`
   - Protocol: JDBI/MySQL

4. **Returns content records**: Database returns matching content rows; `CMSContentDao` maps results to `CMSContent` domain objects
   - From: `continuumTroniconCmsDatabase`
   - To: `CMSContentDao`
   - Protocol: JDBI/MySQL

5. **Returns HTTP response**: `TroniconCmsResource` serializes the content list to JSON and returns HTTP 200
   - From: `TroniconCmsResource`
   - To: Consumer service
   - Protocol: REST (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Path not found or no VALIDATED content | Returns empty list | HTTP 200 with empty array |
| Invalid locale (< 5 characters) | Request validation rejection | HTTP 400 |
| Missing required X-Brand header | Request validation rejection | HTTP 400 |
| Database connectivity failure | Exception propagated | HTTP 500 |

## Sequence Diagram

```
Consumer -> TroniconCmsResource: GET /cms/path/{path}?locale=en_US&status=VALIDATED [X-Brand: groupon]
TroniconCmsResource -> CMSService: findContentByPath(path, locale, brand, status)
CMSService -> CMSContentDao: query(path, locale, brand, VALIDATED)
CMSContentDao -> MySQL: SELECT * FROM cms_content WHERE path=? AND locale=? AND brand=? AND status='VALIDATED'
MySQL --> CMSContentDao: [CMSContent rows]
CMSContentDao --> CMSService: List<CMSContent>
CMSService --> TroniconCmsResource: List<CMSContent>
TroniconCmsResource --> Consumer: HTTP 200 [CMSContent[]]
```

## Related

- Architecture dynamic view: `tronicon-cms-cmsService-components`
- Related flows: [Content Publish Lifecycle](content-publish-lifecycle.md), [Content Authoring and Draft Creation](content-authoring-draft-creation.md)
