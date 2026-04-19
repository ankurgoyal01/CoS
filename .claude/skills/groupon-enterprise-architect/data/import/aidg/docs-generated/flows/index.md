---
service: "aidg"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 2
---

# Flows

Process and flow documentation for AIDG (AI-Driven Deal Generation).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [PDS Inference Enrichment](pds-inference-enrichment.md) | synchronous | API call to InferPDS API | Enriches product data by running AI-driven PDS inference models and returning enrichment results to the caller |
| [Merchant Quality Scoring](merchant-quality-scoring.md) | synchronous | API call to Merchant Quality API | Computes and returns a merchant quality score based on AI-driven evaluation of merchant data |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

> No cross-service flows are documented in the architecture DSL. Dynamic views (`dynamics.dsl`) are empty. Cross-service flow documentation will be added when relationships and dynamic scenarios are modeled in the DSL or when source code is federated.
