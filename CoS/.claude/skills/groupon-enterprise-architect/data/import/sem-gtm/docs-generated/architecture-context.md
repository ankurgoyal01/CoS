---
service: "sem-gtm"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumSemGtmPreviewServer, continuumSemGtmTaggingServer]
---

# Architecture Context

## System Context

`sem-gtm` sits within the `continuumSystem` (Continuum Platform) as Groupon's server-side Google Tag Manager infrastructure. It operates as two distinct Kubernetes deployments inside the `sem-gtm-production` and `sem-gtm-staging` namespaces on GCP. Web clients and Groupon applications forward tag payloads to the tagging server, which processes them via Google's GTM Cloud runtime. Tag engineers interact with the preview server from the GTM UI to debug configurations before promoting changes to production. Both containers integrate outbound with the Google Tag Manager API, which is external to Groupon's federated architecture model.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| GTM Preview Server | `continuumSemGtmPreviewServer` | API service | gtm-cloud-image (GCP) | stable | GTM preview server deployment used to validate and debug tag configurations |
| GTM Tagging Server | `continuumSemGtmTaggingServer` | API service | gtm-cloud-image (GCP) | stable | GTM tagging server deployment used to serve production tag management requests |

## Components by Container

### GTM Preview Server (`continuumSemGtmPreviewServer`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Preview HTTP Server | Accepts debug/preview requests from GTM UI on port 8080; validates tag configurations | gtm-cloud-image |
| Health Probe Endpoint | Responds to `/healthz` for Kubernetes liveness and readiness checks | gtm-cloud-image |

### GTM Tagging Server (`continuumSemGtmTaggingServer`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Tagging HTTP Server | Receives production tag events on port 8080; routes data to configured GTM tags and triggers | gtm-cloud-image |
| Health Probe Endpoint | Responds to `/healthz` for Kubernetes liveness and readiness checks | gtm-cloud-image |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumSemGtmPreviewServer` | `gtmApiUnknown_ab3a36` | Integrates with GTM Cloud for preview/tag debugging | HTTPS |
| `continuumSemGtmTaggingServer` | `gtmApiUnknown_ab3a36` | Integrates with GTM Cloud for production tagging | HTTPS |
| `continuumSemGtmTaggingServer` | `continuumSemGtmPreviewServer` | Tagging server references preview server URL for debug-mode routing | HTTPS (`PREVIEW_SERVER_URL`) |

> Note: `gtmApiUnknown_ab3a36` is an external stub — the Google Tag Manager Cloud API endpoint is outside Groupon's federated architecture model. Relationships are documented in `architecture/models/relations.dsl` as stub-only comments pending full cross-model federation.

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSemGtm`
- Component: `components-continuumSemGtm` (no component views defined — see `architecture/views/components.dsl`)
