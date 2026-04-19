---
service: "HotzoneGenerator"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumHotzoneGeneratorJob"]
---

# Architecture Context

## System Context

HotzoneGenerator is a scheduled batch container within the `continuumSystem` (Continuum Platform). It has no inbound traffic — it is triggered solely by cron. At runtime it reaches out to five internal Continuum services to gather and enrich deal data, then writes the generated hotzones back to the Proximity Notifications API. It sits in the Emerging Channels / Proximity subdomain, acting as the data-preparation job that feeds the consumer proximity notification pipeline.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Hotzone Generator Job | `continuumHotzoneGeneratorJob` | Batch Job | Java 8, Maven | 1.26-SNAPSHOT | Scheduled Java batch job that generates and updates hotzones and auto campaigns by aggregating deal, taxonomy, and proximity data. |

## Components by Container

### Hotzone Generator Job (`continuumHotzoneGeneratorJob`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `hotzoneJobOrchestrator` | Coordinates run modes (`config`, `deal_list`, `weekly_email`), validates configs, and drives end-to-end generation flow from the CLI entry point (`App.java`). | Java (App.java) |
| `configAndScheduleManager` | Loads active hotzone campaign configs from the Proximity API, country lists, and division coefficients used for radius adjustment decisions. | Java (HotzoneConfig, GconfigSourceProvider) |
| `dealAggregationEngine` | Fetches deals from MDS, filters by price/conversion/purchase thresholds, enriches with taxonomy, deal-catalog inventory IDs, and open-hours data from GAPI. | Java (GenerateHotzonesWithMDSDealInfo, DataParser) |
| `campaignAutomationEngine` | Builds and POSTs automated category campaigns from deal-cluster trending data; runs every Tuesday or when `createAuto` flag is set. | Java (GenerateCampaignWithCategoryInfo) |
| `proximitySyncClient` | Reads and mutates hotzone/campaign/send-log state via the Proximity Notifications API. Handles cleanup of expired hotzones and send logs. | HTTP Client (HttpClient.java) |
| `weeklyEmailDispatcher` | Queries weekly consumer IDs from the Proximity PostgreSQL database and triggers per-consumer email send via the Proximity API. | Java (AppDataConnection + HTTP Client) |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumHotzoneGeneratorJob` | `continuumMarketingDealService` | Fetches deal and division data | HTTPS/JSON |
| `continuumHotzoneGeneratorJob` | `continuumTaxonomyService` | Fetches taxonomy metadata (English category names) | HTTPS/JSON |
| `continuumHotzoneGeneratorJob` | `continuumDealCatalogService` | Fetches deal-catalog details (inventory product IDs) | HTTPS/JSON |
| `continuumHotzoneGeneratorJob` | `apiProxy` | Calls internal proxied endpoints for deal clusters and GAPI open-hours | HTTPS/JSON |
| `dealAggregationEngine` | `continuumMarketingDealService` | Fetches divisions and deal datasets | HTTPS/JSON |
| `dealAggregationEngine` | `continuumTaxonomyService` | Fetches category names/metadata | HTTPS/JSON |
| `dealAggregationEngine` | `continuumDealCatalogService` | Fetches deal details (inventory product IDs) | HTTPS/JSON |
| `dealAggregationEngine` | `apiProxy` | Calls internal proxy-backed APIs for inventory/deal enrichment and open hours | HTTPS/JSON |
| `campaignAutomationEngine` | `continuumMarketingDealService` | Loads country/division context | HTTPS/JSON |
| `campaignAutomationEngine` | `continuumTaxonomyService` | Looks up taxonomy display names | HTTPS/JSON |
| `campaignAutomationEngine` | `apiProxy` | Calls deal cluster endpoints via internal API proxy | HTTPS/JSON |
| `campaignAutomationEngine` | `proximitySyncClient` | Submits generated campaigns | Internal method call |
| `weeklyEmailDispatcher` | `proximitySyncClient` | Triggers send-email endpoint per consumer | Internal method call |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumHotzoneGeneratorJob`
- Component: `components-continuumHotzoneGeneratorJob`
- Dynamic view: `dynamic-hotzoneGenerationFlow`
