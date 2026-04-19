---
service: "aidg"
title: "Merchant Quality Scoring"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "merchant-quality-scoring"
flow_type: synchronous
trigger: "API call to Merchant Quality API"
participants:
  - "merchantQuality"
architecture_ref: "none — no dynamic view defined yet"
---

# Merchant Quality Scoring

## Summary

This flow handles merchant quality scoring requests. An internal Continuum service sends merchant identification data to the Merchant Quality API, which evaluates the merchant against AI-driven quality models and returns a quality score. This score is used by downstream systems for deal ranking, advertising eligibility, and merchant trust evaluation within the Groupon marketplace.

## Trigger

- **Type**: api-call
- **Source**: Internal Continuum platform service requesting merchant quality evaluation
- **Frequency**: On-demand, per-request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Upstream Caller | Initiates quality scoring request with merchant data | Not modeled in federated workspace |
| Merchant Quality API | Receives request, evaluates merchant quality, and returns score | `merchantQuality` |

## Steps

1. **Receives scoring request**: An internal Continuum service sends merchant identification data to the Merchant Quality API, requesting a quality score.
   - From: Upstream caller
   - To: `merchantQuality`
   - Protocol: REST/HTTPS (inferred)

2. **Validates merchant data**: The Merchant Quality API validates the incoming request for required merchant identifiers and data format.
   - From: `merchantQuality`
   - To: `merchantQuality` (internal)
   - Protocol: in-process

3. **Evaluates quality model**: The service executes the AI-driven quality scoring model against the merchant data, potentially incorporating historical performance data, review signals, fulfillment metrics, and other quality indicators.
   - From: `merchantQuality`
   - To: `merchantQuality` (internal model execution)
   - Protocol: in-process

4. **Returns quality score**: The Merchant Quality API returns the computed quality score and any associated metadata (e.g., score breakdown, confidence level, contributing factors) to the upstream caller.
   - From: `merchantQuality`
   - To: Upstream caller
   - Protocol: REST/HTTPS JSON response (inferred)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid merchant identifier | Validation error returned to caller | Request rejected; caller receives error response |
| Model scoring failure | Service returns error or default score | Caller receives error or falls back to default quality assumption |
| Merchant data not found | Service returns 404 or default score | Caller handles missing merchant gracefully |
| Upstream timeout | Caller-side timeout handling | Caller retries or proceeds with default quality score |

> Error handling details are inferred from common patterns. Exact behavior will be documented when source code is available.

## Sequence Diagram

```
UpstreamCaller -> merchantQuality: POST /score {merchant_id, merchant_data}
merchantQuality -> merchantQuality: validate merchant identifiers
merchantQuality -> merchantQuality: evaluate quality scoring model
merchantQuality --> UpstreamCaller: 200 OK {quality_score, confidence, factors}
```

## Related

- Architecture dynamic view: not yet defined
- Related flows: [PDS Inference Enrichment](pds-inference-enrichment.md)
