---
service: "itier-merchant-inbound-acquisition"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumMerchantInboundAcquisitionService"]
---

# Architecture Context

## System Context

The Merchant Inbound Acquisition service (`continuumMerchantInboundAcquisitionService`) is a container within the **Continuum Platform** software system. It is the public entry point for prospective merchants: browsers submit signup data to its HTTP endpoints, which in turn call internal Groupon services (Metro draft service via `continuumApiLazloService` for address lookups and Metro client for lead creation) and the external Salesforce CRM to persist merchant leads. The service is stateless; all persistent state is delegated downstream.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Merchant Inbound Acquisition Service | `continuumMerchantInboundAcquisitionService` | WebApp | Node.js, itier-server, React/Preact | 1.7.0-dev | Interaction-tier web application serving merchant signup flows and lead-capture APIs |

## Components by Container

### Merchant Inbound Acquisition Service (`continuumMerchantInboundAcquisitionService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Web Routes and Page Composition (`miaWebRoutes`) | HTTP route handlers that render `/merchant/signup` and `/merchant/signup/marketing` pages; expose the `/merchant/inbound/api/*` BFF endpoints | itier-server routing, Mustache templates, React/Preact SSR |
| Lead and Validation Handlers (`miaLeadAndValidationHandlers`) | Lead creation, field deduplication (validateField), address autocomplete, place-details lookup, and merchant config loading | Node.js handlers — `lead.js`, `dedupe.js`, `geo.js`, `place.js`, `loadconfig.js`, `pds.js` |
| Integration Clients (`miaIntegrationClients`) | Adapters for Metro client, Groupon V2 address API, Salesforce jsforce connection, and analytics/tracing dependencies | `@grpn/metro-client`, `itier-groupon-v2-client`, `jsforce`, `universal-analytics`, `itier-tracing` |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMerchantInboundAcquisitionService` | `continuumApiLazloService` | Calls address autocomplete results and place-details lookup APIs | REST/HTTP via `itier-groupon-v2-client` |
| `continuumMerchantInboundAcquisitionService` | `salesForce` | Creates CRM Lead objects for selected lead flows (non-account-creation countries) | REST via `jsforce` SDK |
| `miaWebRoutes` | `miaLeadAndValidationHandlers` | Routes merchant API and page requests to lead and validation handlers | In-process function call |
| `miaWebRoutes` | `miaIntegrationClients` | Uses shared clients for feature flags, layout, localization, and outbound API calls | In-process |
| `miaLeadAndValidationHandlers` | `miaIntegrationClients` | Uses outbound integrations for draft lead creation, geocoding, and CRM writes | In-process |

> Note: The relationship to `continuumMetroPlatform` (createDraftMerchant, getPDS) is present in code (`@grpn/metro-client`) but marked as `[stub-only]` in the architecture DSL, meaning it is modelled at the system level rather than as a direct container relationship in the current DSL import.

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-merchant-inbound-acquisition-service`
- Dynamic (lead capture flow): `dynamic-merchant-lead-capture-flow`
