---
service: "contract_service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumContractService"
  containers: [continuumContractService, continuumContractMysql]
---

# Architecture Context

## System Context

Contract Service (Cicero) is a backend API service in the **Continuum** platform within the Deal Management domain. It sits between the merchant self-service engine and the MySQL data store, acting as the authoritative system for merchant contract templates and signed contract records. The merchant self-service engine calls Contract Service to manage contract definitions and generate contracts during deal creation. The Deal Builder tool also depends on this service for contract workflows, though it is not currently present in the federated architecture model.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Contracts Service | `continuumContractService` | Backend | Rails / HTTP | 3.2.22.5 | Contract lifecycle APIs (Cicero) — CRUD, rendering, signing |
| Contract Service MySQL | `continuumContractMysql` | Database | MySQL | — | Primary relational datastore for contract definitions, templates, and contracts |

## Components by Container

### Contracts Service (`continuumContractService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `contractSvc_contractsApi` | Rails controller endpoints for contract CRUD and signing (`/v1/contracts`) | Rails Controllers |
| `contractSvc_definitionsApi` | Rails controller endpoints for contract definition CRUD and example rendering (`/v1/contract_definitions`) | Rails Controllers |
| `contractSvc_contractStore` | ActiveRecord models for contracts, contract versions, and identity/signature records | ActiveRecord |
| `contractSvc_definitionStore` | ActiveRecord models for contract definitions and definition templates | ActiveRecord |
| `contractSvc_documentRenderer` | Transforms contract data with XSLT/XSL templates into HTML, PDF, or plain-text output | Ruby Service |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMerchantSelfService` | `continuumContractService` | Manages contract definitions and contracts | REST / HTTP |
| `continuumContractService` | `continuumContractMysql` | Reads and writes contracts and definitions | MySQL (ActiveRecord) |
| `continuumContractService` | `metricsStack` | Emits request and performance metrics | Telegraf / UDP |
| `contractSvc_contractsApi` | `contractSvc_contractStore` | Creates and updates contract records | In-process |
| `contractSvc_contractsApi` | `contractSvc_documentRenderer` | Renders contract outputs (HTML/PDF) | In-process |
| `contractSvc_definitionsApi` | `contractSvc_definitionStore` | Creates and version-manages definitions | In-process |
| `contractSvc_definitionsApi` | `contractSvc_documentRenderer` | Builds example contract renderings | In-process |
| `contractSvc_contractStore` | `continuumContractMysql` | Reads and writes contract data | MySQL |
| `contractSvc_definitionStore` | `continuumContractMysql` | Reads and writes definition data | MySQL |
| `contractSvc_documentRenderer` | `contractSvc_definitionStore` | Loads schema and template definitions | In-process |

## Architecture Diagram References

- System context: `contexts-continuumContractService`
- Container: `containers-continuumContractService`
- Component: `components-continuum-contract-service-components`
