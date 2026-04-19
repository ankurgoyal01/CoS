---
service: "lpapi"
title: "Auto-Index Analysis Job"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "auto-index-analysis-job"
flow_type: scheduled
trigger: "Scheduled job execution or manual trigger via POST /lpapi/autoindex/jobs"
participants:
  - "continuumLpapiApp"
  - "appAutoIndexCoordinator"
  - "continuumLpapiAutoIndexer"
  - "autoIndexScheduler"
  - "autoIndexCrawler"
  - "autoIndexAnalyzer"
  - "autoIndexDataAccess"
  - "autoIndexGscCollector"
  - "continuumRelevanceApi"
  - "continuumLpapiReadOnlyPostgres"
  - "continuumLpapiPrimaryPostgres"
architecture_ref: "dynamic-autoIndexFlow"
---

# Auto-Index Analysis Job

## Summary

The Auto-Index Analysis Job is a background process executed by `continuumLpapiAutoIndexer` that evaluates landing pages for search engine indexability. It reads page and route metadata, fetches deal card availability from the Relevance API, optionally collects Google Search Console performance signals, and persists per-page index recommendations to the primary PostgreSQL store. The flow is coordinated by `appAutoIndexCoordinator` in `continuumLpapiApp` and executed on a schedule by `autoIndexScheduler`.

## Trigger

- **Type**: schedule (and manual via API)
- **Source**: `autoIndexScheduler` in `continuumLpapiAutoIndexer`, or manual `POST /lpapi/autoindex/jobs`
- **Frequency**: Periodic scheduled runs; frequency configured via `/lpapi/autoindex/config`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| LPAPI App | Provides orchestration hooks to configure and initiate runs | `continuumLpapiApp` |
| Auto Index Coordinator | Application-level hook that triggers the worker | `appAutoIndexCoordinator` |
| LPAPI Auto Indexer | Background worker process that executes the analysis | `continuumLpapiAutoIndexer` |
| Auto Index Scheduler | Schedules and coordinates job lifecycle | `autoIndexScheduler` |
| Page Crawler | Retrieves rendered landing page content | `autoIndexCrawler` |
| RAPI Analyzer | Queries Relevance API for deal signal analysis | `autoIndexAnalyzer` |
| Auto Index Data Access | Reads page metadata; writes job state and results | `autoIndexDataAccess` |
| Search Console Collector | Optionally fetches GSC search performance metrics | `autoIndexGscCollector` |
| Relevance API | External source of deal card and page quality signals | `continuumRelevanceApi` |
| LPAPI Read-Only Postgres | Source of page and route metadata for analysis inputs | `continuumLpapiReadOnlyPostgres` |
| LPAPI Primary Postgres | Target for job state and analysis result writes | `continuumLpapiPrimaryPostgres` |

## Steps

1. **Initiates job execution**: `appAutoIndexCoordinator` signals `continuumLpapiAutoIndexer` to begin an analysis run
   - From: `appAutoIndexCoordinator`
   - To: `autoIndexScheduler`
   - Protocol: direct (in-process / worker invocation)

2. **Schedules and opens job record**: `autoIndexScheduler` creates a job record in `continuumLpapiPrimaryPostgres` with status `running`
   - From: `autoIndexScheduler`
   - To: `autoIndexDataAccess` -> `continuumLpapiPrimaryPostgres`
   - Protocol: JDBC

3. **Reads candidate pages and routes**: `autoIndexDataAccess` loads the set of pages and routes to evaluate from the read replica
   - From: `autoIndexDataAccess`
   - To: `continuumLpapiReadOnlyPostgres`
   - Protocol: JDBC

4. **Crawls rendered page content** (per candidate page): `autoIndexCrawler` retrieves rendered landing page HTML for each candidate URL from the routing service
   - From: `autoIndexCrawler`
   - To: upstream routing service (stub — `unknown_routingservice_a0bb640f`, not in federated model)
   - Protocol: HTTP

5. **Analyzes deal and quality signals** (per candidate page): `autoIndexAnalyzer` queries `continuumRelevanceApi` for deal card availability and page-level relevance context
   - From: `autoIndexAnalyzer`
   - To: `continuumRelevanceApi`
   - Protocol: HTTP

6. **Collects GSC metrics** (optional, per candidate page): `autoIndexGscCollector` fetches search performance metrics (impressions, clicks, position) from Google Search Console
   - From: `autoIndexGscCollector`
   - To: Google Search Console API (stub — `unknown_googlesearchconsole_035db05d`, not in federated model)
   - Protocol: HTTPS

7. **Persists analysis results**: `autoIndexDataAccess` writes per-page indexability recommendations and the aggregated analysis results to `continuumLpapiPrimaryPostgres`
   - From: `autoIndexDataAccess`
   - To: `continuumLpapiPrimaryPostgres`
   - Protocol: JDBC

8. **Closes job record**: `autoIndexScheduler` updates the job record status to `completed` or `failed`
   - From: `autoIndexScheduler`
   - To: `autoIndexDataAccess` -> `continuumLpapiPrimaryPostgres`
   - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| RAPI unavailable | `autoIndexAnalyzer` skips deal signals for affected pages | Pages analyzed without RAPI signals; conservative index recommendation |
| GSC unavailable | `autoIndexGscCollector` skips metric collection | Pages analyzed without GSC data; GSC step is optional |
| Routing service unavailable | `autoIndexCrawler` skips page crawl for affected URLs | Pages analyzed without rendered content |
| DB write failure | Job record updated to `failed` status | Analysis results not persisted; job can be re-triggered |
| Job already running | `autoIndexScheduler` prevents concurrent execution | New trigger rejected until current job completes |

## Sequence Diagram

```
appAutoIndexCoordinator -> autoIndexScheduler: trigger analysis run
autoIndexScheduler -> autoIndexDataAccess: create job record (status=running)
autoIndexDataAccess -> continuumLpapiPrimaryPostgres: INSERT job record
autoIndexDataAccess -> continuumLpapiReadOnlyPostgres: SELECT candidate pages/routes
autoIndexCrawler -> RoutingService: GET rendered page HTML (per page)
autoIndexAnalyzer -> continuumRelevanceApi: query deal cards for page route context
autoIndexGscCollector -> GoogleSearchConsole: fetch search performance metrics (optional)
autoIndexAnalyzer --> autoIndexScheduler: analysis results per page
autoIndexScheduler -> autoIndexDataAccess: persist results and recommendations
autoIndexDataAccess -> continuumLpapiPrimaryPostgres: INSERT/UPDATE results
autoIndexScheduler -> autoIndexDataAccess: update job record (status=completed)
autoIndexDataAccess -> continuumLpapiPrimaryPostgres: UPDATE job record
```

## Related

- Architecture dynamic view: `dynamic-autoIndexFlow`
- Architecture component view: `lpapiAutoIndexerComponents`
- Related flows: [Landing Page CRUD](landing-page-crud.md), [Route Resolution and URL Mapping](route-resolution-and-url-mapping.md)
