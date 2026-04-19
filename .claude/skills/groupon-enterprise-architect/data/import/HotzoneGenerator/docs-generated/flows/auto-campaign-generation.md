---
service: "HotzoneGenerator"
title: "Auto Campaign Generation"
generated: "2026-03-03"
type: flow
flow_name: "auto-campaign-generation"
flow_type: scheduled
trigger: "Weekly (every Tuesday) or manual invocation with createAuto argument"
participants:
  - "continuumHotzoneGeneratorJob"
  - "continuumMarketingDealService"
  - "continuumTaxonomyService"
  - "apiProxy"
architecture_ref: "dynamic-hotzoneGenerationFlow"
---

# Auto Campaign Generation

## Summary

Every Tuesday (or when the `createAuto` argument is passed), HotzoneGenerator automatically creates hotzone campaign configurations from trending deal-cluster category data. It first cleans up previously auto-generated campaigns, then for each country iterates over all divisions, fetches trending L4 categories from the deal-clusters endpoint via the internal API proxy, resolves English display names from the Taxonomy service, and POSTs a new campaign to the Proximity Notifications API. This allows the hotzone system to self-update based on current consumer interest trends without manual campaign creation.

## Trigger

- **Type**: schedule (conditional within the main daily job)
- **Source**: `App.main()` checks `Calendar.DAY_OF_WEEK == Calendar.TUESDAY` or `args[2].equals("createAuto")`
- **Frequency**: Weekly on Tuesdays; can also be forced manually by passing `createAuto` as the third CLI argument

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Hotzone Generator Job (`campaignAutomationEngine`) | Orchestrates campaign cleanup and auto-creation | `continuumHotzoneGeneratorJob` |
| Marketing Deal Service (MDS) | Provides country division list | `continuumMarketingDealService` |
| Internal API Proxy (deal-clusters) | Provides trending category data per country/division | `apiProxy` |
| Taxonomy Service v2 | Resolves English display names for category GUIDs | `continuumTaxonomyService` |
| Proximity Notifications API | Accepts new campaign configurations; deletes old auto-campaigns | stub |

## Steps

1. **Delete existing auto-generated campaigns**: Sends `POST hotzone/campaign/delete-auto?client_id=ec-team`. Calls `System.exit(1)` on failure.
   - From: `proximitySyncClient`
   - To: Proximity Notifications API
   - Protocol: HTTPS/JSON

2. **Fetch country division list**: For each country in `CountryCode`, sends `GET /{country}/divisions?client={mds.clientId}` to MDS to get the list of division names.
   - From: `campaignAutomationEngine`
   - To: `continuumMarketingDealService`
   - Protocol: HTTPS/JSON

3. **Fetch trending categories per division**: For each division, sends `GET wh/v2/clusters/navigation?country={country}&division={division}&type=DIVISION_L4_CR_MIN10&client_id={clientId}` to the deal-clusters endpoint via the API proxy.
   - From: `campaignAutomationEngine`
   - To: `apiProxy`
   - Protocol: HTTPS/JSON

4. **Filter categories**: Skips categories with null/empty labels or GUIDs. Skips level-3 categories listed in `denyListCategories`. Deduplicates categories already added for the country using a `Set<UUID>`.
   - From: `campaignAutomationEngine`
   - To: In-process
   - Protocol: direct

5. **Resolve English taxonomy name**: For each qualifying category, sends `GET categories/{categoryGuid}` to the Taxonomy service. Uses an empty string if the call fails.
   - From: `campaignAutomationEngine`
   - To: `continuumTaxonomyService`
   - Protocol: HTTPS/JSON

6. **Build campaign payload**: Constructs a `CampaignAPIDataFormat` with fixed defaults:
   - `limit=1000`, `priceThreshold=500`, `conversion=0.01`, `purchaseNumber=5`
   - `isReverse=false`, `useOpenHours=false`, `isAuto=true`
   - `queryUrl` = `trends/hot.json?country={country}&size=1000&channel={channel}&customer_taxonomy_guid={guid}&client={clientId}&min_margin=0`
   - `audienceId`, `radius`, `dealTimeRange` determined by matching the category's L2 UUID against known category UUIDs in `skeletor.global.properties`
   - From: `campaignAutomationEngine`
   - To: In-process
   - Protocol: direct

7. **POST campaign to Proximity API**: Serialises the campaign to JSON and sends `POST hotzone/campaign?client_id={clientId}`. Logs success or failure per campaign.
   - From: `campaignAutomationEngine`
   - To: Proximity Notifications API
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Campaign delete-auto call fails | Logs error and calls `System.exit(1)` | Run aborts |
| MDS divisions call fails for a country | Caught and logged; that country processes zero divisions | No campaigns created for that country |
| Deal-clusters call fails for a division | Caught and logged; that division skipped | No campaigns created for that division |
| Deal-clusters returns null categories | Logs warning and skips the division | No campaigns created for that division |
| Taxonomy call fails | Caught and logged; empty string used as display name | Campaign created with blank taxonomy name |
| Campaign POST fails | Caught and logged; continues to next campaign | That campaign is not created; others continue |

## Sequence Diagram

```
continuumHotzoneGeneratorJob -> ProximityAPI: POST hotzone/campaign/delete-auto
loop for each country in CountryCode
  continuumHotzoneGeneratorJob -> continuumMarketingDealService: GET /{country}/divisions
  continuumMarketingDealService --> continuumHotzoneGeneratorJob: Division list
  loop for each division
    continuumHotzoneGeneratorJob -> apiProxy: GET wh/v2/clusters/navigation?country=...&division=...
    apiProxy --> continuumHotzoneGeneratorJob: Trending categories (L4)
    loop for each qualifying category
      continuumHotzoneGeneratorJob -> continuumTaxonomyService: GET categories/{categoryGuid}
      continuumTaxonomyService --> continuumHotzoneGeneratorJob: English category name
      continuumHotzoneGeneratorJob -> continuumHotzoneGeneratorJob: Build CampaignAPIDataFormat
      continuumHotzoneGeneratorJob -> ProximityAPI: POST hotzone/campaign
    end
  end
end
```

## Related

- Architecture dynamic view: `dynamic-hotzoneGenerationFlow`
- Related flows: [Hotzone Generation (Config Mode)](hotzone-generation.md), [Weekly Email Dispatch](weekly-email-dispatch.md)
