---
service: "tronicon-cms"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Tronicon CMS.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Content Retrieval by Path](content-retrieval-by-path.md) | synchronous | API call from consumer service | Consumer requests validated CMS content for a given path, locale, and brand |
| [Content Authoring and Draft Creation](content-authoring-draft-creation.md) | synchronous | API call from content editor | Editor creates or updates CMS content in DRAFT state via upsert or clone |
| [Content Publish Lifecycle](content-publish-lifecycle.md) | synchronous | API call from content editor | Editor promotes a DRAFT to VALIDATED, demoting the previous VALIDATED to ARCHIVED |
| [Content Archive](content-archive.md) | synchronous | API call from content editor | Editor explicitly archives a VALIDATED content path |
| [Usability Stats Recording](usability-stats-recording.md) | synchronous | API call from analytics consumer | Consumer saves script and warning counts for a content item |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

Tronicon CMS does not participate in cross-service async flows. All interactions are synchronous HTTP. Upstream consumers (legal page renderers) call the CMS API directly to retrieve validated content. These consumer interactions are tracked in the central architecture model for the Continuum platform.
