---
service: "HotzoneGenerator"
title: "Hotzone Generation (Config Mode)"
generated: "2026-03-03"
type: flow
flow_name: "hotzone-generation"
flow_type: scheduled
trigger: "Daily cron at 22:00 UTC on NA and EMEA production hosts"
participants:
  - "continuumHotzoneGeneratorJob"
  - "continuumMarketingDealService"
  - "continuumTaxonomyService"
  - "continuumDealCatalogService"
  - "apiProxy"
architecture_ref: "dynamic-hotzoneGenerationFlow"
---

# Hotzone Generation (Config Mode)

## Summary

The main hotzone generation flow executes in `config` run mode (the default). It reads all active hotzone campaign configurations from the Proximity Notifications API, fetches qualifying deals from MDS for each configuration, enriches each deal's redemption locations with open-hours data and inventory product IDs, applies population-density radius adjustments, and submits the resulting hotzones in bulk to the Proximity Notifications API. A separate pass generates `HOTZONE_NEWDEAL` type hotzones for deals launched in the last 7 days.

## Trigger

- **Type**: schedule
- **Source**: cron job on the production VM (`cron/na/HotzoneGenerator.cron` and `cron/emea/HotzoneGenerator.cron`)
- **Frequency**: daily at 22:00 UTC

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Hotzone Generator Job | Orchestrates the entire flow; entry point is `App.main()` | `continuumHotzoneGeneratorJob` |
| Proximity Notifications API | Provides campaign configurations; receives generated hotzones | stub (not in federated model) |
| Marketing Deal Service (MDS) | Provides filtered deal datasets per category and country | `continuumMarketingDealService` |
| Internal API Proxy (GAPI) | Provides merchant open-hours per redemption location | `apiProxy` |
| Deal Catalog Service | Provides inventory product IDs per deal | `continuumDealCatalogService` |

## Steps

1. **Clean up expired hotzones**: Sends `POST hotzone/delete-expired?client_id=ec-team` to the Proximity Notifications API. Logs the count of expired hotzones removed. Calls `System.exit(1)` on failure.
   - From: `continuumHotzoneGeneratorJob`
   - To: Proximity Notifications API
   - Protocol: HTTPS/JSON

2. **Delete stale send logs**: Sends `POST proximity/delete-send-log?client_id=ec-team` to the Proximity geofence URL. Logs deleted count.
   - From: `continuumHotzoneGeneratorJob`
   - To: Proximity Notifications API (geofence base URL)
   - Protocol: HTTPS/JSON

3. **Load active campaign configs**: Sends `GET hotzone/campaign?client_id=ec-team` and filters to only `active=true` configs. Validates all required fields; exits on invalid config.
   - From: `configAndScheduleManager`
   - To: Proximity Notifications API
   - Protocol: HTTPS/JSON

4. **Load division coefficients**: Reads the per-environment GConfig JSON resource from classpath (e.g., `gconfig/production.txt`) to get per-division population-density multipliers for radius adjustment.
   - From: `configAndScheduleManager`
   - To: Classpath resource
   - Protocol: In-process file read

5. **Fetch deals from MDS (per config)**: For each active config, sends up to 5 paginated `GET deals.json?country=...&size=5000&channel=g1&page=n&...` requests. Stops pagination when a page returns fewer than 5000 results.
   - From: `dealAggregationEngine`
   - To: `continuumMarketingDealService`
   - Protocol: HTTPS/JSON

6. **Filter deals by thresholds**: Applies `HotZoneDataFilter` to retain only deals meeting `priceThreshold`, `conversion` rate, and `purchaseNumber` minimums. Sorts in reverse conversion order if `isReverse=true`.
   - From: `dealAggregationEngine`
   - To: In-process filter
   - Protocol: direct

7. **Enrich with open hours (when `useOpenHours=true`)**: For each deal, calls `GET /v2/deals/{uuid}?show=options(redemptionLocations)&client_id=...` (US) or `GET /api/mobile/{country}/deals/{uuid}?...` (non-US) on the GAPI proxy. Merges returned open-hour windows with the config time window to produce the final `dealTimeRange`.
   - From: `dealAggregationEngine`
   - To: `apiProxy`
   - Protocol: HTTPS/JSON

8. **Fetch inventory product IDs**: For each valid deal, calls `GET deal_catalog/v2/deals/{uuid}` to retrieve inventory product IDs, stored as a comma-separated string in the hotzone payload.
   - From: `dealAggregationEngine`
   - To: `continuumDealCatalogService`
   - Protocol: HTTPS/JSON

9. **Build hotzone records**: Creates one `HotZone` object per qualifying redemption location. Applies division-coefficient radius adjustment for Restaurant taxonomy. Enforces a 7-day expiry cap. Deduplicates deals across configs using a `Set<UUID>`.
   - From: `dealAggregationEngine`
   - To: In-process
   - Protocol: direct

10. **Generate new-deal hotzones**: Queries MDS for deals with `start_after={7 days ago}` across all configured countries. Creates `HOTZONE_NEWDEAL` type hotzones using the Things-to-Do radius and Food & Drink time range as defaults.
    - From: `dealAggregationEngine`
    - To: `continuumMarketingDealService`
    - Protocol: HTTPS/JSON

11. **Submit hotzones to Proximity API**: Serialises all generated `HotzoneAPIDataFormat` objects into a `HotzonePost` wrapper and sends `POST hotzone?client_id=ec-team`. Logs `successCount` and `ofPossible` from the response. Calls `System.exit(1)` on failure.
    - From: `proximitySyncClient`
    - To: Proximity Notifications API
    - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Proximity API cleanup call fails | Logs error and calls `System.exit(1)` | Run aborts |
| Proximity API insert call fails | Logs error and calls `System.exit(1)` | Run aborts |
| MDS call fails for a country | Caught and logged; that country skipped | Degraded run; other countries continue |
| GAPI open-hours call fails | Exception silently caught; returns empty map | Deal's redemption location skipped when `useOpenHours=true` |
| Deal Catalog call fails | Exception printed as stack trace | Inventory product IDs missing for that deal |
| Config has null required fields | Logs error and calls `System.exit(-1)` | Run aborts before generation |
| Hotzone validation fails (null announcement title) | Logged at ERROR; that hotzone excluded from insert batch | Fewer hotzones submitted |

## Sequence Diagram

```
cron -> continuumHotzoneGeneratorJob: Invoke run_job (daily 22:00 UTC)
continuumHotzoneGeneratorJob -> ProximityAPI: POST hotzone/delete-expired
continuumHotzoneGeneratorJob -> ProximityAPI: POST proximity/delete-send-log
continuumHotzoneGeneratorJob -> ProximityAPI: GET hotzone/campaign
ProximityAPI --> continuumHotzoneGeneratorJob: Active campaign configs
continuumHotzoneGeneratorJob -> classPathResource: Read division coefficients
loop for each active config
  continuumHotzoneGeneratorJob -> continuumMarketingDealService: GET deals.json (paginated)
  continuumMarketingDealService --> continuumHotzoneGeneratorJob: Deal list
  continuumHotzoneGeneratorJob -> apiProxy: GET /v2/deals/{uuid}?show=options(redemptionLocations)
  apiProxy --> continuumHotzoneGeneratorJob: Open hours per redemption location
  continuumHotzoneGeneratorJob -> continuumDealCatalogService: GET deal_catalog/v2/deals/{uuid}
  continuumDealCatalogService --> continuumHotzoneGeneratorJob: Inventory product IDs
end
continuumHotzoneGeneratorJob -> continuumMarketingDealService: GET deals.json?start_after={7 days ago}
continuumMarketingDealService --> continuumHotzoneGeneratorJob: New deals
continuumHotzoneGeneratorJob -> ProximityAPI: POST hotzone (bulk insert)
ProximityAPI --> continuumHotzoneGeneratorJob: successCount / ofPossible
```

## Related

- Architecture dynamic view: `dynamic-hotzoneGenerationFlow`
- Related flows: [Auto Campaign Generation](auto-campaign-generation.md), [New Deal Hotzone Generation](new-deal-hotzone-generation.md), [Weekly Email Dispatch](weekly-email-dispatch.md)
