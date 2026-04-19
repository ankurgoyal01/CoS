---
service: "gcp-aiaas-cloud-functions"
title: "PDS Priority Query"
generated: "2026-03-03"
type: flow
flow_name: "pds-priority-query"
flow_type: synchronous
trigger: "HTTP GET or POST with one or more filter parameters"
participants:
  - "continuumAiaasPdsPriorityFunction"
  - "bigQuery"
architecture_ref: "components-continuumAiaasPdsPriorityFunction"
---

# PDS Priority Query

## Summary

The PDS Priority flow accepts one or more filter parameters (account ID, city, PDS category, merchant potential, etc.) and queries Groupon's BigQuery supply dataset to return the current prioritized PDS records matching those filters. It provides supply operations and merchant advisor tooling with ranked merchant-PDS combinations to guide deal sourcing activity. Results always reflect the most recent data partition in BigQuery.

## Trigger

- **Type**: api-call
- **Source**: Supply operations tooling or merchant advisor dashboards calling the PDS Priority Cloud Function with filter parameters
- **Frequency**: On-demand (per priority data lookup)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| PDS Priority Cloud Function | Entry point; validates filters, builds query, returns results | `continuumAiaasPdsPriorityFunction` |
| PDS Priority Request Handler | Parses and validates filter parameters from JSON body or query string | `continuumAiaasPdsPriorityFunction_pdsPriorityRequestHandler` |
| BigQuery Client | Builds parameterized SQL query and executes against supply dataset | `continuumAiaasPdsPriorityFunction_pdsPriorityBigQueryClient` |
| BigQuery | Supply dataset `prj-grp-dataview-prod-1ff9.supply.acc_information_pds` | `bigQuery` |

## Steps

1. **Receive filter request**: The Request Handler accepts a GET or POST request. Filter parameters can be provided as query string parameters or in a JSON request body.
   - From: Caller
   - To: `continuumAiaasPdsPriorityFunction`
   - Protocol: REST/HTTPS

2. **Parse and validate filters**: The Request Handler extracts allowed filter keys: `accountId`, `city`, `country`, `consolidatedCity`, `pdsCatName`, `pdsCatId`, `merchantPotential`, `customerPercentileBucket`, `slEligible`, `tg`. Maps camelCase parameter names to snake_case column names. Requires at least one non-empty filter.
   - From: `continuumAiaasPdsPriorityFunction_pdsPriorityRequestHandler`
   - To: `continuumAiaasPdsPriorityFunction_pdsPriorityRequestHandler` (internal)
   - Protocol: direct

3. **Authenticate BigQuery client**: The BigQuery Client initializes using a service account JSON file on disk (`service_account.json`) or the `GOOGLE_APPLICATION_CREDENTIALS_JSON` environment variable. Falls back to application default credentials for local testing.
   - From: `continuumAiaasPdsPriorityFunction_pdsPriorityBigQueryClient`
   - To: `bigQuery` (GCP IAM)
   - Protocol: GCP IAM / service account

4. **Build and execute SQL query**: Constructs a dynamic SQL query with a WHERE clause using the validated filter conditions, always constraining to the most recent `load_date`:
   ```sql
   SELECT * FROM `prj-grp-dataview-prod-1ff9.supply.acc_information_pds`
   WHERE load_date = (SELECT MAX(load_date) FROM `prj-grp-dataview-prod-1ff9.supply.acc_information_pds`)
   AND <filter conditions>
   ```
   - From: `continuumAiaasPdsPriorityFunction_pdsPriorityBigQueryClient`
   - To: `bigQuery`
   - Protocol: BigQuery API (google-cloud-bigquery)

5. **Transform and return results**: Query results are iterated; all keys are converted from snake_case to camelCase. Returns the JSON array to the caller with HTTP 200.
   - From: `continuumAiaasPdsPriorityFunction`
   - To: Caller
   - Protocol: REST/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No filter parameters provided | Return `400 MISSING_FILTERS` | Error response listing allowed filter keys |
| Filter parsing failure | Return `400 PARAMETER_PARSING_ERROR` | Error response with parse error details |
| No records match filters | Return `404 NO_DATA_FOUND` | Error response with the filter conditions used |
| BigQuery query execution failure | Return `500 BIGQUERY_ERROR` | Error response with BigQuery exception message |

## Sequence Diagram

```
Caller -> PdsPriorityFunction: GET /?city=Chicago&merchantPotential=High+Potential
PdsPriorityFunction -> PdsPriorityFunction: Parse and validate filter parameters
PdsPriorityFunction -> BigQuery: Authenticate with service account
PdsPriorityFunction -> BigQuery: SELECT * FROM supply.acc_information_pds WHERE load_date=MAX(load_date) AND city='Chicago' AND merchant_potential='High Potential'
BigQuery --> PdsPriorityFunction: Result rows
PdsPriorityFunction -> PdsPriorityFunction: Convert snake_case keys to camelCase
PdsPriorityFunction --> Caller: 200 [{accountId, city, pdsCatName, merchantPotential, ...}]
```

## Related

- Architecture dynamic view: `components-continuumAiaasPdsPriorityFunction`
- Related flows: [Merchant Potential Scoring via Google Scraper](merchant-potential-scoring.md)
