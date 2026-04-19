---
service: "seo-admin-ui"
title: "URL Removal Request"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "url-removal-request"
flow_type: synchronous
trigger: "Operator submits a URL removal request for de-indexing a page from Google"
participants:
  - "seoAdminUiItier"
  - "Google Search Console API"
architecture_ref: "dynamic-seoAdminUiItier"
---

# URL Removal Request

## Summary

This flow allows SEO engineers to submit URL removal requests for pages that need to be de-indexed from Google Search. Common triggers include discontinued deals, duplicate content pages, or pages that have been redirected. The admin UI validates the target URL and submits the removal request directly to the Google Search Console API using OAuth 2.0 service account credentials.

## Trigger

- **Type**: user-action
- **Source**: SEO engineer submits a URL removal request in the seo-admin-ui admin console
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SEO Admin UI | Receives operator request; validates URL; submits to Google Search Console | `seoAdminUiItier` |
| Google Search Console API | Accepts the removal request and queues it for processing | > No Structurizr ID in inventory. |

## Steps

1. **Receive removal request**: Operator enters the URL to be removed and submits the form.
   - From: `Operator browser`
   - To: `seoAdminUiItier`
   - Protocol: REST / HTTP (I-Tier session authenticated)

2. **Validate URL**: seo-admin-ui validates that the URL belongs to a known Groupon domain and is well-formed.
   - From: `seoAdminUiItier`
   - To: `seoAdminUiItier` (internal)
   - Protocol: direct

3. **Authenticate with Google**: seo-admin-ui obtains or refreshes the OAuth 2.0 access token for the Google Search Console service account.
   - From: `seoAdminUiItier`
   - To: `Google OAuth 2.0 endpoint`
   - Protocol: REST / HTTPS

4. **Submit removal request**: seo-admin-ui calls the Google Search Console API to submit the URL removal request.
   - From: `seoAdminUiItier`
   - To: `Google Search Console API`
   - Protocol: REST / HTTPS (OAuth 2.0 Bearer token)

5. **Record removal request**: seo-admin-ui logs the submitted removal request with its status for operator tracking.
   - From: `seoAdminUiItier`
   - To: `seoAdminUiItier` (internal log / session)
   - Protocol: direct

6. **Confirm to operator**: seo-admin-ui displays the submission status and request ID to the operator.
   - From: `seoAdminUiItier`
   - To: `Operator browser`
   - Protocol: HTTP / HTML

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid or non-Groupon URL | Surface validation error | Operator corrects URL and resubmits |
| OAuth token refresh fails | Log error; display auth error message | Operator retries after credentials are verified |
| Google Search Console API returns 4xx | Surface specific error from API | Operator reviews request and resubmits |
| Google Search Console API unavailable | Log error; display error message | Request not submitted; operator retries |

## Sequence Diagram

```
Operator -> seoAdminUiItier: Submit URL removal request
seoAdminUiItier -> seoAdminUiItier: Validate URL
seoAdminUiItier -> GoogleOAuth: Obtain/refresh OAuth 2.0 access token
GoogleOAuth --> seoAdminUiItier: Access token
seoAdminUiItier -> GoogleSearchConsoleAPI: POST URL removal request
GoogleSearchConsoleAPI --> seoAdminUiItier: 200 OK (request ID, status)
seoAdminUiItier --> Operator: Display confirmation with request ID
```

## Related

- Architecture dynamic view: `dynamic-seoAdminUiItier`
- Related flows: [Canonical Update](canonical-update.md), [Auto-Index Worker](auto-index-worker.md)
