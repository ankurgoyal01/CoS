---
service: "seo-admin-ui"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [seoAdminUiItier]
---

# Architecture Context

## System Context

seo-admin-ui sits within the **Continuum** platform as an internal admin web application. SEO engineers and content operators access it via browser. It connects outward to Google Search Console for indexing data, and inward to multiple Continuum services (LPAPI, SEO Deal API, MECS, SEO Checkoff Service, Keyword KB API, Deal Catalog) to coordinate SEO workflows. The service does not expose a public API; all access is internal and requires I-Tier session authentication.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| SEO Admin UI (I-Tier app) | `seoAdminUiItier` | WebApp | Node.js / I-Tier | 7.9.3 | Server-side rendered admin console with Preact frontend; handles all SEO admin operations |

## Components by Container

### SEO Admin UI (`seoAdminUiItier`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Landing Page Route Manager | CRUD for landing page routes via LPAPI | Preact + @grpn/lpapi-client |
| Canonical Update Handler | Submits and tracks canonical URL updates | Preact + REST |
| SEO Deal Manager | Manages SEO deal attributes and page generation | Preact + seo-deal-page + GraphQL |
| URL Removal Request Handler | Submits URL removal requests for de-indexing | Preact + REST |
| Auto-Index Worker | Orchestrates automated page indexing jobs | Node.js scheduled worker |
| Page Route Auditor | Audits page routes against live routing table | Node.js + REST |
| Crosslinks Analyzer | Visualises page crosslink graph from Neo4j | Preact + D3 + @grpn/neo4j-seo |
| Auth Layer | Enforces I-Tier session-based authentication | itier-user-auth 8.1.0 |
| Feature Flag Evaluator | Controls rollout of admin features at runtime | itier-feature-flags 3.1.2 |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `seoAdminUiItier` | LPAPI | Reads and writes landing page routes | REST / HTTP |
| `seoAdminUiItier` | Deal Catalog (GAPI) | Queries deal data for SEO deal management | GraphQL / HTTP |
| `seoAdminUiItier` | SEO Deal API | Manages SEO deal page attributes | REST / HTTP |
| `seoAdminUiItier` | MECS | Reads content data for SEO tasks | REST / HTTP |
| `seoAdminUiItier` | SEO Checkoff Service | Submits and tracks SEO task checkoffs | REST / HTTP |
| `seoAdminUiItier` | Keyword KB API | Queries keyword knowledge base | REST / HTTP |
| `seoAdminUiItier` | Google Search Console API | Retrieves indexing and coverage data | REST / HTTP (OAuth) |
| `seoAdminUiItier` | Neo4j (SEO) | Reads page ranking and crosslink graph data | Bolt / @grpn/neo4j-seo |
| `seoAdminUiItier` | Memcached | Caches session data and API responses | Memcached protocol |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-seoAdminUiItier`
