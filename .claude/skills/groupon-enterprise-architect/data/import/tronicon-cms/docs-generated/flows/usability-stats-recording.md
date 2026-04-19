---
service: "tronicon-cms"
title: "Usability Stats Recording"
generated: "2026-03-03"
type: flow
flow_name: "usability-stats-recording"
flow_type: synchronous
trigger: "API call from an analytics or content quality consumer saving usability metrics for a content item"
participants:
  - "troniconCmsService"
  - "continuumTroniconCmsDatabase"
architecture_ref: "tronicon-cms-cmsService-components"
---

# Usability Stats Recording

## Summary

A consumer (such as an analytics pipeline or content quality tool) records usability metrics for a specific CMS content item. The metrics tracked are `scriptCount` (number of script tags in the content) and `contentWarningCount` (number of content quality warnings detected). The service upserts these statistics — creating a new record if none exists, or updating the existing record for the given `cmsContentId`. Statistics can later be retrieved paired with the content item itself via the show-stats endpoint.

## Trigger

- **Type**: api-call
- **Source**: Analytics pipeline or content quality tooling
- **Frequency**: On demand when content is analyzed (typically after content creation or update)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Analytics / quality tool | Initiates the stats save request | External caller |
| `TroniconCmsStatsResource` | Receives and routes the HTTP POST request | `troniconCmsService` |
| `CMSUsabilityStatsService` | Coordinates usability stats upsert logic | `troniconCmsService` |
| `CMSUsabilityStatsDao` | Persists or updates statistics records | `troniconCmsService` |
| MySQL Database | Stores usability statistics | `continuumTroniconCmsDatabase` |

## Steps

1. **Receives stats save request**: Consumer sends `POST /cms-stats/save` with a JSON array of `CMSUsabilityStats` objects, each containing `cmsContentId`, `scriptCount`, and `contentWarningCount`
   - From: Analytics / quality tool
   - To: `TroniconCmsStatsResource`
   - Protocol: REST (JSON body)

2. **Routes to service layer**: `TroniconCmsStatsResource` delegates to `CMSUsabilityStatsService`
   - From: `TroniconCmsStatsResource`
   - To: `CMSUsabilityStatsService`
   - Protocol: Direct (in-process)

3. **Validates ID presence**: `CMSUsabilityStatsService` verifies that `cmsContentId` is not null; throws error if absent
   - From: `CMSUsabilityStatsService`
   - To: Internal validation
   - Protocol: Direct (in-process)

4. **Upserts statistics**: `CMSUsabilityStatsService` calls `CMSUsabilityStatsDao` to insert a new stats record or update the existing one for the given `cmsContentId`
   - From: `CMSUsabilityStatsService` via `CMSUsabilityStatsDao`
   - To: `continuumTroniconCmsDatabase`
   - Protocol: JDBI/MySQL

5. **Returns saved statistics**: HTTP 200 with the persisted `CMSUsabilityStats` object(s)
   - From: `TroniconCmsStatsResource`
   - To: Analytics / quality tool
   - Protocol: REST (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `cmsContentId` is null | Validation rejection | HTTP 400 ("CMS Content ID cannot be null") |
| Referenced `cmsContentId` does not exist | Database constraint / not found | HTTP 404 |
| Database write failure | Exception propagated | HTTP 500 |

## Sequence Diagram

```
Analytics tool -> TroniconCmsStatsResource: POST /cms-stats/save [CMSUsabilityStats[]]
TroniconCmsStatsResource -> CMSUsabilityStatsService: saveStats(List<CMSUsabilityStats>)
CMSUsabilityStatsService -> CMSUsabilityStatsService: validate(cmsContentId != null)
CMSUsabilityStatsService -> CMSUsabilityStatsDao: upsert(stats)
CMSUsabilityStatsDao -> MySQL: INSERT/UPDATE cms_usability_stats
MySQL --> CMSUsabilityStatsDao: saved record
CMSUsabilityStatsService --> TroniconCmsStatsResource: CMSUsabilityStats
TroniconCmsStatsResource --> Analytics tool: HTTP 200 [CMSUsabilityStats]
```

## Related

- Architecture dynamic view: `tronicon-cms-cmsService-components`
- Related flows: [Content Retrieval by Path](content-retrieval-by-path.md)
- Stats retrieval: `GET /cms-stats/id/{cms_content_id}` and `GET /cms-stats/show-stats/id/{cms_content_id}`
