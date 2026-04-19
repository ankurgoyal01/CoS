---
service: "regulatory-consent-log"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for the Regulatory Consent Log service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Consent Creation](consent-creation.md) | synchronous | `POST /v1/consents` from consumer-facing service | Records user consent(s) to Postgres and queues MBus outbox messages |
| [Consent Retrieval](consent-retrieval.md) | synchronous | `GET /v1/consents` from consumer or admin service | Looks up existing consent records by user identifier |
| [User Erasure Pipeline](user-erasure-pipeline.md) | asynchronous / event-driven | MBus user erasure event published by Users Service | Processes the full b-cookie erasure lifecycle: MBus → Redis → Janus → Postgres → MBus |
| [Cookie Validation](cookie-validation.md) | synchronous | `GET /v1/cookie` from API-Lazlo or API-Torii | Returns erased-user info for a given b-cookie UUID |
| [Transcend Webhook and Access Upload](transcend-webhook.md) | asynchronous / event-driven | Inbound Transcend webhook `POST` + scheduled Quartz jobs | Receives GDPR access/erasure requests from Transcend; uploads data to Lazlo/Transcend APIs |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- The [User Erasure Pipeline](user-erasure-pipeline.md) spans the Users Service, Message Bus, Janus Aggregator Service, and both RCL containers (`continuumRegulatoryConsentLogApi` and `continuumRegulatoryConsentLogWorker`).
- The [Transcend Webhook and Access Upload](transcend-webhook.md) flow spans Transcend Privacy Platform, LivingSocial Transcend API, Lazlo API, and LivingSocial Lazlo API.
- The [Consent Creation](consent-creation.md) flow involves upstream consumer services (Registration, Checkout, Subscription Modal) routing through API-Lazlo to the RCL API.
