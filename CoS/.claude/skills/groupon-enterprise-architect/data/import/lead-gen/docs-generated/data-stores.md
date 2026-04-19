---
service: "lead-gen"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "leadGenDb"
    type: "postgresql"
    purpose: "Primary data store for leads, contacts, enrichment data, outreach state, and workflow logs"
---

# Data Stores

## Overview

LeadGen uses a single PostgreSQL database (`leadGenDb`) as its primary data store. All lead records, enrichment results, outreach campaign state, and workflow execution logs are persisted here. The LeadGen Service accesses the database via JDBC, and the n8n workflows write workflow status and logs directly via SQL connections.

## Stores

### LeadGen DB (`leadGenDb`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `leadGenDb` |
| Purpose | Stores leads, contacts, enrichment and outreach status, logs |
| Ownership | owned |
| Migrations path | Managed by the lead-gen service repository |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `leads` | Raw scraped lead records from Apify | `id`, `business_name`, `address`, `phone`, `email`, `website`, `source`, `region`, `category`, `scraped_at`, `status` |
| `lead_enrichment` | Enrichment data attached to a lead | `id`, `lead_id`, `pds_score`, `pds_data`, `quality_score`, `quality_data`, `enriched_at`, `enrichment_status` |
| `lead_contacts` | Contact persons extracted or inferred for a lead | `id`, `lead_id`, `name`, `email`, `phone`, `title`, `source` |
| `outreach_campaigns` | Email outreach campaign definitions | `id`, `name`, `template_id`, `status`, `created_at`, `started_at`, `completed_at` |
| `outreach_messages` | Individual outreach messages sent per lead | `id`, `campaign_id`, `lead_id`, `contact_id`, `mailgun_message_id`, `status`, `sent_at`, `opened_at`, `replied_at` |
| `crm_sync_log` | Salesforce sync status per lead | `id`, `lead_id`, `sf_account_id`, `sf_contact_id`, `sync_status`, `synced_at`, `error_message` |
| `workflow_runs` | n8n workflow execution logs | `id`, `workflow_name`, `trigger_type`, `status`, `started_at`, `completed_at`, `error_details` |

#### Access Patterns

- **Read**: Lead queries with filtering by status, region, score thresholds; enrichment lookups by lead_id; outreach message status tracking; workflow run history
- **Write**: Bulk inserts of scraped leads; enrichment result updates per lead; outreach message status transitions; CRM sync log entries; workflow run start/complete/error logging
- **Indexes**: `leads(status, region)`, `leads(scraped_at)`, `lead_enrichment(lead_id)`, `outreach_messages(campaign_id, status)`, `crm_sync_log(lead_id)`, `workflow_runs(workflow_name, status)`

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| — | — | No dedicated cache layer is currently used | — |

> No dedicated caching layer is currently deployed. Enrichment data is persisted directly to PostgreSQL. If enrichment latency becomes a bottleneck, consider adding Redis for caching PDS and quality score results.

## Data Flows

- **Scrape -> Persist**: Apify scraping results are received by `leadGenService` and bulk-inserted into the `leads` table
- **Enrich -> Update**: PDS and quality score enrichment results are written to `lead_enrichment` and linked to the originating lead record
- **Outreach -> Track**: Outreach message send/open/reply events update `outreach_messages` status
- **CRM Sync -> Log**: Salesforce Account/Contact creation results are logged to `crm_sync_log`
- **Workflow -> Log**: n8n workflow execution state transitions are written to `workflow_runs` by the workflow engine directly
