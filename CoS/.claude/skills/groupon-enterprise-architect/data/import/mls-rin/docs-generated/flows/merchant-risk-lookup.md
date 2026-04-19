---
service: "mls-rin"
title: "Merchant Risk Lookup"
generated: "2026-03-03"
type: flow
flow_name: "merchant-risk-lookup"
flow_type: synchronous
trigger: "HTTP GET to /v1/merchant_risk/{merchant_id}"
participants:
  - "continuumMlsRinService"
  - "mlsRinYangDb"
architecture_ref: "dynamic-continuumMlsRinService"
---

# Merchant Risk Lookup

## Summary

The Merchant Risk Lookup flow retrieves a merchant's risk status and threshold data from the optional Yang DB read model. This endpoint is only active when the merchant risk module is enabled via configuration (`modules.merchantRisk` is present and `databases.yangConfig` is configured). The risk domain services read from `mlsRinYangDb` and apply configured minimum and maximum refunded percentage thresholds to compute and return the merchant's risk assessment.

## Trigger

- **Type**: api-call
- **Source**: Internal consumer (Merchant Center portal or Merchant Experience tooling) checking merchant risk status
- **Frequency**: On-demand (per merchant profile page load or risk review request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MLS RIN Service | Orchestrator — receives request, queries Yang DB, applies risk thresholds, returns response | `continuumMlsRinService` |
| MLS RIN Yang DB | Source for merchant risk and yang-module data | `mlsRinYangDb` |

## Steps

1. **Receive merchant risk request**: Accepts GET on `/v1/merchant_risk/{merchant_id}` where `merchant_id` is a UUID path parameter.
   - From: `caller`
   - To: `continuumMlsRinService`
   - Protocol: REST / HTTP

2. **Authenticate caller**: JTier auth bundle validates client-ID credentials.
   - From: `continuumMlsRinService`
   - To: `mlsRin_apiLayer` (internal)
   - Protocol: direct

3. **Check module availability**: Merchant Risk Services verify that the Yang DB configuration and risk module configuration are present (`Optional<PostgresConfig> yangConfig()` and `Optional<MerchantRiskConfiguration> merchantRisk()` are both non-empty). If not configured, the endpoint is not reachable / returns an error.
   - From/To: `continuumMlsRinService` (internal — `mlsRin_riskDomain`)
   - Protocol: direct

4. **Query merchant risk from Yang DB**: Issues JDBI query against `mlsRinYangDb` for the merchant risk record identified by `merchant_id`.
   - From: `continuumMlsRinService`
   - To: `mlsRinYangDb`
   - Protocol: JDBI/PostgreSQL

5. **Apply risk thresholds**: Merchant Risk Services apply `minRecommendedPercentage` and `maxRefundedPercentage` thresholds from `MerchantRiskConfiguration` to compute the effective risk classification.
   - From/To: `continuumMlsRinService` (internal — `mlsRin_riskDomain`)
   - Protocol: direct

6. **Return merchant risk response**: Returns JSON `MerchantRisk` response with risk status and threshold data.
   - From: `continuumMlsRinService`
   - To: `caller`
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Yang DB not configured (module disabled) | Module not activated; endpoint may return 404 or 500 | Endpoint unavailable when yang module is absent |
| Yang DB unavailable | JDBI connection failure propagates | HTTP 500 returned |
| Merchant not found in Yang DB | Empty result from JDBI query | HTTP 200 with empty / default risk response or 404 depending on service logic |
| Authentication failure | JTier auth bundle rejects | HTTP 401 / 403 returned |

## Sequence Diagram

```
Caller -> continuumMlsRinService: GET /v1/merchant_risk/{merchant_id}
continuumMlsRinService -> mlsRin_apiLayer: validate auth (client-id)
continuumMlsRinService -> mlsRin_riskDomain: check yang module enabled
mlsRin_riskDomain -> mlsRinYangDb: SELECT merchant_risk WHERE merchant_id = {uuid}
mlsRinYangDb --> mlsRin_riskDomain: risk record
mlsRin_riskDomain -> mlsRin_riskDomain: apply minRecommendedPercentage / maxRefundedPercentage thresholds
continuumMlsRinService --> Caller: JSON MerchantRisk response
```

## Related

- Architecture dynamic view: `dynamic-continuumMlsRinService`
- Related flows: [Deal List Query](deal-list-query.md)
