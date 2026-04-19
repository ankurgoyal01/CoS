---
service: "lead-gen"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for LeadGen Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Lead Scraping Pipeline](lead-scraping-pipeline.md) | scheduled | n8n scheduled trigger or manual API call | Scrapes prospect leads from web sources via Apify, deduplicates, and persists to database |
| [Lead Enrichment](lead-enrichment.md) | batch | n8n trigger after scraping completes or manual API call | Enriches scraped leads with PDS inference data and merchant quality scores |
| [Outreach Campaign](outreach-campaign.md) | batch | n8n trigger after enrichment qualifies leads or manual API call | Sends templated email outreach to qualified leads via Mailgun |
| [Salesforce Account Creation](salesforce-account-creation.md) | batch | n8n trigger after outreach engagement or manual API call | Creates Salesforce Accounts and Contacts for engaged leads |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 4 |

## Cross-Service Flows

- The [Lead Scraping Pipeline](lead-scraping-pipeline.md) flow spans `leadGenWorkflows`, `leadGenService`, `apify`, and `leadGenDb`
- The [Lead Enrichment](lead-enrichment.md) flow spans `leadGenWorkflows`, `leadGenService`, `inferPDS`, `merchantQuality`, and `leadGenDb`
- The [Outreach Campaign](outreach-campaign.md) flow spans `leadGenWorkflows`, `leadGenService`, `mailgun`, and `leadGenDb`
- The [Salesforce Account Creation](salesforce-account-creation.md) flow spans `leadGenWorkflows`, `leadGenService`, `salesForce`, and `leadGenDb`

> Dynamic views are not yet defined in Structurizr for this service. See the component diagrams (`components-continuum-leadgen-service`, `components-continuum-leadgen-workflows`) for static container relationships.
