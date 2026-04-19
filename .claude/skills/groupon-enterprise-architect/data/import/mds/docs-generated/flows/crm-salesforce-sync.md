---
service: "mds"
title: "CRM Salesforce Sync"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "crm-salesforce-sync"
flow_type: asynchronous
trigger: "Deal enrichment pipeline triggers CRM attribute fetch during enrichment cycle"
participants:
  - "continuumMarketingDealService"
  - "continuumMarketingDealDb"
  - "salesForce"
architecture_ref: "dynamic-mds-crm-sync"
---

# CRM Salesforce Sync

## Summary

The CRM Salesforce sync flow handles the integration between MDS and Salesforce for merchant and deal CRM attribute enrichment. During the deal enrichment pipeline, MDS fetches CRM attributes (sales rep assignments, merchant tier, account metadata, campaign associations) from Salesforce's REST API and incorporates them into the enriched deal record. This data enhances deal feeds and performance reports with CRM context. The sync is read-only from MDS's perspective -- MDS consumes CRM data but does not write back to Salesforce.

## Trigger

- **Type**: event (sub-step within deal enrichment pipeline)
- **Source**: Deal Enrichment Pipeline requests CRM attributes for a deal being enriched
- **Frequency**: Per deal enrichment cycle; triggered for deals with merchant CRM associations

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Enrichment Pipeline | Requests CRM data as part of enrichment | `mdsDealEnrichmentPipeline` |
| External Service Adapters | HTTP client for Salesforce API | `externalAdapters` |
| Salesforce | CRM data source for merchant/deal attributes | `salesForce` |
| Persistence Adapter | Persists CRM-enriched deal data | `mdsDealPersistenceAdapter` |
| Marketing Deal Service Database | Stores CRM attributes with deal records | `continuumMarketingDealDb` |

## Steps

1. **Initiate CRM fetch**: During the enrichment pipeline, the Deal Enrichment Pipeline determines that the deal has merchant CRM associations and initiates a CRM attribute fetch.
   - From: `mdsDealEnrichmentPipeline`
   - To: internal (decision logic)
   - Protocol: in-process

2. **Call Salesforce API**: External Service Adapters call the Salesforce REST API with the merchant/deal identifiers to retrieve CRM attributes.
   - From: `externalAdapters`
   - To: `salesForce`
   - Protocol: REST/HTTPS (OAuth authenticated)

3. **Receive CRM attributes**: Salesforce returns merchant CRM data including sales rep assignment, merchant tier, account status, and campaign associations.
   - From: `salesForce`
   - To: `externalAdapters`
   - Protocol: REST/HTTPS

4. **Merge CRM data into deal record**: The enrichment pipeline merges the CRM attributes into the deal enrichment payload alongside other enrichment data (taxonomy, pricing, location, performance).
   - From: `externalAdapters`
   - To: `mdsDealEnrichmentPipeline`
   - Protocol: in-process

5. **Persist CRM-enriched deal**: The Persistence Adapter writes the CRM-enriched deal data to PostgreSQL as part of the overall enrichment persistence step.
   - From: `mdsDealEnrichmentPipeline`
   - To: `mdsDealPersistenceAdapter` -> `continuumMarketingDealDb`
   - Protocol: JDBC (Sequelize)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce API unavailable | CRM enrichment skipped for this deal; enrichment proceeds with other data sources | Deal enriched without CRM attributes; retried on next enrichment cycle |
| Salesforce API rate limit | Request backed off and retried with exponential delay | CRM data retrieved on retry; enrichment may be delayed |
| Salesforce authentication failure | CRM enrichment skipped; alert emitted | All CRM enrichment blocked until token refresh; manual intervention may be needed |
| Invalid/missing CRM data for deal | Deal proceeds without CRM attributes; logged for investigation | No adverse impact on core deal data |

## Sequence Diagram

```
mdsDealEnrichmentPipeline -> externalAdapters: fetchCrmAttributes(merchant_id, deal_id)
externalAdapters -> salesForce: GET /services/data/accounts?merchant_id=X
salesForce --> externalAdapters: {sales_rep, merchant_tier, account_status, campaigns}
externalAdapters --> mdsDealEnrichmentPipeline: crm_attributes
mdsDealEnrichmentPipeline -> mdsDealEnrichmentPipeline: merge CRM data into deal
mdsDealEnrichmentPipeline -> mdsDealPersistenceAdapter: persist(deal with CRM data)
mdsDealPersistenceAdapter -> continuumMarketingDealDb: UPDATE deal SET crm_attributes = ...
continuumMarketingDealDb --> mdsDealPersistenceAdapter: OK
```

## Related

- Architecture dynamic view: `dynamic-mds-crm-sync`
- Related flows: [Deal Enrichment Pipeline](deal-enrichment-pipeline.md)
