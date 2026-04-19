---
service: "seo-admin-ui"
title: "Auto-Index Worker"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "auto-index-worker"
flow_type: scheduled
trigger: "Scheduled job or manual operator trigger submits pages for Google indexing"
participants:
  - "seoAdminUiItier"
  - "Google Search Console API"
  - "LPAPI"
architecture_ref: "dynamic-seoAdminUiItier"
---

# Auto-Index Worker

## Summary

The auto-index worker is a background process within seo-admin-ui that automatically submits Groupon pages for indexing to Google Search Console. It runs on a schedule (or can be manually triggered by an operator) and targets pages that are new, recently updated, or have not been indexed within a configured window. The worker fetches the list of candidate pages from LPAPI and submits them to Google Search Console via the URL Inspection API.

## Trigger

- **Type**: schedule / manual
- **Source**: Internal scheduled job within seo-admin-ui; can also be manually triggered via `POST /auto-index/trigger` by an authenticated operator
- **Frequency**: Scheduled (specific interval not confirmed in inventory); on-demand via manual trigger

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SEO Admin UI (auto-index worker) | Orchestrates the indexing run; fetches pages; submits to Google | `seoAdminUiItier` |
| LPAPI | Provides the list of landing page routes to be indexed | > No Structurizr ID in inventory. |
| Google Search Console API | Accepts URL indexing submission requests | > No Structurizr ID in inventory. |

## Steps

1. **Trigger worker run**: The scheduled job fires, or an operator submits a manual trigger request.
   - From: `Scheduler / Operator browser`
   - To: `seoAdminUiItier`
   - Protocol: internal schedule / REST / HTTP

2. **Fetch candidate pages**: seo-admin-ui queries LPAPI for the list of active landing page routes that are candidates for indexing.
   - From: `seoAdminUiItier`
   - To: `LPAPI`
   - Protocol: REST / HTTP via `@grpn/lpapi-client`

3. **Filter pages**: seo-admin-ui applies eligibility criteria (new pages, recently updated, or past indexing window).
   - From: `seoAdminUiItier`
   - To: `seoAdminUiItier` (internal)
   - Protocol: direct

4. **Authenticate with Google**: seo-admin-ui obtains or refreshes the OAuth 2.0 access token for Google Search Console.
   - From: `seoAdminUiItier`
   - To: `Google OAuth 2.0 endpoint`
   - Protocol: REST / HTTPS

5. **Submit pages for indexing**: For each eligible page, seo-admin-ui calls the Google Search Console URL Inspection / Indexing API.
   - From: `seoAdminUiItier`
   - To: `Google Search Console API`
   - Protocol: REST / HTTPS (OAuth 2.0 Bearer token)

6. **Log indexing results**: seo-admin-ui records the submission results (success/failure per URL) for operator review.
   - From: `seoAdminUiItier`
   - To: `seoAdminUiItier` (internal logs)
   - Protocol: direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| LPAPI unavailable | Log error; abort worker run | No pages submitted; worker retries on next schedule |
| OAuth token refresh fails | Log error; abort worker run | No pages submitted; operator should verify credentials |
| Google API rate limit hit | Honour Retry-After header; back off | Partial indexing submission; remaining pages deferred to next run |
| Google API returns error for a URL | Log per-URL error; continue with remaining URLs | Partial run; failed URLs visible in worker logs |

## Sequence Diagram

```
Scheduler -> seoAdminUiItier: Trigger auto-index worker run
seoAdminUiItier -> LPAPI: GET active landing page routes
LPAPI --> seoAdminUiItier: List of page routes
seoAdminUiItier -> seoAdminUiItier: Filter eligible pages
seoAdminUiItier -> GoogleOAuth: Obtain/refresh OAuth 2.0 token
GoogleOAuth --> seoAdminUiItier: Access token
loop for each eligible page
  seoAdminUiItier -> GoogleSearchConsoleAPI: POST URL indexing request
  GoogleSearchConsoleAPI --> seoAdminUiItier: 200 OK / error
end
seoAdminUiItier -> seoAdminUiItier: Log results
```

## Related

- Architecture dynamic view: `dynamic-seoAdminUiItier`
- Related flows: [URL Removal Request](url-removal-request.md), [Landing Page Route CRUD](landing-page-route-crud.md), [Page Route Auditing](page-route-auditing.md)
