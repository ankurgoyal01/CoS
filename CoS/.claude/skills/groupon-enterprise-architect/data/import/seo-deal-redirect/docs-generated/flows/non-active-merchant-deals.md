---
service: "seo-deal-redirect"
title: "Non-Active Merchant Deals"
generated: "2026-03-03"
type: flow
flow_name: "non-active-merchant-deals"
flow_type: batch
trigger: "Executed as a separate Dataproc PySpark job within the daily redirect pipeline DAG; schedule gated by croniter expressions (NA: 0 5 9 * *, INTL: 0 5 1 * *)"
participants:
  - "continuumSeoDealRedirectJobs"
  - "continuumSeoHiveWarehouse"
  - "gcpCloudStorage"
  - "seoDealApi"
architecture_ref: "components-seoDealRedirectJobs"
---

# Non-Active Merchant Deals

## Summary

The non-active merchant deals job handles a specific redirect scenario: deals from merchants who have **no currently active deals on Groupon at all**. For these deals, the standard expired-to-live algorithm finds no match (because there are no launched deals from the same merchant). This PySpark job identifies such deals, enriches them with customer-facing taxonomy data and LPAPI location data to construct a relevant category browse page URL, and publishes the redirect to the SEO Deal API. It runs on a separate schedule (NA on the 9th, INTL on the 1st of each month) gated by `croniter` within the same DAG.

## Trigger

- **Type**: schedule (cron-gated within the DAG run)
- **Source**: Airflow DAG task `find_non_active_merchant_deals`; internal schedule check via `croniter`
  - NA schedule: `0 5 9 * *` (9th of month)
  - INTL schedule: `0 5 1 * *` (1st of month)
- **Frequency**: Monthly per region, within the [Daily Redirect Pipeline](daily-redirect-pipeline.md)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Non-Active Merchant Deals Job | Main PySpark job — loads deals, identifies non-active merchants, enriches, generates redirects | `nonActiveMerchantDealsJob` (component of `continuumSeoDealRedirectJobs`) |
| SEO Hive Warehouse | Source for `daily_deals` and `pds_blacklist`; destination for audit table | `continuumSeoHiveWarehouse` |
| GCP Cloud Storage | Provides LPAPI location Parquet and taxonomy Parquet reference files | `gcpCloudStorage` (stub) |
| SEO Deal API | Receives redirect URL updates | `seoDealApi` (stub) |

## Steps

1. **Check schedule**: Uses `croniter` to evaluate whether the current `run_date` matches the NA or INTL cron expression. Exits gracefully if neither schedule matches.
   - From: `nonActiveMerchantDealsJob`
   - To: local `croniter` evaluation
   - Protocol: Python

2. **Load daily deals**: Reads `grp_gdoop_seo_db.daily_deals` for the target country codes (`country_codes_na` = `["us"]`; `country_codes_intl` = `["ie","uk","gb","fr","es","nl","pl","de","au","ae"]`).
   - From: `nonActiveMerchantDealsJob`
   - To: `continuumSeoHiveWarehouse`
   - Protocol: Spark SQL

3. **Filter PDS blacklist**: Removes deals whose `pds_cat_id` is in `grp_gdoop_seo_db.pds_blacklist`.
   - From: `nonActiveMerchantDealsJob`
   - To: `continuumSeoHiveWarehouse`
   - Protocol: Spark SQL JOIN

4. **Identify non-active merchants**: Splits `daily_deals` into:
   - Active merchants: all merchants where at least one deal has `is_live = true`
   - Non-active merchant deals: deals where the `merchant_id` does NOT appear in the active merchants set
   - Implemented via a LEFT ANTI JOIN on `merchant_id`
   - From: `nonActiveMerchantDealsJob`
   - To: local Spark DataFrame operation
   - Protocol: PySpark

5. **Deduplicate by deal permalink**: Groups by `deal_permalink` to handle deals with multiple redemption locations. Keeps one `deal_uuid` per permalink (lexicographically first) and adds a flag `has_multiple_redemption_locations`.
   - From: `nonActiveMerchantDealsJob`
   - To: local Spark window function
   - Protocol: PySpark with Window function

6. **Enrich with taxonomy data**: Joins with merchant-to-customer taxonomy lookup (Parquet at `merchant_to_customer_lookup_parquet_path`) and customer taxonomy data (Parquet at `customer_taxonomy_parquet_path`). Adds a list of potential category browse page permalinks per deal.
   - From: `nonActiveMerchantDealsJob`
   - To: `gcpCloudStorage` (reads Parquet)
   - Protocol: Spark `read.parquet()` + JOIN

7. **Enrich with LPAPI location data**: Reads LPAPI localized location Parquet (`lpapi_location_data_path`). For each deal with a lat/lng, pre-filters LPAPI locations using a bounding box, then calculates Haversine distance via UDF, and uses a Window function to select the closest LPAPI location within `lpapi_search_radius_km` (25 km).
   - From: `nonActiveMerchantDealsJob`
   - To: `gcpCloudStorage` (reads Parquet)
   - Protocol: Spark `read.parquet()` + UDF + Window

8. **Construct redirect URL**: Builds the `redirect_to` URL using the matched LPAPI location and the localized taxonomy category permalink. URL pattern: `https://www.groupon.{tld}/{localized_page}/{location_slug}/{category_slug}`. Country-to-locale and country-to-TLD mappings are applied.
   - From: `nonActiveMerchantDealsJob`
   - To: local Spark UDF
   - Protocol: PySpark UDF

9. **Submit redirects to SEO Deal API**: For each deal (if `dry_run = false`), makes a rate-limited HTTPS PUT request to:
   `{api_host}/seodeals/deals/{deal_uuid}/edits/attributes/redirectUrl?source=seo-deal-redirect-non-active-merchant`
   Rate limit: 1,250 calls per 60 seconds.
   - From: `nonActiveMerchantDealsJob`
   - To: `seoDealApi`
   - Protocol: HTTPS PUT with mTLS

10. **Save audit results**: Writes all processed deal redirect results to `grp_gdoop_seo_db.processed_non_active_merchant_redirects` for auditing and future analysis.
    - From: `nonActiveMerchantDealsJob`
    - To: `continuumSeoHiveWarehouse`
    - Protocol: Spark `write.saveAsTable()`

11. **Collect results to driver**: Collects the final DataFrame to the Spark driver node for potential emailing to the team.
    - From: `nonActiveMerchantDealsJob`
    - To: local driver (Airflow EmailOperator)
    - Protocol: PySpark collect()

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Schedule does not match current run date | Job exits gracefully with a log message | No deals are processed; no API calls made |
| `dry_run = true` | API calls are skipped; results are still collected and saved to audit table | Used for testing; no production changes |
| No LPAPI location found within 25 km | Deal is still processed but redirect URL uses a non-location-specific category URL | Redirect goes to a category browse page without location specificity |
| API PUT returns non-200 | Error logged per deal; job continues | That deal's redirect is not updated |
| `pds_blacklist` join removes all deals | Empty result; no API calls | No redirects published for the run |

## Sequence Diagram

```
nonActiveMerchantDealsJob -> nonActiveMerchantDealsJob: Check croniter schedule (NA/INTL)
nonActiveMerchantDealsJob -> continuumSeoHiveWarehouse: Load daily_deals for target country codes
nonActiveMerchantDealsJob -> continuumSeoHiveWarehouse: Filter against pds_blacklist
nonActiveMerchantDealsJob -> nonActiveMerchantDealsJob: Identify merchants with no active deals (LEFT ANTI JOIN)
nonActiveMerchantDealsJob -> nonActiveMerchantDealsJob: Deduplicate by deal_permalink, flag multi-location deals
nonActiveMerchantDealsJob -> gcpCloudStorage: Read merchant-to-customer taxonomy Parquet
nonActiveMerchantDealsJob -> gcpCloudStorage: Read customer taxonomy Parquet
nonActiveMerchantDealsJob -> nonActiveMerchantDealsJob: Enrich with category permalink candidates
nonActiveMerchantDealsJob -> gcpCloudStorage: Read LPAPI location Parquet
nonActiveMerchantDealsJob -> nonActiveMerchantDealsJob: Bounding box pre-filter + Haversine UDF + Window (closest location)
nonActiveMerchantDealsJob -> nonActiveMerchantDealsJob: Construct redirect_to URL (TLD + locale + location + category)
loop [for each deal, rate-limited 1250/60s, if dry_run=false]
  nonActiveMerchantDealsJob -> seoDealApi: PUT /seodeals/deals/{uuid}/edits/attributes/redirectUrl?source=seo-deal-redirect-non-active-merchant
  seoDealApi --> nonActiveMerchantDealsJob: HTTP 200
end
nonActiveMerchantDealsJob -> continuumSeoHiveWarehouse: Save to processed_non_active_merchant_redirects (audit)
```

## Related

- Parent flow: [Daily Redirect Pipeline](daily-redirect-pipeline.md)
- Supplementary documentation: `docs/non_active_merchant_deals/overview.md`, `docs/non_active_merchant_deals/find_non_active_merchant_deals.md`
- Architecture ref: `nonActiveMerchantDealsJob` component within `continuumSeoDealRedirectJobs`
- API endpoint: `PUT /seodeals/deals/{deal_uuid}/edits/attributes/redirectUrl?source=seo-deal-redirect-non-active-merchant` (see [API Surface](../api-surface.md))
