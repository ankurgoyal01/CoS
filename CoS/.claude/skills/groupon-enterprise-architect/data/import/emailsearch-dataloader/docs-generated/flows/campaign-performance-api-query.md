---
service: "emailsearch-dataloader"
title: "Campaign Performance API Query"
generated: "2026-03-03"
type: flow
flow_name: "campaign-performance-api-query"
flow_type: synchronous
trigger: "Inbound HTTP GET or POST request to the campaign performance REST API"
participants:
  - "continuumEmailSearchDataloaderService"
  - "continuumEmailSearchPostgresDb"
  - "continuumCampaignPerformanceMysqlDb"
architecture_ref: "emailsearch_dataloader_components"
---

# Campaign Performance API Query

## Summary

The Campaign Performance API Query flow handles synchronous REST requests from internal consumers who need to look up campaign performance data by UTM campaign identifier. The HTTP API Resources (JAX-RS) component receives the request, delegates to the Email Search Service core logic, which queries the appropriate data store via the DAO layer, and returns a JSON response. This API allows internal Rocketman services and operators to retrieve current campaign performance metrics without direct database access.

## Trigger

- **Type**: api-call
- **Source**: Internal service or operator calls the REST API on port 9000
- **Frequency**: On-demand (per request); low volume — internal service-to-service interface

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API caller (internal) | Initiates the HTTP request | External to this service |
| HTTP API Resources | Receives and validates the request; routes to core service | `continuumEmailSearchDataloaderService` |
| Email Search Service | Business logic for performance data retrieval | `continuumEmailSearchDataloaderService` |
| DAO Layer | Executes database queries | `continuumEmailSearchDataloaderService` |
| Email Search Postgres | Source of performance data (if from local store) | `continuumEmailSearchPostgresDb` |
| Campaign Performance MySQL | Source of campaign performance data (read-only) | `continuumCampaignPerformanceMysqlDb` |

## Steps

### GET /campaign_performance/{utm_campaign}

1. **Receive HTTP GET request**: The `emailsearchDataloader_apiResources` (JAX-RS resource) receives an HTTP GET request with the `utm_campaign` path parameter. The parameter is marked as personal data CLASS4 per JTier annotation.
   - From: API caller
   - To: `emailsearchDataloader_apiResources`
   - Protocol: REST (HTTP/JSON)

2. **Invoke Email Search Service**: The API resource delegates to `emailSearchService` to retrieve performance data for the given UTM campaign identifier.
   - From: `emailsearchDataloader_apiResources`
   - To: `emailSearchService`
   - Protocol: in-process

3. **Query data store via DAO Layer**: `emailSearchService` calls `daoLayer_EmaDat` to look up campaign performance metrics. The query may target `continuumEmailSearchPostgresDb` and/or `continuumCampaignPerformanceMysqlDb` depending on data source configuration.
   - From: `emailSearchService`
   - To: `daoLayer_EmaDat`
   - Protocol: in-process

4. **Execute database query**: The DAO layer executes a JDBC query against the appropriate database.
   - From: `daoLayer_EmaDat`
   - To: `continuumEmailSearchPostgresDb` or `continuumCampaignPerformanceMysqlDb`
   - Protocol: JDBC

5. **Return JSON response**: The API resource serializes the `CampaignPerformance` result to JSON and returns an HTTP 200 response.
   - From: `emailsearchDataloader_apiResources`
   - To: API caller
   - Protocol: REST (HTTP/JSON)

### POST /campaign_performances

1. **Receive HTTP POST request**: The `emailsearchDataloader_apiResources` receives a POST request with a `ListPerformancesRequest` JSON body containing a list of UTM campaign identifiers. Bean validation (`@NotNull @Valid`) is applied.
   - From: API caller
   - To: `emailsearchDataloader_apiResources`
   - Protocol: REST (HTTP/JSON)

2. **Invoke Email Search Service**: The API resource delegates to `emailSearchService` with the list of campaign identifiers.
   - From: `emailsearchDataloader_apiResources`
   - To: `emailSearchService`
   - Protocol: in-process

3. **Bulk query data store**: `emailSearchService` calls `daoLayer_EmaDat` for each (or all) campaign identifiers in the request.
   - From: `emailSearchService` / `daoLayer_EmaDat`
   - To: `continuumEmailSearchPostgresDb` or `continuumCampaignPerformanceMysqlDb`
   - Protocol: JDBC

4. **Return JSON response**: Returns HTTP 200 with a `CampaignPerformances` JSON object containing the list of results.
   - From: `emailsearchDataloader_apiResources`
   - To: API caller
   - Protocol: REST (HTTP/JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `utm_campaign` not found | Standard JAX-RS 404 response | Caller receives HTTP 404 |
| Invalid request body (POST) | `@Valid` annotation triggers validation exception; JAX-RS returns HTTP 400 | Caller receives HTTP 400 with validation error |
| Database unavailable | JDBC exception propagates; JAX-RS returns HTTP 500 | Caller receives HTTP 500 |
| Missing required body (POST) | `@NotNull` constraint fails; HTTP 400 | Caller receives HTTP 400 |

## Sequence Diagram

```
ApiCaller -> HttpApiResources: GET /campaign_performance/{utm_campaign}
HttpApiResources -> EmailSearchService: getPerformance(utmCampaign)
EmailSearchService -> DaoLayer: findByUtmCampaign(utmCampaign)
DaoLayer -> EmailSearchPostgres: SELECT ... WHERE utm_campaign = ? [JDBC]
EmailSearchPostgres --> DaoLayer: CampaignPerformance row
DaoLayer --> EmailSearchService: CampaignPerformance
EmailSearchService --> HttpApiResources: CampaignPerformance
HttpApiResources --> ApiCaller: HTTP 200 application/json

ApiCaller -> HttpApiResources: POST /campaign_performances {utmCampaigns: [...]}
HttpApiResources -> EmailSearchService: listPerformances(ListPerformancesRequest)
EmailSearchService -> DaoLayer: findByUtmCampaigns([...])
DaoLayer -> CampaignPerformanceMysql: SELECT ... WHERE utm_campaign IN (...) [JDBC]
CampaignPerformanceMysql --> DaoLayer: List<CampaignPerformance>
DaoLayer --> EmailSearchService: List<CampaignPerformance>
EmailSearchService --> HttpApiResources: CampaignPerformances
HttpApiResources --> ApiCaller: HTTP 200 application/json
```

## Related

- Architecture component view: `emailsearch_dataloader_components`
- Related flows: [Campaign Decision Job](campaign-decision-job.md)
