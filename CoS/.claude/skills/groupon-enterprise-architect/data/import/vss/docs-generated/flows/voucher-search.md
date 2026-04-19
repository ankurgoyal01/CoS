---
service: "vss"
title: "Voucher Search"
generated: "2026-03-03"
type: flow
flow_name: "voucher-search"
flow_type: synchronous
trigger: "HTTP GET or POST request from Merchant Centre"
participants:
  - "merchantCenter"
  - "continuumVssService"
  - "vssResource"
  - "searchService"
  - "voucherUserDataService"
  - "voucherUsersDataDbi"
  - "continuumVssMySql"
architecture_ref: "components-vss-searchService-components"
---

# Voucher Search

## Summary

The voucher search flow is the primary user-facing operation of VSS. Merchant Centre sends a search request containing a `merchantId`, a `clientId`, and a free-text `query` string. VSS validates the client, executes a query against its local MySQL read replica, and returns a list of matched voucher-user records including purchaser and consumer identity fields. The query matches across multiple fields: first name, last name, Groupon code, security/redemption code, gifted email, and user email.

## Trigger

- **Type**: api-call
- **Source**: Merchant Centre (`merchantCenter`)
- **Frequency**: On demand (per merchant user action); production throughput target 50K RPM

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant Centre | Calls VSS search API with merchant and query context | `merchantCenter` |
| VSS Service | Receives HTTP request, orchestrates query | `continuumVssService` |
| VssResource | REST entry point — validates params, routes to SearchService | `vssResource` |
| SearchService | Orchestrates query execution, selects search strategy by match type | `searchService` |
| VoucherUserDataService | Read/write data layer — executes search against data store | `voucherUserDataService` |
| VoucherUsersDataDbi | JDBI DAO — issues SQL query to MySQL read replica | `voucherUsersDataDbi` |
| VSS MySQL | Returns matching voucher-user rows | `continuumVssMySql` |

## Steps

1. **Receives search request**: Merchant Centre sends `GET /v1/vouchers/search?merchantId=X&clientId=Y&query=Z` or `POST /v1/vouchers/search` with equivalent body.
   - From: `merchantCenter`
   - To: `vssResource` (via `continuumVssService`)
   - Protocol: REST

2. **Validates client and query**: `vssResource` checks that `clientId` is in the configured `clientIds` whitelist and that the `query` string meets minimum length threshold (`API_QUERY_THRESHOLD=3` characters).
   - From: `vssResource`
   - To: internal validation (no external call)
   - Protocol: direct

3. **Delegates to SearchService**: `vssResource` passes the validated request to `searchService`.
   - From: `vssResource`
   - To: `searchService`
   - Protocol: direct

4. **Determines search strategy**: `searchService` inspects the query to determine which field(s) to match (voucher code, redemption code, purchaser first/last name, purchaser email, gifted first/last name, gifted email). Metrics are emitted per match category (e.g., `VoucherCodeMatchCount`, `PurchaserFNameMatchCount`).
   - From: `searchService`
   - To: `voucherUserDataService`
   - Protocol: direct

5. **Queries MySQL read replica**: `voucherUserDataService` calls `voucherUsersDataDbi` to execute the appropriate SQL query scoped by `merchantId` and filtered by the query term against relevant columns.
   - From: `voucherUserDataService`
   - To: `voucherUsersDataDbi` → `continuumVssMySql`
   - Protocol: JDBI / MySQL

6. **Returns results**: MySQL returns matched rows; `voucherUsersDataDbi` maps rows to `VoucherUserResponseData` objects (containing `grouponCode`, `redemptionCode`, `inventoryUnitId`, `merchantId`, and `purchaser`/`consumer` Customer objects with masked email).
   - From: `continuumVssMySql`
   - To: `voucherUserDataService` → `searchService` → `vssResource`
   - Protocol: JDBI / Java

7. **Returns HTTP response**: `vssResource` serializes results as JSON and returns `200 OK` with the `VSS` response body containing `totalUnits`, `units`, `totalUsers`, and `users` lists.
   - From: `continuumVssService`
   - To: `merchantCenter`
   - Protocol: REST / JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing required params (`merchantId`, `clientId`, `query`) | Validation in `vssResource` returns 400 Bad Request | Request rejected before MySQL query |
| `clientId` not in whitelist | Validation returns 401 Unauthorized | Request rejected |
| Query below minimum length | Validation returns 400 | Request rejected |
| MySQL read replica unavailable | JDBI throws exception; Dropwizard returns 500 | 5XX alert fires on Wavefront |
| No results matching query | Returns 200 with empty `units` and `users` lists | Normal empty result |

## Sequence Diagram

```
MerchantCentre -> VssResource: GET /v1/vouchers/search?merchantId&clientId&query
VssResource -> VssResource: Validate clientId whitelist + query length
VssResource -> SearchService: search(merchantId, clientId, query)
SearchService -> VoucherUserDataService: findVouchers(merchantId, query)
VoucherUserDataService -> VoucherUsersDataDbi: query(merchantId, term)
VoucherUsersDataDbi -> VSSMySQL: SELECT ... WHERE merchantId=X AND (fields LIKE query)
VSSMySQL --> VoucherUsersDataDbi: rows
VoucherUsersDataDbi --> VoucherUserDataService: List<VoucherUserResponseData>
VoucherUserDataService --> SearchService: results
SearchService --> VssResource: results
VssResource --> MerchantCentre: 200 OK {totalUnits, units, totalUsers, users}
```

## Related

- Architecture dynamic view: `components-vss-searchService-components`
- Related flows: [Voucher Backfill](voucher-backfill.md), [Inventory Unit Ingestion](inventory-unit-ingestion.md)
