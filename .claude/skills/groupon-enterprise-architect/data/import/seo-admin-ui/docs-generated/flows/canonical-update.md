---
service: "seo-admin-ui"
title: "Canonical Update"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "canonical-update"
flow_type: synchronous
trigger: "Operator submits a canonical URL update task for a Groupon page"
participants:
  - "seoAdminUiItier"
  - "SEO Checkoff Service"
architecture_ref: "dynamic-seoAdminUiItier"
---

# Canonical Update

## Summary

This flow allows SEO engineers to submit canonical URL update tasks for Groupon pages. When a page's canonical URL needs to change — for example, after a URL restructure or redirect chain cleanup — an operator submits the update through the admin UI. The request is tracked as an SEO task and passed to the SEO Checkoff Service for status tracking and workflow coordination.

## Trigger

- **Type**: user-action
- **Source**: SEO engineer submits a canonical update form in the seo-admin-ui admin console
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SEO Admin UI | Receives operator request; validates canonical URL; submits task | `seoAdminUiItier` |
| SEO Checkoff Service | Accepts the canonical update task; tracks its completion status | > No Structurizr ID in inventory. |

## Steps

1. **Receive canonical update request**: Operator enters the target page URL and the new canonical URL in the admin console and submits.
   - From: `Operator browser`
   - To: `seoAdminUiItier`
   - Protocol: REST / HTTP (I-Tier session authenticated)

2. **Validate URLs**: seo-admin-ui validates that both the page URL and the canonical URL are well-formed.
   - From: `seoAdminUiItier`
   - To: `seoAdminUiItier` (internal)
   - Protocol: direct

3. **Submit canonical update task**: seo-admin-ui posts the canonical update task to the SEO Checkoff Service.
   - From: `seoAdminUiItier`
   - To: `SEO Checkoff Service`
   - Protocol: REST / HTTP

4. **Receive task acknowledgement**: SEO Checkoff Service returns a task ID and initial status.
   - From: `SEO Checkoff Service`
   - To: `seoAdminUiItier`
   - Protocol: REST / HTTP

5. **Confirm to operator**: seo-admin-ui displays the task ID and status to the operator.
   - From: `seoAdminUiItier`
   - To: `Operator browser`
   - Protocol: HTTP / HTML or JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid URL format | Surface validation error to operator | Operator corrects and resubmits |
| SEO Checkoff Service unavailable | Log error; display error message | Operator retries; task not created |
| SEO Checkoff Service returns 4xx | Surface specific error message | Operator reviews task data and resubmits |

## Sequence Diagram

```
Operator -> seoAdminUiItier: Submit canonical update (page URL + canonical URL)
seoAdminUiItier -> seoAdminUiItier: Validate URLs
seoAdminUiItier -> SEOCheckoffService: POST canonical update task
SEOCheckoffService --> seoAdminUiItier: 201 Created (task ID, status)
seoAdminUiItier --> Operator: Display task confirmation
```

## Related

- Architecture dynamic view: `dynamic-seoAdminUiItier`
- Related flows: [URL Removal Request](url-removal-request.md), [Page Route Auditing](page-route-auditing.md)
