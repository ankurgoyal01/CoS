---
service: "goods-vendor-portal"
title: "Contract and Agreement Management"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "contract-and-agreement-management"
flow_type: synchronous
trigger: "Merchant navigates to the contracts or co-op agreements section of the portal"
participants:
  - "emberApp"
  - "goodsVendorPortal_apiClient"
  - "continuumGoodsVendorPortalWeb"
  - "gpapiApi_unk_1d2b"
  - "continuumAccountingService"
architecture_ref: "dynamic-contract-and-agreement-management"
---

# Contract and Agreement Management

## Summary

The Contract and Agreement Management flow allows goods merchants to view their active and historical contracts and co-op agreements with Groupon. Contracts define the commercial terms under which goods are sold; co-op agreements capture shared marketing cost commitments. Both are read from GPAPI, which in turn coordinates with `continuumAccountingService` for financial data. The portal surfaces these records in read-only views; contract creation and financial terms are managed through internal Groupon processes, not through the vendor portal.

## Trigger

- **Type**: user-action
- **Source**: Authenticated merchant navigates to the contracts or co-op agreements section
- **Frequency**: On-demand; merchants review contracts and agreements periodically or when prompted by Groupon operations

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Views contract and co-op agreement records | — |
| Ember UI | Renders contract list and detail views; renders co-op agreement list and detail views | `emberApp` |
| API Client | Fetches contract and co-op agreement data from the proxy endpoints | `goodsVendorPortal_apiClient` |
| Nginx (portal) | Proxies requests to GPAPI | `continuumGoodsVendorPortalWeb` |
| GPAPI | Returns contract and co-op agreement records; coordinates financial data with accounting | `gpapiApi_unk_1d2b` |
| Continuum Accounting Service | Provides financial data for contract and co-op agreement records (via GPAPI) | `continuumAccountingService` |

## Steps

1. **Loads contracts route**: Ember router transitions to the contracts section; `emberApp` initiates a contract list fetch.
   - From: `emberApp`
   - To: `goodsVendorPortal_apiClient`
   - Protocol: In-process (ember-data model hook)

2. **Fetches contracts**: `goodsVendorPortal_apiClient` issues `GET /goods-gateway/contracts` to retrieve the vendor's contracts.
   - From: `goodsVendorPortal_apiClient`
   - To: `continuumGoodsVendorPortalWeb` (Nginx)
   - Protocol: REST/HTTPS

3. **Proxies to GPAPI**: Nginx forwards the contracts request to GPAPI.
   - From: `continuumGoodsVendorPortalWeb`
   - To: `gpapiApi_unk_1d2b`
   - Protocol: REST/HTTPS

4. **GPAPI retrieves financial context**: GPAPI transmits financial data related to contracts to `continuumAccountingService` and incorporates the response into the contract records.
   - From: `gpapiApi_unk_1d2b`
   - To: `continuumAccountingService`
   - Protocol: HTTPS

5. **Returns contract list**: GPAPI returns the contract records with financial context; Nginx proxies the response back.
   - From: `gpapiApi_unk_1d2b`
   - To: `goodsVendorPortal_apiClient` (via Nginx)
   - Protocol: REST/HTTPS

6. **Renders contract list**: `emberApp` populates the ember-data store and renders the contract list.
   - From: `emberApp`
   - To: Merchant browser
   - Protocol: In-browser rendering

7. **Views contract detail**: Merchant selects a contract; Ember issues `GET /goods-gateway/contracts/:id` and renders the detail view.
   - From: `goodsVendorPortal_apiClient`
   - To: `continuumGoodsVendorPortalWeb` (Nginx) → `gpapiApi_unk_1d2b`
   - Protocol: REST/HTTPS

8. **Navigates to co-op agreements (optional)**: Merchant navigates to the co-op agreements section; same fetch pattern applies using `GET /goods-gateway/co-op-agreements` and `GET /goods-gateway/co-op-agreements/:id`.
   - From: `goodsVendorPortal_apiClient`
   - To: `continuumGoodsVendorPortalWeb` (Nginx) → `gpapiApi_unk_1d2b`
   - Protocol: REST/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No contracts found | GPAPI returns an empty list; portal renders an empty state | Merchant sees a "No contracts available" message |
| GPAPI unavailable | Nginx proxy returns 502/503; portal shows an error banner | Contract data cannot be displayed; merchant may retry later |
| Accounting service delay | GPAPI may return partial financial data or a timeout error; portal surfaces whatever GPAPI returns | Contract records shown without full financial detail, or an error is displayed |
| Unauthorized access to contract | GPAPI returns 403; portal routes to an access-denied view | Merchant cannot view contracts belonging to other vendors |

## Sequence Diagram

```
Merchant -> emberApp: Navigates to contracts section
emberApp -> goodsVendorPortal_apiClient: Request contract list
goodsVendorPortal_apiClient -> continuumGoodsVendorPortalWeb: GET /goods-gateway/contracts
continuumGoodsVendorPortalWeb -> gpapiApi_unk_1d2b: GET /contracts (proxied)
gpapiApi_unk_1d2b -> continuumAccountingService: Transmit/retrieve financial data
continuumAccountingService --> gpapiApi_unk_1d2b: Financial context
gpapiApi_unk_1d2b --> continuumGoodsVendorPortalWeb: 200 OK { contracts[] }
continuumGoodsVendorPortalWeb --> goodsVendorPortal_apiClient: Proxy response
goodsVendorPortal_apiClient --> emberApp: Populate ember-data store
emberApp --> Merchant: Render contract list
Merchant -> emberApp: Selects contract
goodsVendorPortal_apiClient -> continuumGoodsVendorPortalWeb: GET /goods-gateway/contracts/:id
continuumGoodsVendorPortalWeb -> gpapiApi_unk_1d2b: GET /contracts/:id (proxied)
gpapiApi_unk_1d2b --> continuumGoodsVendorPortalWeb: 200 OK { contract }
continuumGoodsVendorPortalWeb --> goodsVendorPortal_apiClient: Proxy response
goodsVendorPortal_apiClient --> emberApp: Render contract detail
```

## Related

- Architecture dynamic view: `dynamic-contract-and-agreement-management`
- Related flows: [Deal and Promotion Creation](deal-and-promotion-creation.md), [Analytics and Insights Reporting](analytics-and-insights-reporting.md)
