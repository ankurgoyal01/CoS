---
service: "leadminer"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumM3System"
  containers: [continuumM3LeadminerService]
---

# Architecture Context

## System Context

Leadminer sits within the Continuum platform's M3 (Merchants and Places) system. It is a Rails web application used exclusively by internal operators to inspect and edit M3 data. The service has no local database; it delegates all reads and writes to specialized M3 backend services. Authentication is handled by Control Room. The service integrates with Salesforce for external merchant UUID mapping and calls Taxonomy and GeoDetails services for reference data enrichment.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Leadminer Web App | `continuumM3LeadminerService` | Web Application | Ruby on Rails | 3.2.22.3 | Browser-based editor for M3 Places and Merchants data; stateless — all persistence via downstream APIs |

## Components by Container

### Leadminer Web App (`continuumM3LeadminerService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Places Controller (`/p`) | Search, list, view, and edit Place records | Rails MVC |
| Merge Controller (`/p/merge`) | Merge duplicate Place records | Rails MVC |
| Defrank Controller (`/p/defrank`) | Defrank flagged Place records | Rails MVC |
| Autocomplete Controller (`/p/autocomplete`) | Type-ahead place search suggestions | Rails MVC |
| Merchants Controller (`/m`) | Search, list, view, and edit Merchant records | Rails MVC |
| Input History Controller (`/i`) | View input history for places and merchants | Rails MVC |
| API Controllers (`/api/*`) | Business categories, services, geocode lookups | Rails MVC |
| Users Controller (`/u`) | Internal user management | Rails MVC |
| Heartbeat Controller (`/heartbeat`) | Health check endpoint | Rails MVC |
| M3 Client Integration | Wraps m3_client gem for all M3 API calls | m3_client 3.14.0 |
| Phone Validator | Validates and normalizes phone numbers | global_phone 1.0.1 |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumM3LeadminerService` | `continuumPlaceReadService` | Reads place records and search results | REST/HTTP |
| `continuumM3LeadminerService` | `continuumPlaceWriteService` | Writes place edits, merges, defranks | REST/HTTP |
| `continuumM3LeadminerService` | `continuumM3MerchantService` | Reads and writes merchant records | REST/HTTP |
| `continuumM3LeadminerService` | `continuumInputHistoryService` | Retrieves input history for places/merchants | REST/HTTP |
| `continuumM3LeadminerService` | `continuumBoomStickService` | Supplementary place/merchant data lookups | REST/HTTP |
| `continuumM3LeadminerService` | `continuumTaxonomyService` | Fetches business categories and service taxonomy | REST/HTTP |
| `continuumM3LeadminerService` | `continuumGeoDetailsService` | Resolves geocode and address details | REST/HTTP |
| `continuumM3LeadminerService` | `salesForce` | External merchant UUID mapping | REST/HTTP |
| `continuumControlRoom` | `continuumM3LeadminerService` | Authenticates operator sessions | REST/HTTP |

## Architecture Diagram References

- System context: `contexts-continuum-m3`
- Container: `containers-continuum-m3`
- Component: `components-leadminer`
- Dynamic view: `dynamic-place-edit-flow`
