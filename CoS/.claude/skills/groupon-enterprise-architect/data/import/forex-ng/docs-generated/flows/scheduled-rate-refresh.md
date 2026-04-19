---
service: "forex-ng"
title: "Scheduled Rate Refresh"
generated: "2026-03-03"
type: flow
flow_name: "scheduled-rate-refresh"
flow_type: scheduled
trigger: "Kubernetes cron job on schedule */11 * * * * or Quartz cron 0 */5 * * * ?"
participants:
  - "continuumForexService_exchangeRatesUpdaterJob"
  - "continuumForexService_forexService"
  - "continuumForexService_netsuiteDataProvider"
  - "continuumForexNetsuiteApi"
  - "continuumForexService_rateStoreAdapter"
  - "continuumForexService_s3StorageClient"
  - "continuumForexS3Bucket"
architecture_ref: "dynamic-forex-refresh-rates"
---

# Scheduled Rate Refresh

## Summary

On a scheduled basis, Forex NG fetches the latest currency exchange rates for all 46 configured ISO 4217 currencies from the NetSuite exchange-rate API and publishes validated rate JSON files to AWS S3. In cloud production, this is triggered by a Kubernetes cron job running the `refresh-rates` CLI command every 11 minutes. In environments where the in-process Quartz scheduler is active (e.g., some development/production legacy configurations), the `ExchangeRatesUpdaterJob` triggers the same `refreshRates()` logic on a `0 */5 * * * ?` cron expression. The full flow includes NetSuite data fetching, CSV parsing, sanity validation on a staging area, and atomic promotion to the live S3 directory.

## Trigger

- **Type**: schedule
- **Source**: Kubernetes cron job (`JTIER_RUN_CMD=refresh-rates`; schedule `*/11 * * * *`) or Quartz scheduler (`ExchangeRatesUpdaterJob`; cron `0 */5 * * * ?`)
- **Frequency**: Every 11 minutes (Kubernetes cron job in production cloud)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kubernetes Cron Job / Quartz Scheduler | Triggers the rate refresh execution | External scheduler |
| Exchange Rates Updater Job | Quartz job that calls `ForexService.refreshRates()` | `continuumForexService_exchangeRatesUpdaterJob` |
| Forex Service | Orchestrates the full refresh: fetch, transform, persist | `continuumForexService_forexService` |
| NetSuite Data Provider | Fetches raw CSV rate data from NetSuite concurrently per currency | `continuumForexService_netsuiteDataProvider` |
| NetSuite Exchange Rates API | External source of daily exchange rate data | `continuumForexNetsuiteApi` |
| Rate Store Adapter | Routes storage operations to the S3 implementation | `continuumForexService_rateStoreAdapter` |
| AWS S3 Storage Client | Executes async S3 write, copy, delete operations | `continuumForexService_s3StorageClient` |
| Forex Rates S3 Bucket | Stores rate JSON files in `tmp_rates/` and `v1/rates/` | `continuumForexS3Bucket` |

## Steps

1. **Cron trigger fires**: The Kubernetes cron job creates a new pod running `java -jar forex.jar refresh-rates /path/to/config.yml`, or the Quartz scheduler executes `ExchangeRatesUpdaterJob.execute()`.
   - From: Kubernetes scheduler / Quartz
   - To: `continuumForexService_exchangeRatesUpdaterJob` (or `RefreshRatesCommand`)
   - Protocol: Schedule

2. **Invoke rate refresh**: The job calls `ForexService.refreshRates()`.
   - From: `continuumForexService_exchangeRatesUpdaterJob`
   - To: `continuumForexService_forexService`
   - Protocol: Direct (Java)

3. **Fetch data from NetSuite**: `ForexServiceImpl` calls `NetsuiteDataProvider.getData()`, which iterates over all configured currencies (46 in production) and issues concurrent async HTTP requests to the NetSuite scriptlet endpoint (`GET /app/site/hosting/scriptlet.nl?StartDate={today}&EndDate={today}&BaseCurrency={code}&...`). Requests are batched in groups of `concurrentFreq` (10 in production) using `CompletableFuture.allOf`.
   - From: `continuumForexService_netsuiteDataProvider`
   - To: `continuumForexNetsuiteApi`
   - Protocol: HTTPS (Retrofit)

4. **Validate NetSuite response**: For each currency response, `validateNetsuiteData()` checks HTTP status is 200, body is non-null/non-empty, and the CSV header matches `Base Currency,Target Currency,Exchange Rate,Effective Date`. Non-200 responses cause a `NetsuiteCallFailedException` for that currency; the currency is added to the `failedCurrency` list for retry.

5. **Parse CSV rows**: `getRatesFromResponse()` splits CSV rows, validates base currency matches, converts effective date to Unix epoch seconds, and builds a `Map<quoteCurrency, [rate, epochTime]>`. Currency pairs where base equals quote, or the quote is not in the configured currency list, are skipped.

6. **Retry failed currencies**: Any currencies in `failedCurrency` are retried up to `maxRetryCount` (2) times. If retries are exhausted, a `DataProviderException` is thrown and the refresh aborts.

7. **Transform to ForexRate model**: `ForexHelper.transform()` converts the raw map into a `Map<baseCurrency, ForexRate>` where each `ForexRate` is an immutable value object with `base`, `rates` (SortedMap), `timestamps` (SortedMap), `source`, and a derived `timestamp` (minimum per-quote epoch).
   - From: `continuumForexService_forexService`
   - To: (in-process transformation)
   - Protocol: Direct

8. **Update conversion rates in S3**: `AWSS3ForexStore.updateConversionRates()` is called with the transformed `Map<currency, ForexRate>`. See [Rate Refresh with Sanity Check](rate-refresh-sanity.md) for the detailed S3 staging and promotion steps.
   - From: `continuumForexService_forexService`
   - To: `continuumForexService_rateStoreAdapter` → `continuumForexService_s3StorageClient` → `continuumForexS3Bucket`
   - Protocol: AWS SDK v2 (HTTPS)

9. **Job completes**: On success the cron job pod exits with code 0. On any exception, it exits with code 1.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| NetSuite returns non-200 for a currency | `NetsuiteCallFailedException` thrown; currency added to retry list | Currency is retried up to `maxRetryCount` (2) times |
| All retries for a currency exhausted | `DataProviderException` thrown | Entire refresh job aborts; no partial rates are published |
| Unexpected exception from NetSuite (non-NetsuiteCallFailed) | `netsuiteCallSuccess` flag set to false | `DataProviderException` thrown; refresh aborts |
| `SanityFailedException` during S3 sanity check | Exception propagates from `AWSS3ForexStore` | Refresh aborts; `v1/rates/` retains previous contents; `tmp_rates/` is cleaned up in `finally` |
| S3 write failure after all retries | Returns `false` from `writeData()`; logged as error | Refresh aborts; `tmp_rates/` cleanup still attempted |

## Sequence Diagram

```
Scheduler -> ExchangeRatesUpdaterJob: execute()
ExchangeRatesUpdaterJob -> ForexServiceImpl: refreshRates()
ForexServiceImpl -> NetsuiteDataProvider: getData()
loop for each currency batch (concurrentFreq=10)
  NetsuiteDataProvider -> NetsuiteAPI: GET /scriptlet.nl?BaseCurrency={code}&...
  NetsuiteAPI --> NetsuiteDataProvider: CSV rows
  NetsuiteDataProvider -> NetsuiteDataProvider: validate + parse rows
end
ForexServiceImpl -> ForexServiceImpl: ForexHelper.transform(rawRates)
ForexServiceImpl -> AWSS3ForexStore: updateConversionRates(forexRateMap)
AWSS3ForexStore -> S3Client: putObject(tmp_rates/{currency}.json) x46
S3Client --> AWSS3ForexStore: success
AWSS3ForexStore -> AWSS3Sanity: doSanity(tmp_rates/)
AWSS3Sanity -> S3Client: getObject(tmp_rates/{sanityCurrency}.json) x5
AWSS3ForexStore -> S3Client: copyObject(tmp_rates/ -> v1/rates/) x46
AWSS3ForexStore -> AWSS3Sanity: doSanity(v1/rates/)
AWSS3ForexStore -> S3Client: putObject(grpn/healthcheck)
AWSS3ForexStore -> S3Client: getObject(grpn/healthcheck)
AWSS3ForexStore -> S3Client: deleteObject(tmp_rates/{currency}.json) x46
```

## Related

- Architecture dynamic view: `dynamic-forex-refresh-rates`
- Related flows: [Rate Refresh with Sanity Check](rate-refresh-sanity.md), [Manual Rate Refresh (Admin)](manual-rate-refresh.md), [Rate Query](rate-query.md)
