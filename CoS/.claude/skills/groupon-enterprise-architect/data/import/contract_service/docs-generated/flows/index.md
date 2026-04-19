---
service: "contract_service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Contract Service (Cicero).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Contract Definition Upload](contract-definition-upload.md) | synchronous | API call from merchant-self-service-engine | Uploads and versions a new contract definition (schema + templates) into the service |
| [Contract Creation](contract-creation.md) | synchronous | API call from merchant-self-service-engine | Creates a new contract instance from a definition, validates merchant data against schema |
| [Contract Rendering](contract-rendering.md) | synchronous | API call (GET contract in HTML/PDF/TXT format) | Renders a stored contract using its XSLT template into a formatted output document |
| [Contract Signing](contract-signing.md) | synchronous | API call from merchant-self-service-engine | Records a merchant's electronic or acceptance signature against a contract |
| [Contract Update and Versioning](contract-update-versioning.md) | synchronous | API call (PUT contract) | Updates contract user data and automatically snapshots a new version record |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All flows originate from `continuumMerchantSelfService` (merchant self-service engine) calling `continuumContractService` over REST HTTP. The Contract Service then interacts with `continuumContractMysql` (MySQL via DaaS) synchronously as part of each request. No dynamic views are currently modeled in the architecture DSL for this service (`views/dynamics.dsl` is empty).

See [Architecture Context](../architecture-context.md) for container relationship references.
