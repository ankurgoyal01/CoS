---
service: "ugc-async"
title: "Essence Aspect Aggregation"
generated: "2026-03-03"
type: flow
flow_name: "essence-aspect-aggregation"
flow_type: event-driven
trigger: "MBus Essence NLP tagging output event (essenceListener or aspectsListener consumer)"
participants:
  - "essenceAspectTaggingService_4a88"
  - "mbusPlatform_9b1a"
  - "continuumUgcAsyncService"
  - "continuumM3MerchantService"
  - "continuumUgcPostgresDb"
architecture_ref: "dynamic-ugc-async-essence-aspect-aggregation"
---

# Essence Aspect Aggregation

## Summary

The Essence Aspect Tagging Service produces NLP-derived aspect scores for Groupon place and merchant content. These scores are published as events on MBus. ugc-async consumes these events via the `essenceListener` and `aspectsListener` consumers and updates the `aggregated_ratings` table with per-place and per-merchant `PlaceAspectsSummary` lists. Aspects are sorted by frequency and capped at 20 per place and 20 per merchant. Category-based and non-category-based aspects are stored separately within a JSON column.

## Trigger

- **Type**: event (MBus message)
- **Source**: `essenceAspectTaggingService_4a88` publishes NLP aspect analysis output events to MBus
- **Frequency**: Per content batch analysed by the Essence service; event-driven, continuous

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Essence Aspect Tagging Service | Produces NLP aspect analysis events on MBus | `essenceAspectTaggingService_4a88` |
| MBus Platform | Delivers aspect events to ugc-async consumers | `mbusPlatform_9b1a` |
| UGC Async Service — Message Bus Consumers | Receives `PlaceAspectMessage` payload | `continuumUgcAsyncService` |
| UGC Async Service — EssenceListenerService | Transforms aspect payload and orchestrates place/merchant aspect updates | `continuumUgcAsyncService` |
| M3 Merchant Service | Provides merchant-to-place mappings needed for merchant-level rollup | `continuumM3MerchantService` |
| UGC Postgres | Source and target of aggregated rating records | `continuumUgcPostgresDb` |

## Steps

1. **Receives Essence NLP event**: MBus platform delivers a `PlaceAspectMessage` to the `essenceListener` (or `aspectsListener`) consumer in ugc-async
   - From: `mbusPlatform_9b1a`
   - To: `continuumUgcAsyncService` (Message Bus Consumers)
   - Protocol: MBus

2. **Extracts placeId and treatmentId**: Consumer extracts the primary `placeId` and `treatmentId` (either `categoryBased` or `nonCategoryBased`) from the message header/body
   - From: Message Bus Consumers
   - To: EssenceListenerService
   - Protocol: direct (in-process)

3. **Transforms aspect payload to PlaceAspectsSummary list**: `getPASForPlace()` iterates the `opinions` list in `PlaceAspectMessage`; for each opinion, builds a `PlaceAspectsSummary` with scores (`tfidf_score`, `sentiment_avg`, `sentiment_var`, `positive_count`, `negative_count`, `uniqueness`, `frequency`), adjective scores, and source information
   - From: EssenceListenerService
   - To: EssenceListenerService (internal transform)
   - Protocol: direct (in-process)

4. **Fetches existing aggregated rating for place**: `aggregatedRatingDao.findAggregatedRatingContent(placeContext)` reads the current aggregated rating record for the place from `continuumUgcPostgresDb`
   - From: `continuumUgcAsyncService`
   - To: `continuumUgcPostgresDb`
   - Protocol: JDBI / SQL

5. **Merges place aspects**: `mergePlaceAspectSummaries()` replaces the aspects for the given `treatmentId` with the new sorted and capped list (top 20 by frequency); retains aspects from the other treatmentId unchanged. Updates `aspect_information` JSON column on the `aggregated_ratings` row
   - From: EssenceListenerService
   - To: `continuumUgcPostgresDb`
   - Protocol: JDBI / SQL

6. **Fetches merchant IDs for the place**: Calls `m3ServiceManager.getMerchantIdsForPlace(placeId)` to retrieve the set of merchants associated with the updated place
   - From: `continuumUgcAsyncService`
   - To: `continuumM3MerchantService`
   - Protocol: REST (Retrofit)

7. **Rolls up aspects to merchant level**: For each merchant, `updateAspectsForMerchant()` fetches all place IDs for that merchant via `m3ServiceManager.findPlaceIdsByMerchantId()`, reads the aspect data from each place's aggregated rating, merges category-based and non-category-based aspect lists across all places (cap: 20 per merchant per treatment), and writes the updated merchant aggregated rating back to `continuumUgcPostgresDb`
   - From: `continuumUgcAsyncService`
   - To: `continuumM3MerchantService` (place IDs lookup) then `continuumUgcPostgresDb`
   - Protocol: REST (Retrofit) then JDBI / SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Aggregated rating record not found for place | Warning logged (`AGGREGATED_RATING_NOT_FOUND`); aspect update skipped | Place aspects not updated; no retry |
| Aggregated rating not found for merchant | Warning logged; merchant rollup skipped | Merchant aspects not updated |
| Aspect list JSON parse failure (`PlaceAspectMap`) | Falls back to `JsonUtils.parseAsMap()`; warning logged | Partial parse attempted; may result in empty aspect map |
| Aspect sorting failure | Warning logged; unsorted list used instead | Aspects saved in arbitrary order rather than by frequency |
| M3 Merchant Service call failure | Exception propagates; merchant rollup halted for this event | Merchant-level aspects not updated; place aspects already saved |

## Sequence Diagram

```
Essence Aspect Tagging Service -> MBus Platform: Publish PlaceAspectMessage (NLP output)
MBus Platform -> UGC Async (Consumers): Deliver PlaceAspectMessage
UGC Async (Consumers) -> EssenceListenerService: updatePlaceAspects(message, placeId, treatmentId)
EssenceListenerService -> UGC Postgres: findAggregatedRatingContent(placeContext)
UGC Postgres --> EssenceListenerService: Existing aggregated rating (with aspect_information JSON)
EssenceListenerService -> UGC Postgres: updateAspectsString(aggregatedRatingId, updatedRating)
EssenceListenerService -> M3 Merchant Service: getMerchantIdsForPlace(placeId) (REST)
M3 Merchant Service --> EssenceListenerService: merchantIds
loop for each merchantId
  EssenceListenerService -> M3 Merchant Service: findPlaceIdsByMerchantId(merchantId) (REST)
  M3 Merchant Service --> EssenceListenerService: placeIds
  EssenceListenerService -> UGC Postgres: findAggregatedRatingContent per placeId (merge aspects)
  EssenceListenerService -> UGC Postgres: updateAspectsString(merchantAggregatedRatingId, mergedAspects)
end
```

## Related

- Architecture dynamic view: `dynamic-ugc-async-essence-aspect-aggregation`
- Related flows: [Survey Creation from MBus Event](survey-creation-mbus.md)
- Essence Listener Service source: `src/main/java/com/groupon/ugc/ugcasync/helper/EssenceListenerService.java`
