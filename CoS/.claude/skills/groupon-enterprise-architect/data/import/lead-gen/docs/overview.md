# LeadGen Service Overview

LeadGen supports prospect acquisition, enrichment, and outreach for Sales. The stack is modeled inside the Continuum boundary and uses:

- `leadGenService` (Java) to orchestrate scraping, deduplication, enrichment, validation, and outreach.
- `leadGenWorkflows` (n8n) to schedule and trigger scraping/enrichment jobs and to persist workflow state in `leadGenDb` (PostgreSQL).
- External providers:
  - `apify` for scraping lead candidates backed by `googlePlaces` data.
  - `inferPDS` and `merchantQuality` (AIDG) for enrichment (wrapped by Encore when Clay invokes them).
  - `salesForce` (Salesforce) for account/contact creation.
  - `bird` (preferred) and `mailgun` (legacy fallback) for outbound messaging.
  - `clay` for automated lead sourcing; Clay calls Encore wrappers for AIDG services, invokes Apify/Google Places, and syncs to Salesforce.

Clay is modeled as an external system; it depends on Encore to wrap `inferPDS` and `merchantQuality` and uses Bird for outreach. LeadGen continues to call Apify/AIDG directly while Clay integration matures.
