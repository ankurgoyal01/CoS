---
service: "HotzoneGenerator"
title: "New Deal Hotzone Generation"
generated: "2026-03-03"
type: flow
flow_name: "new-deal-hotzone-generation"
flow_type: scheduled
trigger: "Runs within the daily hotzone generation job (22:00 UTC) as a sub-flow of config mode"
participants:
  - "continuumHotzoneGeneratorJob"
  - "continuumMarketingDealService"
architecture_ref: "dynamic-hotzoneGenerationFlow"
---

# New Deal Hotzone Generation

## Summary

As part of the main daily hotzone generation run, HotzoneGenerator queries MDS for all deals that started within the last 7 days (across each configured country) and creates `HOTZONE_NEWDEAL` type hotzones for them. This ensures that newly launched deals are immediately surfaced in the proximity notification system without waiting for a manually configured campaign. The new-deal hotzones use fixed defaults for radius (Things-to-Do: 3200 m) and time window (Food & Drink: every day 11AM–5PM).

## Trigger

- **Type**: schedule (sub-flow within the main daily job)
- **Source**: Invoked by `App.main()` during the `config` run mode execution, after config-based hotzones are processed
- **Frequency**: Daily at 22:00 UTC

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Hotzone Generator Job | Computes the 7-day lookback window and orchestrates the new-deal query and hotzone creation | `continuumHotzoneGeneratorJob` |
| Marketing Deal Service (MDS) | Returns deals with `start_after` date within the last 7 days | `continuumMarketingDealService` |
| Proximity Notifications API | Receives the batch of HOTZONE_NEWDEAL hotzones for insertion | stub |

## Steps

1. **Compute 7-day lookback date**: Calculates `sevenDaysBefore` as today minus 7 days, formatted as `yyyy-MM-dd`.
   - From: `continuumHotzoneGeneratorJob` (App.generateNewDealHotzones)
   - To: In-process
   - Protocol: direct

2. **Fetch new deals from MDS (per country)**: For each country in `CountryCode`, sends up to 5 paginated `GET deals.json?country={country}&size=5000&channel={channel}&start_after={sevenDaysBefore}&client={mds.clientId}&page={n}`. Stops early when a page is smaller than 5000 results.
   - From: `dealAggregationEngine`
   - To: `continuumMarketingDealService`
   - Protocol: HTTPS/JSON

3. **Build HOTZONE_NEWDEAL records**: For each deal and each valid redemption location (must have lat/lng and match the target country), creates a `HotZone` with:
   - `dealType = HOTZONE_NEWDEAL`
   - `sendType = PULL`
   - `audience_id = 0`
   - `audience_type = bcookie`
   - `cat = c09790ba-a6b9-40fc-ad81-4cdf25260b5e` (hardcoded Things-to-Do category)
   - `radius` from `radius.things-to-do` property (3200 m)
   - `dealTimeRange` from `timeRange.food-and-drink` property (every day 11AM–5PM)
   - `customer_taxonomy` from deal's own taxonomy field (or empty string if null)
   - `expires` capped at min(deal end/expire date, now + 7 days)
   - From: `dealAggregationEngine`
   - To: In-process
   - Protocol: direct

4. **Submit HOTZONE_NEWDEAL hotzones**: Included in the same bulk `POST hotzone?client_id=ec-team` call as config-based hotzones.
   - From: `proximitySyncClient`
   - To: Proximity Notifications API
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MDS returns no new deals for a country | Returns empty list; continues to next country | No new-deal hotzones for that country |
| Redemption location missing lat/lng | Logs info and skips that location | Fewer hotzones for that deal |
| Redemption location in wrong country | Logs info and skips that location | Fewer hotzones for that deal |
| Exception building a hotzone record | Stack trace printed; that location skipped | Fewer hotzones |

## Sequence Diagram

```
continuumHotzoneGeneratorJob -> continuumHotzoneGeneratorJob: Compute 7-day lookback date
loop for each country in CountryCode
  continuumHotzoneGeneratorJob -> continuumMarketingDealService: GET deals.json?start_after={date}&country={country}
  continuumMarketingDealService --> continuumHotzoneGeneratorJob: New deal list
  continuumHotzoneGeneratorJob -> continuumHotzoneGeneratorJob: Build HOTZONE_NEWDEAL records per redemption location
end
continuumHotzoneGeneratorJob -> ProximityAPI: POST hotzone (included in main bulk insert)
```

## Related

- Architecture dynamic view: `dynamic-hotzoneGenerationFlow`
- Related flows: [Hotzone Generation (Config Mode)](hotzone-generation.md)
