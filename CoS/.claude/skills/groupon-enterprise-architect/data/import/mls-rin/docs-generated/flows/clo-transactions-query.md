---
service: "mls-rin"
title: "CLO Transactions Query"
generated: "2026-03-03"
type: flow
flow_name: "clo-transactions-query"
flow_type: synchronous
trigger: "HTTP POST to /v2/clotransactions/itemized_list, /v2/clotransactions/visits, or /v2/clotransactions/new_customers"
participants:
  - "continuumMlsRinService"
  - "mlsRinDealIndexDb"
architecture_ref: "dynamic-continuumMlsRinService"
---

# CLO Transactions Query

## Summary

The CLO Transactions Query flow serves requests for Card-Linked Offer (CLO) transaction data for a set of deals within a date range. Three sub-flows share the same resource path prefix (`/v2/clotransactions`) and are distinguished by endpoint suffix: `itemized_list` returns individual CLO transaction records, `visits` returns aggregated visit counts with locale-formatted output, and `new_customers` returns new customer acquisition counts. All three endpoints require a deal ID filter in the request body and start/end date parameters. The CLO domain services read from the deal index or CLO-specific tables in the local read-model databases.

## Trigger

- **Type**: api-call
- **Source**: Merchant Center portal requesting CLO performance data for merchant dashboard
- **Frequency**: On-demand (per user request / dashboard load)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MLS RIN Service | Orchestrator — receives POST, validates request, queries CLO data, returns response | `continuumMlsRinService` |
| MLS RIN Deal Index DB | Source for CLO transaction records linked to deals | `mlsRinDealIndexDb` |

## Steps

1. **Receive CLO transactions request**: Accepts POST on one of:
   - `/v2/clotransactions/itemized_list` — requires `dealIdsFilter` in body; `start_date`, `end_date` as query params
   - `/v2/clotransactions/visits` — requires `dealIdsFilter` in body; `start_date`, `end_date`, `locale` as query params
   - `/v2/clotransactions/new_customers` — requires `merchantDealIds` in body; `start_date`, `end_date` as query params
   - From: `caller`
   - To: `continuumMlsRinService`
   - Protocol: REST / HTTP

2. **Authenticate caller**: JTier auth bundle validates client-ID for `ROLE_READ`.
   - From: `continuumMlsRinService`
   - To: `mlsRin_apiLayer` (internal)
   - Protocol: direct

3. **Validate request body**: CLO resource validates that required filter fields are present (`dealIdsFilter` or `merchantDealIds`). Returns HTTP 400 with descriptive message if filter is absent or empty.
   - From/To: `continuumMlsRinService` (internal — `CloTransactionsResource`)
   - Protocol: direct

4. **Query CLO transaction data**: CLO Transactions Service queries the database for CLO records matching the deal IDs and UTC-normalized date range (start/end converted to UTC LocalDateTime).
   - From: `continuumMlsRinService`
   - To: `mlsRinDealIndexDb` (CLO transaction tables)
   - Protocol: JDBI/PostgreSQL

5. **Aggregate or format response**:
   - `itemized_list`: Returns raw `List<CloTransaction>` records
   - `visits`: Aggregates into `VisitsResponse` with locale-formatted amounts using `Locale.forLanguageTag(locale)`
   - `new_customers`: Aggregates into `NewCustomersResponse` with customer acquisition counts
   - From/To: `continuumMlsRinService` (internal — `CloTransactionsService`)
   - Protocol: direct

6. **Return CLO response**: Returns JSON response body.
   - From: `continuumMlsRinService`
   - To: `caller`
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing dealIdsFilter / merchantDealIds in body | `BadRequestException` thrown | HTTP 400 with message "Malformed or incomplete dealIds query in body, dealIds filter is required." |
| DB unavailable | JDBI exception propagates | HTTP 500 returned |
| Invalid date format (start_date / end_date) | JAX-RS `OffsetDateTimeParam` parsing failure | HTTP 400 returned |
| Authentication failure | JTier auth bundle rejects | HTTP 401 / 403 returned |

## Sequence Diagram

```
Caller -> continuumMlsRinService: POST /v2/clotransactions/visits?start_date=...&end_date=...&locale=en-US {dealIdsFilter:[...]}
continuumMlsRinService -> mlsRin_apiLayer: validate auth (client-id ROLE_READ)
continuumMlsRinService -> mlsRin_cloDomain: validate dealIdsFilter not empty
continuumMlsRinService -> mlsRinDealIndexDb: SELECT clo_transactions WHERE deal_id IN (...) AND occurred_at BETWEEN ... AND ...
mlsRinDealIndexDb --> continuumMlsRinService: CLO records
continuumMlsRinService -> mlsRin_cloDomain: aggregate visits by deal, format with locale
continuumMlsRinService --> Caller: JSON VisitsResponse
```

## Related

- Architecture dynamic view: `dynamic-continuumMlsRinService`
- Related flows: [Deal List Query](deal-list-query.md), [Metrics Retrieval](metrics-retrieval.md)
