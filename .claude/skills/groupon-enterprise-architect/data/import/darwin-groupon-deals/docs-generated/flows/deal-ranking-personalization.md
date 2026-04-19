---
service: "darwin-groupon-deals"
title: "Deal Ranking and Personalization"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-ranking-personalization"
flow_type: synchronous
trigger: "Invoked internally by aggregationEngine after upstream data collection is complete"
participants:
  - "aggregationEngine"
  - "modelStore"
  - "externalClients"
  - "watsonObjectStorageExt_3a1f2c"
  - "audienceUserAttributesServiceExt_6e01f4"
  - "continuumUserIdentitiesService"
architecture_ref: "darwinAggregatorServiceComponents"
---

# Deal Ranking and Personalization

## Summary

Deal Ranking and Personalization is the core intelligence step within the Darwin Aggregator Service. After the `aggregationEngine` collects candidate deals from Elasticsearch and enrichment data from upstream services, it applies ML model artifacts (loaded from Watson Object Storage by `modelStore`) to score each deal candidate. Personalization signals — including resolved user identity, audience segmentation attributes, and geo context — are incorporated into the scoring to produce a ranked, user-tailored deal list. This flow runs as an internal sub-flow within both the [REST Deal Search](rest-deal-search.md) and [Async Batch Aggregation](async-batch-aggregation.md) flows.

## Trigger

- **Type**: api-call (internal)
- **Source**: `aggregationEngine` invokes ranking after completing upstream data fan-out
- **Frequency**: per-request (every aggregation, synchronous or async)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `aggregationEngine` | Orchestrates scoring, applies model, produces ranked output | `continuumDarwinAggregatorService` |
| `modelStore` | Provides current ML model artifacts to the scoring step | `continuumDarwinAggregatorService` |
| Watson Object Storage | Backing store for ML model artifacts loaded by `modelStore` | `watsonObjectStorageExt_3a1f2c` |
| Audience User Attributes | Supplies audience segmentation data (fetched in prior fan-out step) | `audienceUserAttributesServiceExt_6e01f4` |
| User Identities Service | Supplies resolved user identity (fetched in prior fan-out step) | `continuumUserIdentitiesService` |

## Steps

1. **Receive Candidate Pool**: `aggregationEngine` receives the raw set of deal candidates from the Elasticsearch query and catalog enrichment steps.
   - From: Elasticsearch query results + Deal Catalog enrichment
   - To: `aggregationEngine`
   - Protocol: In-process

2. **Load Model Artifacts**: `modelStore` provides the current ML ranking model (feature weights, ranking parameters) to `aggregationEngine`. If the model is already loaded in memory (e.g., from service startup), this step is a read from the in-process model cache.
   - From: `aggregationEngine`
   - To: `modelStore`
   - Protocol: In-process (backed by `watsonObjectStorageExt_3a1f2c` for initial load)

3. **Assemble Feature Vector**: `aggregationEngine` constructs a feature vector for each deal candidate, combining deal attributes (price, category, geo match, availability) with user signals (identity, audience attributes) and contextual signals (query, geo, session).
   - From: `aggregationEngine`
   - To: In-process
   - Protocol: In-process

4. **Score Candidates**: `aggregationEngine` applies the ML model to each deal candidate's feature vector to produce a relevance score.
   - From: `aggregationEngine`
   - To: In-process (model scoring)
   - Protocol: In-process

5. **Apply Booster Experiments**: `aggregationEngine` applies any active A/B booster experiment configurations (read from `/booster_ab_experiments` state) to adjust scores for experiment participants.
   - From: `aggregationEngine`
   - To: In-process booster configuration state
   - Protocol: In-process

6. **Sort and Truncate**: `aggregationEngine` sorts deal candidates by descending relevance score and truncates to the requested result count.
   - From: `aggregationEngine`
   - To: In-process
   - Protocol: In-process

7. **Return Ranked List**: `aggregationEngine` emits the ordered, personalized deal list for downstream steps (sponsored ad blending, cache write, response serialization).
   - From: `aggregationEngine`
   - To: Calling flow (`apiResource` or `messagingAdapter_DarGroDea`)
   - Protocol: In-process

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Model artifact not loaded (cold start or load failure) | Fall back to default ranking (e.g., popularity-based or recency-based sort) | Deals returned without ML personalization; quality degraded |
| Watson Object Storage unreachable | Stale model used from in-process cache if available | Ranking quality depends on model freshness |
| Audience attributes unavailable | Scoring proceeds without personalization signals | Non-personalized ranking applied |
| User identity not resolved | Anonymous feature vector used for scoring | Ranking is non-personalized |
| Booster experiment config invalid | Experiment skipped; baseline scoring applied | A/B experiment results not collected |

## Sequence Diagram

```
aggregationEngine -> modelStore:                     Request current model artifacts
modelStore        -> watsonObjectStorageExt_3a1f2c:  Load model (if not cached)
watsonObjectStorage --> modelStore:                  Model artifact bytes
modelStore        --> aggregationEngine:             Model object
aggregationEngine -> aggregationEngine:              Assemble feature vectors (deal + user + context)
aggregationEngine -> aggregationEngine:              Score candidates with ML model
aggregationEngine -> aggregationEngine:              Apply booster A/B adjustments
aggregationEngine -> aggregationEngine:              Sort and truncate to result size
aggregationEngine --> CallingFlow:                   Ordered deal list
```

## Related

- Architecture dynamic view: `darwinAggregatorServiceComponents`
- Related flows: [REST Deal Search](rest-deal-search.md), [Async Batch Aggregation](async-batch-aggregation.md)
- A/B experiment management: `GET /booster_ab_experiments`, `PUT /booster_ab_experiments` — see [API Surface](../api-surface.md)
