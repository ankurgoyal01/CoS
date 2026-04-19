---
service: "badges-trending-calculator"
title: "Deal Purchase Badge Computation"
generated: "2026-03-03"
type: flow
flow_name: "deal-purchase-badge-computation"
flow_type: event-driven
trigger: "DealPurchase event arrives on janus-tier1 Kafka topic"
participants:
  - "janusTier1Topic"
  - "continuumBadgesTrendingCalculator"
  - "watsonKv"
  - "continuumBadgesRedisStore"
architecture_ref: "dynamic-deal-purchase-badge-computation"
---

# Deal Purchase Badge Computation

## Summary

This is the primary end-to-end flow of the service. When a customer purchases a deal, a `DealPurchase` event is published to the Janus Kafka topic. Badges Trending Calculator consumes these events in 10-minute Spark Streaming micro-batches, validates and aggregates them, enriches each deal with division and channel metadata from Watson KV, and then computes updated Trending and Top Seller rankings that are written to Redis for consumption by `badges-service`.

## Trigger

- **Type**: event
- **Source**: `DealPurchase` event on Kafka topic `janus-tier1` (producer: Janus)
- **Frequency**: Continuous; micro-batches every 600 seconds (production)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Janus Kafka (`janus-tier1`) | Event source — streams deal purchase events | `janusTier1Topic` |
| Badges Trending Calculator | Event processor — filters, enriches, aggregates, and ranks | `continuumBadgesTrendingCalculator` |
| Watson KV | Metadata provider — supplies division, channel, and merchantServiceCategory per deal UUID | `watsonKv` |
| Badges Redis Store | State store — holds rolling deal-count hashes and final badge rankings | `continuumBadgesRedisStore` |

## Steps

1. **Receive micro-batch DataFrame**: The `BadgeCalculator` entry point (via `JanusStreamingCSparkJob`) polls `janus-tier1` and assembles a Spark DataFrame of `DealPurchase` rows for the current batch interval.
   - From: `janusTier1Topic`
   - To: `janusDealPurchaseIngestion` (BadgeCalculator)
   - Protocol: Kafka SSL

2. **Filter invalid rows**: `BadgeCalculatorProcessor.filterRow` removes rows where `dealUUID`, `country`, or `dealPermalink` is empty, or where the country/deal UUID fails validation checks.
   - From: `badgeCalculatorProcessor`
   - To: internal filter
   - Protocol: in-process

3. **Aggregate by dealUUID**: Filter rows are grouped by `dealUUID`; `quantity` values are summed; `country`, `dealPermalink`, and `eventTime` are taken from the first occurrence.
   - From: `badgeCalculatorProcessor`
   - To: Spark SQL aggregation
   - Protocol: in-process (Spark SQL)

4. **Enrich with division and channel (Watson UDF)**: A Spark UDF calls `WatsonServiceClient.getIntrinsicDto` for each distinct `dealUUID`. Watson returns `channelPermalink`, `divPermalink`, and `merchantServiceCategory`. The UDF adds a `deal_info` struct column to each row.
   - From: `watsonIntrinsicAdapter`
   - To: `watsonKv` (edge proxy)
   - Protocol: HTTPS (mTLS)

5. **Filter by supported division**: `BadgeCalculatorProcessor.filterRowOnLocation` checks that the deal's `divPermalink` is in the `Divison_Supported` cached set (read from Redis by `DBHandle.getCachedDivisionSet`) and that the `merchantServiceCategory` is not in the excluded PDS list.
   - From: `badgeCalculatorProcessor`
   - To: `continuumBadgesRedisStore` (GET `Divison_Supported`)
   - Protocol: Redis

6. **Repartition by division and channel**: The enriched DataFrame is repartitioned on `deal_info.divison` and `deal_info.channel` so all purchases for the same segment land in the same Spark partition.
   - From: `badgeCalculatorProcessor`
   - To: Spark repartition
   - Protocol: in-process (Spark)

7. **Compute Trending and Top Seller rankings per partition**: `ProcessorTask.calculatorTask` is called for each partition. For each base key (division + channel) over 7 days it reads the existing daily hash from Redis, merges in the current batch counts, applies a daily decay factor (0.9^day) for Trending, and produces two Top-500 ranked maps.
   - From: `trendingComputationEngine`
   - To: `continuumBadgesRedisStore` (HGETALL per day key)
   - Protocol: Redis

8. **Persist updated daily deal-count hashes**: `ProcessorTask.persistDealCountsInStorage2` writes the merged daily hash back to Redis with an 8-day expiry (691200 seconds).
   - From: `trendingComputationEngine` via `redisPersistenceAdapter`
   - To: `continuumBadgesRedisStore` (HSET + EXPIRE)
   - Protocol: Redis

9. **Write final weekly summarized rankings**: `ProcessorTask.updateFinalSummarizedResults2` atomically replaces the final weekly hash key (`wfinal|{prefix}|{calcType}|{baseKey}`) for both Trending and Top Seller.
   - From: `trendingComputationEngine` via `redisPersistenceAdapter`
   - To: `continuumBadgesRedisStore` (UNLINK + HSET + EXPIRE)
   - Protocol: Redis

10. **Write per-deal rank-and-count strings**: `ProcessorTask.updateFinalIndividualDealsResult2` writes a per-deal key (`{hashTag}|{prefix}|wfinal|{calcType}_deal|{dealUUID}`) for each ranked deal with a 1-day expiry.
    - From: `trendingComputationEngine` via `redisPersistenceAdapter`
    - To: `continuumBadgesRedisStore` (SETEX)
    - Protocol: Redis

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid row (empty dealUUID/country/permalink) | Filtered out in `filterRow` before aggregation | Row dropped; no impact on rankings |
| Watson HTTP error (`ClientProtocolException`) | Caught in UDF; logged as error | Row has empty division/channel; excluded by `filterRowOnLocation` |
| Watson generic exception | Caught in UDF; logged as error | Same as above |
| Division not in supported set | Filtered by `filterRowOnLocation` | Row dropped |
| Excluded PDS UUID | Filtered by `filterRowOnLocation` | Row dropped |
| Redis `JedisConnectionException` | Caught per base-key; logged as error | Rankings for that partition key skipped in current batch |
| Redis read failure (general) | 5-attempt retry with 50ms interval in `calculatorTask` | If all retries fail, batch data is lost for that key |
| Kafka offset out of range | Spark job terminates | Manual operator action required (offset reset) |

## Sequence Diagram

```
janus-tier1    BadgeCalculator    BadgeCalculatorProcessor    WatsonKV    Redis
     |                |                      |                   |          |
     |--DealPurchase->|                      |                   |          |
     |          micro-batch DF               |                   |          |
     |                |--dispatch batch DF-->|                   |          |
     |                |              filter invalid rows         |          |
     |                |              groupBy dealUUID+sum qty    |          |
     |                |              for each dealUUID           |          |
     |                |                      |--GET intrinsic--->|          |
     |                |                      |<--deal_info-------|          |
     |                |              filterRowOnLocation         |          |
     |                |                      |--GET Divison_Supported------>|
     |                |                      |<--division set---------------|
     |                |              repartition by div+channel  |          |
     |                |                      |--calculatorTask---|--------->|
     |                |                      |                   |  HGETALL daily hashes
     |                |                      |                   |<---------|
     |                |                      |       merge+decay+rank       |
     |                |                      |---HSET daily hashes--------->|
     |                |                      |---UNLINK+HSET wfinal keys--->|
     |                |                      |---SETEX per-deal keys------->|
```

## Related

- Architecture dynamic view: `dynamic-deal-purchase-badge-computation`
- Related flows: [Geo Division Refresh](geo-division-refresh.md), [Trending and Top Seller Ranking Computation](trending-ranking-computation.md)
