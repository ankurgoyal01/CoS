---
service: "forex-ng"
title: "Manual Rate Refresh (Admin)"
generated: "2026-03-03"
type: flow
flow_name: "manual-rate-refresh"
flow_type: synchronous
trigger: "GET /v1/rates/data HTTP request or refresh-rates CLI command"
participants:
  - "continuumForexService_ratesApiResource"
  - "continuumForexService_forexService"
  - "continuumForexService_netsuiteDataProvider"
  - "continuumForexNetsuiteApi"
  - "continuumForexService_rateStoreAdapter"
  - "continuumForexService_s3StorageClient"
  - "continuumForexS3Bucket"
architecture_ref: "dynamic-forex-refresh-rates"
---

# Manual Rate Refresh (Admin)

## Summary

An operator or admin caller can trigger an immediate on-demand refresh of all forex rates through two mechanisms: the HTTP admin endpoint `GET /v1/rates/data` on the running service, or the Dropwizard CLI command `refresh-rates` executed directly against the packaged JAR. Both entry points invoke the same `ForexService.refreshRates()` logic as the scheduled refresh, but are initiated synchronously rather than by the scheduler. The CLI `refresh-rates` command is also the mechanism used by the Kubernetes cron job.

## Trigger

- **Type**: api-call (for `/v1/rates/data`) or manual (for CLI `refresh-rates`)
- **Source**: Operator via HTTP or command line; Kubernetes cron job (via `JTIER_RUN_CMD=refresh-rates`)
- **Frequency**: On-demand or per Kubernetes cron schedule

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator / Cron Job | Initiates the refresh | External |
| Rates API Resource | Receives `GET /v1/rates/data` and invokes `refreshRates()` | `continuumForexService_ratesApiResource` |
| RefreshRatesCommand (CLI) | Dropwizard command that bootstraps the environment and invokes `refreshRates()` | `continuumForexService_exchangeRatesUpdaterJob` (CLI variant) |
| Forex Service | Orchestrates fetch, transform, and store operations | `continuumForexService_forexService` |
| NetSuite Data Provider | Calls NetSuite API for all configured currencies | `continuumForexService_netsuiteDataProvider` |
| NetSuite Exchange Rates API | Returns CSV exchange rate data | `continuumForexNetsuiteApi` |
| Rate Store Adapter | Routes to S3 store in production | `continuumForexService_rateStoreAdapter` |
| AWS S3 Storage Client | Executes async S3 operations | `continuumForexService_s3StorageClient` |
| Forex Rates S3 Bucket | Stores updated rate JSON files | `continuumForexS3Bucket` |

## Steps

### Path A: HTTP Admin Endpoint

1. **Receive HTTP request**: Operator calls `GET /v1/rates/data` on the running HTTP service.
   - From: Operator
   - To: `continuumForexService_ratesApiResource` (`ForexResource.refreshData()`)
   - Protocol: HTTP

2. **Invoke refreshRates()**: `ForexResource.refreshData()` calls `forexSvc.refreshRates()`.
   - From: `continuumForexService_ratesApiResource`
   - To: `continuumForexService_forexService`
   - Protocol: Direct (Java)

3. **Execute full rate refresh**: Same steps 3–9 as [Scheduled Rate Refresh](scheduled-rate-refresh.md) — fetch from NetSuite, transform, write to S3 with sanity checks.

4. **Return response**: On success, returns `HTTP 200` with entity `"OK"` (text/html). On any exception, returns `HTTP 500` with the exception message.
   - From: `continuumForexService_ratesApiResource`
   - To: Operator
   - Protocol: HTTP

### Path B: CLI Command (`refresh-rates`)

1. **Start JVM process**: Kubernetes cron job or operator runs `java -jar forex.jar refresh-rates /path/to/config.yml`.
   - From: Kubernetes cron job / Operator
   - To: `RefreshRatesCommand`
   - Protocol: OS process

2. **Bootstrap environment**: `RefreshRatesCommand.run()` initializes the Dropwizard `Environment` (metrics, lifecycle, server factory), registers the Retrofit `NetsuiteRetroClient` bundle, calls `bootstrap.run()`, and registers `NetsuiteDataProvider`.

3. **Invoke refreshRates()**: Calls `ForexService.refreshRates()` using the bootstrapped service instance. Logs start time.

4. **Execute full rate refresh**: Same steps 3–9 as [Scheduled Rate Refresh](scheduled-rate-refresh.md).

5. **Log completion time**: Logs `"Successfully refreshed forex rates in the store"` with `time_taken_in_secs`.

6. **Exit with status code**: Calls `ForexHelper.exit(0)` on success or `ForexHelper.exit(1)` on exception. The Kubernetes cron job uses this exit code to determine success/failure.
   - From: `RefreshRatesCommand`
   - To: OS process exit
   - Protocol: JVM exit code

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Exception during refresh via HTTP endpoint | Caught in `refreshData()`; returns HTTP 500 with exception message | Operator receives 500; no partial rates published |
| Exception during CLI refresh | Caught in `RefreshRatesCommand.run()`; logged; `ForexHelper.exit(1)` called | Kubernetes marks the cron job run as failed; alerts may fire |
| NetSuite data fetch failure | Same as scheduled refresh — retry logic applies | Refresh aborts; existing rates preserved |
| S3 sanity check failure | `SanityFailedException` propagates | Refresh aborts; operator must investigate |

## Sequence Diagram

```
[HTTP Path]
Operator -> ForexResource: GET /v1/rates/data
ForexResource -> ForexServiceImpl: refreshRates()
ForexServiceImpl -> NetsuiteDataProvider: getData() [all currencies]
NetsuiteDataProvider -> NetsuiteAPI: GET /scriptlet.nl x46
NetsuiteAPI --> NetsuiteDataProvider: CSV rows
ForexServiceImpl -> AWSS3ForexStore: updateConversionRates(forexRateMap)
AWSS3ForexStore -> S3Bucket: write/sanity/copy/sanity/healthcheck/delete
ForexResource --> Operator: HTTP 200 "OK"

[CLI Path]
CronJob -> RefreshRatesCommand: java -jar forex.jar refresh-rates config.yml
RefreshRatesCommand -> RefreshRatesCommand: bootstrap environment
RefreshRatesCommand -> ForexServiceImpl: refreshRates()
ForexServiceImpl -> NetsuiteDataProvider: getData() [all currencies]
NetsuiteDataProvider -> NetsuiteAPI: GET /scriptlet.nl x46
ForexServiceImpl -> AWSS3ForexStore: updateConversionRates(forexRateMap)
AWSS3ForexStore -> S3Bucket: write/sanity/copy/sanity/healthcheck/delete
RefreshRatesCommand -> OS: exit(0)
```

## Related

- Architecture dynamic view: `dynamic-forex-refresh-rates`
- Related flows: [Scheduled Rate Refresh](scheduled-rate-refresh.md), [Rate Refresh with Sanity Check](rate-refresh-sanity.md), [Rate Query](rate-query.md)
