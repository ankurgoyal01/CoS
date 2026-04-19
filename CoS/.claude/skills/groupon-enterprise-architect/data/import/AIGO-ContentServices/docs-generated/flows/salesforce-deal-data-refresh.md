---
service: "AIGO-ContentServices"
title: "Salesforce Deal Data Refresh"
generated: "2026-03-03"
type: flow
flow_name: "salesforce-deal-data-refresh"
flow_type: synchronous
trigger: "User or operator calls the Salesforce poll endpoint to refresh deal data"
participants:
  - "continuumFrontendContentGenerator"
  - "continuumContentGeneratorService"
  - "salesForce"
architecture_ref: "dynamic-continuumContentGeneratorService"
---

# Salesforce Deal Data Refresh

## Summary

This flow refreshes the local cache of Salesforce deal data used by the Content Generator Service. The operator (or automated process) triggers the poll-job endpoint, which creates a Salesforce bulk query job, polls until results are ready, saves the CSV output to the container filesystem, and makes the data available for subsequent deal selection in the frontend via the `get-stored-data` endpoint.

## Trigger

- **Type**: api-call (user-action or operator-initiated)
- **Source**: User clicks "Refresh Deals" in the frontend UI, or operator directly calls `GET /salesforce/poll-job`; alternatively frontend calls `POST /salesforce/launch-job` then `GET /salesforce/store-results/{job_id}` separately
- **Frequency**: On-demand; typically before starting a content generation session to ensure deal data is current

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Client Layer | Initiates Salesforce endpoint calls | `fgApiClient` |
| Generation API | Receives requests; delegates to Salesforce Integration | `cgGenerationApi` |
| Salesforce Integration | Authenticates, creates bulk job, polls, downloads, and stores results | `cgSalesforceIntegration` |
| Salesforce | External CRM providing deal data via Bulk API v2 | `salesForce` |

## Steps

1. **Trigger data refresh**: API Client Layer calls `GET /salesforce/poll-job` (recommended combined flow) with optional query params `max_attempts` (default 6), `interval` (default 10.0s), `initial_wait` (default 10.0s).
   - From: `fgApiClient`
   - To: `cgGenerationApi`
   - Protocol: HTTPS/JSON

2. **Authenticate with Salesforce**: Salesforce Integration calls `salesforce_login()` to obtain an OAuth access token using credentials from `SF_USERNAME`, `SF_PASSWORD`, `SF_INSTANCE_URL` env vars.
   - From: `cgSalesforceIntegration`
   - To: `salesForce`
   - Protocol: HTTPS (OAuth)

3. **Create bulk query job**: Salesforce Integration calls `create_salesforce_query_job(access_token, instance_url, salesforce_deals_query)` to submit the deals bulk query to Salesforce Bulk API v2.
   - From: `cgSalesforceIntegration`
   - To: `salesForce`
   - Protocol: HTTPS (Salesforce Bulk API v2)

4. **Initial wait**: Service sleeps for `initial_wait` seconds before starting to poll.

5. **Poll for results**: Salesforce Integration loops up to `max_attempts` times, calling `get_job_results(access_token, instance_url, job_id)` at `interval` second intervals until CSV data is returned.
   - From: `cgSalesforceIntegration`
   - To: `salesForce`
   - Protocol: HTTPS (Salesforce Bulk API v2)

6. **Save CSV results**: Once results are available, Salesforce Integration writes the CSV data to `salesforce/salesforce_data/salesforce_data.csv` within the container filesystem.
   - From: `cgSalesforceIntegration`
   - To: container filesystem
   - Protocol: file I/O

7. **Return success response**: Generation API returns `{"status": "completed", "message": "Results saved to salesforce_data.csv", "attempts": N}`.
   - From: `cgGenerationApi`
   - To: `fgApiClient`
   - Protocol: HTTPS/JSON

8. **Fetch stored data**: Frontend or subsequent process calls `GET /salesforce/get-stored-data` to retrieve the stored CSV as `{"deals": [...]}` JSON, with NaN values cleaned and surrogate pairs stripped.
   - From: `fgApiClient`
   - To: `cgGenerationApi`
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce authentication failure | `salesforce_login()` returns `None` | HTTP 401 with `"Failed to authenticate with Salesforce"` |
| Job creation failure | No `id` in job response | HTTP 500 with detail |
| Polling timeout (results not ready after `max_attempts`) | Loop exhausted | HTTP 408 with timeout message |
| No CSV file when calling `get-stored-data` | File existence check fails | HTTP 404 with `"CSV file not found"` |
| CSV parsing error | Exception in `process_csv_data()` | HTTP 500 with detail |

## Sequence Diagram

```
fgApiClient -> cgGenerationApi: GET /salesforce/poll-job?max_attempts=6&interval=10&initial_wait=10
cgSalesforceIntegration -> salesForce: OAuth login request
salesForce --> cgSalesforceIntegration: access_token
cgSalesforceIntegration -> salesForce: POST Bulk API - create query job (salesforce_deals_query)
salesForce --> cgSalesforceIntegration: {id: job_id, ...}
cgSalesforceIntegration -> cgSalesforceIntegration: sleep(initial_wait)
loop up to max_attempts:
  cgSalesforceIntegration -> salesForce: GET Bulk API - get job results (job_id)
  salesForce --> cgSalesforceIntegration: CSV data (or empty if not ready)
  alt CSV data available:
    cgSalesforceIntegration -> filesystem: write salesforce_data.csv
    break
  else not ready:
    cgSalesforceIntegration -> cgSalesforceIntegration: sleep(interval)
  end
end
cgGenerationApi --> fgApiClient: {status: "completed", attempts: N}
fgApiClient -> cgGenerationApi: GET /salesforce/get-stored-data
cgGenerationApi -> filesystem: read salesforce_data.csv
cgGenerationApi --> fgApiClient: {deals: [...]}
```

## Related

- Architecture dynamic view: `dynamic-continuumContentGeneratorService`
- Related flows: [Multi-Step Content Generation](multi-step-content-generation.md)
