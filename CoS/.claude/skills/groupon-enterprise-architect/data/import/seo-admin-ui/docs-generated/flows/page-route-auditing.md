---
service: "seo-admin-ui"
title: "Page Route Auditing"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "page-route-auditing"
flow_type: synchronous
trigger: "Operator initiates a page route audit from the admin UI"
participants:
  - "seoAdminUiItier"
  - "LPAPI"
  - "Google Search Console API"
architecture_ref: "dynamic-seoAdminUiItier"
---

# Page Route Auditing

## Summary

The page route auditing flow allows SEO engineers to verify the health and consistency of Groupon's landing page routes. The audit compares the expected routing configuration (from LPAPI) against live indexing and coverage data (from Google Search Console) to identify discrepancies such as pages that are configured but not indexed, or pages that are indexed but no longer active. Results are presented as an audit report in the admin UI.

## Trigger

- **Type**: user-action
- **Source**: SEO engineer clicks "Run Audit" in the page route audit section of the admin console
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SEO Admin UI | Orchestrates the audit; fetches routes and indexing data; produces report | `seoAdminUiItier` |
| LPAPI | Provides the expected set of active landing page routes | > No Structurizr ID in inventory. |
| Google Search Console API | Provides live indexing and coverage data for Groupon pages | > No Structurizr ID in inventory. |

## Steps

1. **Operator initiates audit**: Operator navigates to the route audit screen and submits the audit request.
   - From: `Operator browser`
   - To: `seoAdminUiItier`
   - Protocol: REST / HTTP (I-Tier session authenticated)

2. **Fetch expected routes**: seo-admin-ui queries LPAPI for the full list of active landing page routes.
   - From: `seoAdminUiItier`
   - To: `LPAPI`
   - Protocol: REST / HTTP via `@grpn/lpapi-client`

3. **Authenticate with Google**: seo-admin-ui obtains or refreshes the OAuth 2.0 access token for Google Search Console.
   - From: `seoAdminUiItier`
   - To: `Google OAuth 2.0 endpoint`
   - Protocol: REST / HTTPS

4. **Fetch indexing coverage**: seo-admin-ui queries Google Search Console API for coverage data on the Groupon property.
   - From: `seoAdminUiItier`
   - To: `Google Search Console API`
   - Protocol: REST / HTTPS (OAuth 2.0 Bearer token)

5. **Compute audit results**: seo-admin-ui compares the LPAPI route list against Google indexing data, flagging mismatches.
   - From: `seoAdminUiItier`
   - To: `seoAdminUiItier` (internal)
   - Protocol: direct

6. **Present audit report**: seo-admin-ui renders the audit report listing matching, missing, and unexpected routes.
   - From: `seoAdminUiItier`
   - To: `Operator browser`
   - Protocol: HTTP / HTML

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| LPAPI unavailable | Log error; display error message | Audit cannot complete; operator retries |
| Google Search Console API unavailable | Log error; display error message | Audit cannot complete; operator retries |
| OAuth token refresh fails | Log error; abort audit | Operator verifies credentials and retries |
| Partial Google API data | Warn operator in report | Audit completes with partial data; gaps flagged |

## Sequence Diagram

```
Operator -> seoAdminUiItier: Initiate page route audit
seoAdminUiItier -> LPAPI: GET all active landing page routes
LPAPI --> seoAdminUiItier: Route list
seoAdminUiItier -> GoogleOAuth: Obtain/refresh OAuth 2.0 token
GoogleOAuth --> seoAdminUiItier: Access token
seoAdminUiItier -> GoogleSearchConsoleAPI: GET indexing coverage data
GoogleSearchConsoleAPI --> seoAdminUiItier: Coverage report
seoAdminUiItier -> seoAdminUiItier: Compute discrepancies
seoAdminUiItier --> Operator: Render audit report
```

## Related

- Architecture dynamic view: `dynamic-seoAdminUiItier`
- Related flows: [Auto-Index Worker](auto-index-worker.md), [Landing Page Route CRUD](landing-page-route-crud.md), [Canonical Update](canonical-update.md)
