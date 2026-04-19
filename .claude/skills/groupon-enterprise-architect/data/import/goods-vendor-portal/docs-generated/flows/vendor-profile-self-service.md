---
service: "goods-vendor-portal"
title: "Vendor Profile Self-Service"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "vendor-profile-self-service"
flow_type: synchronous
trigger: "Merchant navigates to the self-service or vendor profile section and submits updates"
participants:
  - "emberApp"
  - "goodsVendorPortal_apiClient"
  - "continuumGoodsVendorPortalWeb"
  - "gpapiApi_unk_1d2b"
architecture_ref: "dynamic-vendor-profile-self-service"
---

# Vendor Profile Self-Service

## Summary

The Vendor Profile Self-Service flow allows goods merchants to manage their own vendor account details without requiring Groupon operations involvement. Merchants can update business addresses, contact information, and banking details through the self-service section of the portal. All changes are submitted to GPAPI, which validates and persists the updates. This flow is flagged as a SOX-relevant workflow because banking information changes have financial compliance implications.

## Trigger

- **Type**: user-action
- **Source**: Authenticated merchant navigates to the vendor profile or self-service section
- **Frequency**: On-demand; typically during onboarding, address changes, or banking detail updates

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Views and updates vendor profile information | — |
| Ember UI | Renders profile and self-service views; manages form state and validation | `emberApp` |
| API Client | Fetches and submits vendor and self-service data to the proxy endpoints | `goodsVendorPortal_apiClient` |
| Nginx (portal) | Proxies vendor and self-service requests to GPAPI | `continuumGoodsVendorPortalWeb` |
| GPAPI | Validates and persists vendor profile updates; enforces business rules on self-service changes | `gpapiApi_unk_1d2b` |

## Steps

1. **Loads vendor profile**: Merchant navigates to the vendor/self-service section; `emberApp` issues `GET /goods-gateway/vendors/:id` to fetch the current vendor record.
   - From: `goodsVendorPortal_apiClient`
   - To: `continuumGoodsVendorPortalWeb` (Nginx) → `gpapiApi_unk_1d2b`
   - Protocol: REST/HTTPS

2. **Loads self-service data**: `emberApp` concurrently fetches self-service profile data via `GET /goods-gateway/self-service`.
   - From: `goodsVendorPortal_apiClient`
   - To: `continuumGoodsVendorPortalWeb` (Nginx) → `gpapiApi_unk_1d2b`
   - Protocol: REST/HTTPS

3. **Renders profile form**: `emberApp` populates and renders the editable vendor profile and self-service forms with the fetched data.
   - From: `emberApp`
   - To: Merchant browser
   - Protocol: In-browser rendering

4. **Merchant edits profile fields**: Merchant updates address, contact, or banking information in the relevant form sections.
   - From: Merchant browser
   - To: `emberApp`
   - Protocol: DOM events

5. **Submits vendor profile update**: `goodsVendorPortal_apiClient` issues `PUT /goods-gateway/vendors/:id` with the updated vendor payload.
   - From: `goodsVendorPortal_apiClient`
   - To: `continuumGoodsVendorPortalWeb` (Nginx)
   - Protocol: REST/HTTPS

6. **Submits self-service update (if applicable)**: If the merchant updates self-service fields (addresses, banking), `goodsVendorPortal_apiClient` issues `PUT /goods-gateway/self-service`.
   - From: `goodsVendorPortal_apiClient`
   - To: `continuumGoodsVendorPortalWeb` (Nginx)
   - Protocol: REST/HTTPS

7. **Proxies and validates**: Nginx forwards both requests to GPAPI; GPAPI applies SOX-relevant validation rules, particularly for banking information changes.
   - From: `continuumGoodsVendorPortalWeb`
   - To: `gpapiApi_unk_1d2b`
   - Protocol: REST/HTTPS

8. **Returns confirmation**: GPAPI returns the updated records; `emberApp` refreshes the form with persisted values and displays a success notification.
   - From: `gpapiApi_unk_1d2b`
   - To: `emberApp` (via Nginx and apiClient)
   - Protocol: REST/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Validation error on profile update | GPAPI returns 422 with field-level errors; portal displays inline error messages | Merchant corrects the invalid fields and resubmits |
| Banking update flagged by compliance | GPAPI returns a compliance hold error; portal surfaces the message with guidance | Change is not applied immediately; merchant is directed to contact support or await manual review |
| GPAPI unavailable | Nginx returns 502/503; portal shows an error banner | Profile update is not saved; merchant may retry |
| Unauthorized vendor access | GPAPI returns 403 if the session does not have rights to the requested vendor ID | Merchant sees an access-denied message; they cannot modify other vendors' profiles |
| Concurrent edit conflict | GPAPI returns 409; portal informs merchant of a conflict | Merchant refreshes and resubmits |

## Sequence Diagram

```
Merchant -> emberApp: Navigates to self-service / vendor profile
emberApp -> goodsVendorPortal_apiClient: Fetch vendor and self-service data
goodsVendorPortal_apiClient -> continuumGoodsVendorPortalWeb: GET /goods-gateway/vendors/:id
goodsVendorPortal_apiClient -> continuumGoodsVendorPortalWeb: GET /goods-gateway/self-service
continuumGoodsVendorPortalWeb -> gpapiApi_unk_1d2b: GET /vendors/:id, GET /self-service (proxied)
gpapiApi_unk_1d2b --> continuumGoodsVendorPortalWeb: Vendor and self-service records
continuumGoodsVendorPortalWeb --> goodsVendorPortal_apiClient: Proxy responses
goodsVendorPortal_apiClient --> emberApp: Populate profile forms
Merchant -> emberApp: Edits and submits profile update
goodsVendorPortal_apiClient -> continuumGoodsVendorPortalWeb: PUT /goods-gateway/vendors/:id
goodsVendorPortal_apiClient -> continuumGoodsVendorPortalWeb: PUT /goods-gateway/self-service
continuumGoodsVendorPortalWeb -> gpapiApi_unk_1d2b: PUT /vendors/:id, PUT /self-service (proxied)
gpapiApi_unk_1d2b --> continuumGoodsVendorPortalWeb: 200 OK { updated records }
continuumGoodsVendorPortalWeb --> goodsVendorPortal_apiClient: Proxy response
goodsVendorPortal_apiClient --> emberApp: Update store, show success
emberApp --> Merchant: "Profile updated successfully"
```

## Related

- Architecture dynamic view: `dynamic-vendor-profile-self-service`
- Related flows: [Merchant Login](merchant-login.md), [Contract and Agreement Management](contract-and-agreement-management.md)
