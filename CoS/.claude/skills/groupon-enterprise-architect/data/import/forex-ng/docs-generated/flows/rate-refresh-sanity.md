---
service: "forex-ng"
title: "Rate Refresh with Sanity Check"
generated: "2026-03-03"
type: flow
flow_name: "rate-refresh-sanity"
flow_type: batch
trigger: "Called within rate refresh flow after NetSuite data fetch and transformation"
participants:
  - "continuumForexService_rateStoreAdapter"
  - "continuumForexService_s3StorageClient"
  - "continuumForexS3Bucket"
architecture_ref: "dynamic-forex-refresh-rates"
---

# Rate Refresh with Sanity Check

## Summary

After fetching and transforming exchange rate data from NetSuite, Forex NG uses a multi-step staged write process to safely update the live S3 rate files. New rate files are first written to a temporary directory (`tmp_rates/`) in S3. A sanity check validates the staged files for a subset of configured currencies before they are promoted to the live directory (`v1/rates/`). A second sanity check validates the live directory after promotion. Finally, a health check sentinel file is written and read back to verify end-to-end S3 read/write connectivity. Temporary files are always deleted in a `finally` block, regardless of outcome.

## Trigger

- **Type**: api-call (internal — called by `ForexServiceImpl.refreshRates()` via `AWSS3ForexStore.updateConversionRates()`)
- **Source**: Scheduled rate refresh or manual rate refresh
- **Frequency**: Same as the triggering refresh; every 11 minutes in production

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Rate Store Adapter (AWSS3ForexStore) | Orchestrates the staged write, sanity check, and promotion steps | `continuumForexService_rateStoreAdapter` |
| AWSS3Sanity | Validates a sample of rate files for correctness and freshness | Internal component (part of `continuumForexService`) |
| AWS S3 Storage Client (AWSS3Client) | Executes all async S3 operations (put, get, copy, delete) | `continuumForexService_s3StorageClient` |
| Forex Rates S3 Bucket | Stores rate JSON files in `tmp_rates/` and `v1/rates/` directories | `continuumForexS3Bucket` |

## Steps

1. **Write all rate files to staging area**: `AWSS3ForexStore.uploadTo()` serializes each `ForexRate` as a JSON string and calls `AWSS3Client.writeData()`. This issues async `PutObject` requests to `tmp_rates/{currency}.json` for all currencies. Up to 50 concurrent S3 operations are batched. Failed writes are retried up to 2 times.
   - From: `continuumForexService_rateStoreAdapter`
   - To: `continuumForexS3Bucket` (path: `tmp_rates/`)
   - Protocol: AWS SDK v2 (HTTPS)

2. **Sanity check on staging area**: `AWSS3Sanity.doSanity("tmp_rates/")` reads the JSON file for each currency in the `sanityCurrencies` list (default: USDCAD, USDEUR, CADUSD, EURUSD, USD) from `tmp_rates/` and performs three validation checks per file:
   - For single currencies (3 chars): `base` field matches the code; `rates` map has `currencies.size() - 1` entries; `timestamp != 0`; `source != null`; `timestamps` map has `currencies.size() - 1` entries.
   - For currency pairs (6 chars): `base` matches the first 3 chars; the `rates` map contains the target currency; `timestamp != 0`; `source != null`.
   - Freshness check: `timestamp` is not older than 24 hours (`NO_OF_SECS_IN_DAY = 86400` seconds).
   - From: `continuumForexService_rateStoreAdapter`
   - To: `continuumForexS3Bucket` (read from `tmp_rates/`)
   - Protocol: AWS SDK v2 (HTTPS)

3. **Promote staged files to live directory**: On sanity pass, `AWSS3ForexStore.copy()` calls `AWSS3Client.copy()` which issues async `CopyObject` requests to copy each `tmp_rates/{currency}.json` → `v1/rates/{currency}.json`. Up to 50 concurrent operations. Failed copies are retried up to 2 times.
   - From: `continuumForexService_rateStoreAdapter`
   - To: `continuumForexS3Bucket` (copy from `tmp_rates/` to `v1/rates/`)
   - Protocol: AWS SDK v2 (HTTPS)

4. **Sanity check on live directory**: `AWSS3Sanity.doSanity("v1/rates/")` repeats the same validation steps against the newly promoted files in `v1/rates/`. This confirms the copy was successful and the live data is valid.
   - From: `continuumForexService_rateStoreAdapter`
   - To: `continuumForexS3Bucket` (read from `v1/rates/`)
   - Protocol: AWS SDK v2 (HTTPS)

5. **Write and verify health check sentinel**: `AWSS3ForexStore.addHealthCheck()` writes the string `"OK"` to `grpn/healthcheck` in the S3 bucket, then immediately reads it back. If the read-back value does not equal `"OK"`, a `SanityFailedException` is thrown.
   - From: `continuumForexService_s3StorageClient`
   - To: `continuumForexS3Bucket` (write then read `grpn/healthcheck`)
   - Protocol: AWS SDK v2 (HTTPS)

6. **Delete temporary files** (always, in `finally` block): `AWSS3ForexStore.deleteFrom()` calls `AWSS3Client.delete()` to remove all `tmp_rates/{currency}.json` files. Failed deletions are retried up to 2 times. Failures are logged as errors but do not prevent the overall refresh from being considered complete.
   - From: `continuumForexService_s3StorageClient`
   - To: `continuumForexS3Bucket` (delete from `tmp_rates/`)
   - Protocol: AWS SDK v2 (HTTPS)

7. **Close S3 client**: `AWSS3Client.close()` is called in the outer `finally` block, closing the `S3AsyncClient` and setting the instance to `null` so a fresh client is created on the next invocation.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| S3 write to `tmp_rates/` fails after all retries | `uploadTo()` returns false; error logged; method returns false | Refresh aborts before promotion; `v1/rates/` unchanged; `tmp_rates/` cleanup runs in `finally` |
| Sanity check fails on `tmp_rates/` | `SanityFailedException` thrown | Refresh aborts; `v1/rates/` unchanged; `tmp_rates/` cleanup runs in `finally` |
| S3 copy from `tmp_rates/` to `v1/rates/` fails | `copy()` returns -1; error logged; method returns false | Partial copy may exist in `v1/rates/`; consumer may see stale/mixed data; `tmp_rates/` cleanup runs |
| Sanity check fails on `v1/rates/` | `SanityFailedException` thrown | Rate files may be partially corrupted in `v1/rates/`; requires manual investigation |
| Health check sentinel write or read fails | `SanityFailedException` thrown | S3 connectivity issue; alert and investigate IAM / bucket access |
| `tmp_rates/` cleanup fails | Error logged; no exception re-thrown | Stale temp files remain in S3; does not block future refreshes |

## Sequence Diagram

```
AWSS3ForexStore -> AWSS3Client: writeData(tmp_rates/{currency}.json x46)
AWSS3Client -> S3Bucket: PutObject x46 (batched, up to 50 concurrent)
S3Bucket --> AWSS3Client: success
AWSS3ForexStore -> AWSS3Sanity: doSanity("tmp_rates/")
loop for each sanityCurrency (USDCAD, USDEUR, CADUSD, EURUSD, USD)
  AWSS3Sanity -> AWSS3Client: read("tmp_rates/{currency}.json")
  AWSS3Client -> S3Bucket: GetObject
  S3Bucket --> AWSS3Client: JSON
  AWSS3Sanity -> AWSS3Sanity: checkCurrency/checkCurrencyCombination/checkLastDataSyncDate
end
AWSS3ForexStore -> AWSS3Client: copy(tmp_rates/ -> v1/rates/ x46)
AWSS3Client -> S3Bucket: CopyObject x46 (batched)
S3Bucket --> AWSS3Client: success
AWSS3ForexStore -> AWSS3Sanity: doSanity("v1/rates/")
AWSS3ForexStore -> AWSS3Client: writeData(grpn/healthcheck = "OK")
AWSS3ForexStore -> AWSS3Client: read(grpn/healthcheck) -> assert "OK"
AWSS3ForexStore -> AWSS3Client: delete(tmp_rates/{currency}.json x46) [finally]
AWSS3Client -> AWSS3Client: close() [finally]
```

## Related

- Architecture dynamic view: `dynamic-forex-refresh-rates`
- Related flows: [Scheduled Rate Refresh](scheduled-rate-refresh.md), [Manual Rate Refresh (Admin)](manual-rate-refresh.md)
