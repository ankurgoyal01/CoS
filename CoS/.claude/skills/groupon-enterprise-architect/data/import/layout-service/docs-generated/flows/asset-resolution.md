---
service: "layout-service"
title: "Asset Resolution Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "asset-resolution"
flow_type: synchronous
trigger: "Template rendering requires CDN-backed static asset URLs for header/footer resources"
participants:
  - "layoutSvc_assetResolver"
  - "layoutSvc_templateRenderer"
architecture_ref: "components-continuum-layout-service"
---

# Asset Resolution Flow

## Summary

Before rendering a Mustache template, Layout Service must resolve CDN-backed URLs for all static assets (JavaScript bundles, stylesheets, images, brand icons) referenced in header and footer templates. The Asset Resolver component provides these URLs and associated metadata to the Template Renderer, ensuring that all asset references in the rendered page chrome point to the correct CDN origin for the current deployment, environment, and brand.

## Trigger

- **Type**: api-call (sub-flow triggered internally during layout request processing, before template rendering)
- **Source**: `layoutSvc_templateRenderer` — requires resolved asset URLs before it can apply context to the template
- **Frequency**: Per layout request (or per unique context, if asset resolution results are memoized in-process)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Asset Resolver | Provider — resolves CDN-backed static asset URLs and brand-specific resource metadata | `layoutSvc_assetResolver` |
| Template Renderer | Consumer — receives resolved asset URLs and injects them into the Mustache rendering context | `layoutSvc_templateRenderer` |

## Steps

1. **Requests asset metadata**: Template Renderer invokes Asset Resolver to obtain CDN-backed URLs for the asset manifest entries required by the current layout template.
   - From: `layoutSvc_templateRenderer`
   - To: `layoutSvc_assetResolver`
   - Protocol: direct (in-process)

2. **Reads asset manifest**: Asset Resolver reads the deployed asset manifest (a static file bundled with the service artifact or injected via environment configuration) to identify asset filenames, content hashes, and CDN base paths.
   - From: `layoutSvc_assetResolver`
   - To: Local asset manifest (deployed artifact)
   - Protocol: direct (in-process file read)

3. **Constructs CDN URLs**: Asset Resolver prepends the configured `CDN_BASE_URL` to each asset path, incorporating content hashes or versioned filenames to produce cache-busting CDN URLs.
   - From: `layoutSvc_assetResolver`
   - To: `layoutSvc_assetResolver` (internal URL construction)
   - Protocol: direct

4. **Returns resolved asset URLs and metadata**: Asset Resolver returns the map of asset names to CDN URLs to Template Renderer.
   - From: `layoutSvc_assetResolver`
   - To: `layoutSvc_templateRenderer`
   - Protocol: direct (in-process)

5. **Injects asset URLs into rendering context**: Template Renderer merges the resolved asset URLs into the full rendering context alongside locale, market, and user data, making them available as Mustache template variables.
   - From: `layoutSvc_templateRenderer`
   - To: `layoutSvc_templateRenderer` (internal context assembly)
   - Protocol: direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Asset manifest file missing or unreadable | Asset Resolver returns empty/fallback metadata; error logged | Template rendered without asset URLs; browser fails to load static assets; layout chrome structure is intact |
| `CDN_BASE_URL` not configured | Asset Resolver cannot construct URLs; falls back to relative paths or empty strings | Assets may not load in browser; layout HTML structure is returned |
| Unknown asset key requested | Asset Resolver returns nil for unknown keys; Template Renderer handles missing variable as empty string in Mustache | Template renders with empty asset reference for that resource |

## Sequence Diagram

```
layoutSvc_templateRenderer -> layoutSvc_assetResolver:    Request asset URLs for layout template
layoutSvc_assetResolver    -> layoutSvc_assetResolver:    Read deployed asset manifest
layoutSvc_assetResolver    -> layoutSvc_assetResolver:    Construct CDN URLs (CDN_BASE_URL + asset path)
layoutSvc_assetResolver    --> layoutSvc_templateRenderer: Resolved asset URL map
layoutSvc_templateRenderer -> layoutSvc_templateRenderer: Merge asset URLs into rendering context
```

## Related

- Architecture dynamic view: `dynamic-layout-service-request-flow`
- Related flows: [Layout Request Flow](layout-request-flow.md), [Context Composition Flow](context-composition.md)
