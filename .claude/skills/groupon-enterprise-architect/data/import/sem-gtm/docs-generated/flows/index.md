---
service: "sem-gtm"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for GTM Server Side (sem-gtm).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Tag Event Processing](tag-event-processing.md) | synchronous | HTTP request from web/app client | Web or app client sends a tag payload to the tagging server; GTM runtime processes and forwards to tag destinations |
| [Preview Session Debugging](preview-session-debugging.md) | synchronous | Tag engineer initiates debug session in GTM UI | GTM UI opens a preview/debug session against the preview server to validate tag configuration before production rollout |
| [Container Startup and Configuration Load](container-startup.md) | scheduled | Kubernetes pod start (deployment rollout or restart) | GTM container starts up, authenticates with GTM Cloud API using CONTAINER_CONFIG, loads workspace configuration, and begins serving traffic |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The tagging server flow involves an outbound HTTPS call to the external Google Tag Manager Cloud API (`gtmApiUnknown_ab3a36`), which is outside Groupon's federated architecture model. The tagging server also references the preview server (`continuumSemGtmPreviewServer`) via `PREVIEW_SERVER_URL` when routing debug sessions. Both cross-service relationships are noted as stub-only in the central architecture DSL pending full cross-model federation.
