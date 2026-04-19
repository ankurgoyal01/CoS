---
service: "lead-gen"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 5
internal_count: 0
---

# Integrations

## Overview

LeadGen Service integrates with five external systems and no internal Continuum platform services (beyond its own database). All external integrations are accessed via REST or API protocols from the `leadGenService` container. The n8n workflow engine (`leadGenWorkflows`) orchestrates job scheduling but does not directly call external systems -- it delegates to `leadGenService` for all external communication.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Apify | API | Web scraping of prospect leads | yes | `apify` |
| InferPDS | REST | Lead enrichment with PDS inference data | yes | `inferPDS` |
| Merchant Quality | REST | Lead enrichment with merchant quality scores | yes | `merchantQuality` |
| Mailgun | API | Email outreach campaign delivery | yes | `mailgun` |
| Salesforce | REST | Account and Contact creation for qualified leads | yes | `salesForce` |

### Apify Detail

- **Protocol**: API (REST-based Apify Actor API)
- **Base URL / SDK**: Apify Cloud API; configured via environment variable
- **Auth**: API token stored as secret
- **Purpose**: Executes web scraping actors to discover potential merchant leads from Google Places and other web sources. Apify actors are configured with region/category parameters and return structured business data (name, address, phone, website, email)
- **Failure mode**: Scraping jobs fail; no new leads enter the pipeline. Retryable with smaller batch sizes or different actor parameters
- **Circuit breaker**: No evidence found; failures are handled at the workflow retry level

### InferPDS Detail

- **Protocol**: REST
- **Base URL / SDK**: Internal AIDG service endpoint; configured via environment variable
- **Auth**: Service-to-service authentication
- **Purpose**: Enriches scraped leads with Probabilistic Data Service (PDS) inference data, providing business categorization, size estimates, and predictive attributes that help score lead quality
- **Failure mode**: Enrichment pipeline stalls for PDS data; leads remain in "pending enrichment" state. Retryable once service recovers; cached enrichment may be used as fallback
- **Circuit breaker**: No evidence found

### Merchant Quality Detail

- **Protocol**: REST
- **Base URL / SDK**: Internal AIDG service endpoint; configured via environment variable
- **Auth**: Service-to-service authentication
- **Purpose**: Enriches leads with a composite quality score derived from merchant signals, helping prioritize high-value prospects for outreach. Used in conjunction with PDS data to compute a final lead score
- **Failure mode**: Quality scoring unavailable; leads proceed with PDS enrichment only. Final lead score is degraded but outreach can continue with partial enrichment
- **Circuit breaker**: No evidence found

### Mailgun Detail

- **Protocol**: API (Mailgun REST API)
- **Base URL / SDK**: Mailgun API endpoint; configured via environment variable
- **Auth**: API key stored as secret
- **Purpose**: Sends outreach emails to qualified leads on behalf of the Sales team. Supports templated email campaigns, delivery tracking (sent, opened, bounced), and inbox warmup sequences to maintain sender reputation
- **Failure mode**: Outreach emails are not delivered; campaign stalls. Rate limit or block errors require switching to alternate provider or pausing campaign. Delivery status tracked in `outreach_messages` table
- **Circuit breaker**: No evidence found; failures tracked per-message with retry logic

### Salesforce Detail

- **Protocol**: REST (Salesforce REST API)
- **Base URL / SDK**: Salesforce instance URL; configured via environment variable
- **Auth**: OAuth 2.0 credentials stored as secrets
- **Purpose**: Creates Account and Contact records in Salesforce for leads that have been enriched and qualified through outreach. This is the handoff point to the Sales team, who manage the prospect relationship from Salesforce onward
- **Failure mode**: CRM sync fails; leads accumulate in "pending sync" state. Salesforce daily API limits can cause batch failures. Sync retried when limits reset; failures logged to `crm_sync_log`
- **Circuit breaker**: No evidence found; sync retries managed at workflow level

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| — | — | No internal Continuum service dependencies beyond own database | — |

> LeadGen does not currently depend on other internal Continuum services. The `inferPDS` and `merchantQuality` services are AIDG endpoints accessed as external REST dependencies. Future integration with Clay (external lead sourcing automation) would route through Encore wrappers rather than direct LeadGen calls.

## Consumed By

> Upstream consumers are tracked in the central architecture model. The primary consumer of LeadGen output is the Sales team via Salesforce. n8n workflows trigger LeadGen Service APIs on schedule.

## Dependency Health

- External dependency health is monitored through the `/api/pipeline/status` endpoint, which reports scrape queue depth, enrichment backlog, and outreach pending counts
- Apify job failures are detected by the n8n workflow engine and retried with configurable backoff
- Mailgun delivery failures are tracked per-message in the `outreach_messages` table; aggregate delivery rates are monitored
- Salesforce sync failures are logged to `crm_sync_log` with error details; daily API limit consumption is tracked
- No explicit circuit breaker patterns are implemented; failure handling relies on workflow-level retry logic and per-message status tracking
