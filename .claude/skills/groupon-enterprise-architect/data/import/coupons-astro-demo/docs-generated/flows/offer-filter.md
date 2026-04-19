---
service: "coupons-astro-demo"
title: "Offer Filter"
generated: "2026-03-03"
type: flow
flow_name: "offer-filter"
flow_type: synchronous
trigger: "User clicks a filter tab in the OfferFilter Svelte component"
participants:
  - "OfferFilter (Svelte)"
  - "offers store (Svelte)"
  - "OffersList (Svelte)"
  - "OfferCard (Svelte)"
architecture_ref: "CouponsAstroWebAppComponents"
---

# Offer Filter

## Summary

After the merchant page has been server-rendered and delivered to the browser, the `OfferFilter` Svelte component enables client-side filtering of the visible offer list without any further server requests. When a user clicks a filter tab (All, Deals, Codes, Sales, Rewards), the component updates a shared Svelte writable store (`selectedFilter`), which triggers a derived store (`filteredOffers`) to recompute the visible subset. The `OffersList` component reactively re-renders based on `filteredOffers`. Offer type normalization maps VoucherCloud offer type strings (e.g., `OnlineDeal`, `OnlineCode`) to canonical category labels.

## Trigger

- **Type**: user-action
- **Source**: User clicks a filter tab in `OfferFilter.svelte`
- **Frequency**: On-demand, per user interaction (client-side only)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| OfferFilter (Svelte) | Renders filter tabs; writes `selectedFilter` store on tab click | `uiComponents` |
| offers store (`src/lib/stores/offers.ts`) | Svelte writable/derived stores: `baseOffers`, `selectedFilter`, `filteredOffers`, `counts` | `uiComponents` |
| OffersList (Svelte) | Subscribes to `filteredOffers`; renders the visible offer cards | `uiComponents` |
| OfferCard (Svelte) | Renders individual offer with type label, CTA button, and redemption count | `uiComponents` |

## Steps

1. **SSR hydration**: On page load, the server has already rendered all offers into HTML. During client-side hydration, `OffersList` initializes the `baseOffers` writable store with the full offer array received as a prop from the route handler.
   - From: `couponsRouteHandler` (SSR prop)
   - To: `baseOffers` Svelte store
   - Protocol: Astro island hydration (client-side)

2. **Compute initial counts**: The `counts` derived store calculates per-category totals from `baseOffers` by calling `normalizeOfferType()` on each offer's `OfferType` field. Normalization rules:
   - `OnlineDeal` → `deal`
   - `OnlineCode` → `code`
   - `OnlineSale` / `OnlineSales` → `sale`
   - `OnlineReward` / `OnlineRewards` → `reward`
   - `OfferFilter` reads `counts` to display per-tab counts alongside labels.
   - From: `baseOffers` store
   - To: `counts` derived store
   - Protocol: Svelte reactivity

3. **User clicks filter tab**: User selects a tab (e.g., "Deals"). `OfferFilter` calls `selectedFilter.set('deal')`, updating the writable store.
   - From: User interaction
   - To: `selectedFilter` store
   - Protocol: DOM event → Svelte store write

4. **Recompute filtered offers**: The `filteredOffers` derived store reacts to `selectedFilter` changing. If `selectedFilter` is `'all'`, returns all `baseOffers`. Otherwise, filters to offers where `normalizeOfferType(offer.OfferType) === selectedFilter`.
   - From: `selectedFilter` store
   - To: `filteredOffers` derived store
   - Protocol: Svelte reactivity

5. **Re-render offer list**: `OffersList` is subscribed to `filteredOffers`. Svelte's reactive rendering updates the DOM to show only the filtered offer cards. Each `OfferCard` displays:
   - Type label tag (Deal, Coupon, Sale, Reward)
   - Offer title and description
   - CTA button (Get Deal, Get Code, View Sale, Get Gift Card)
   - Redemption count in the last 24 hours (`OfferStatistics.RedemptionCount24Hr`)
   - From: `filteredOffers` store
   - To: `OffersList` → `OfferCard` instances
   - Protocol: Svelte reactivity / DOM update

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Offer has null/unknown OfferType | `normalizeOfferType()` returns `null`; offer is excluded from category counts but included in `'all'` view | No error; offer renders in all-tab view only |
| `baseOffers` is empty array | `counts` returns all zeros; `filteredOffers` returns empty array | OffersList renders empty; no error |
| Filter tab selected with no matching offers | `filteredOffers` returns empty array | OffersList renders empty section; user sees no offer cards |

## Sequence Diagram

```
User         OfferFilter         selectedFilter store    filteredOffers store    OffersList
  |               |                      |                       |                   |
  |--click tab--->|                      |                       |                   |
  |               |--set('deal')-------->|                       |                   |
  |               |                      |--derived recompute--->|                   |
  |               |                      |  filter baseOffers    |                   |
  |               |                      |  where type==='deal'  |                   |
  |               |                      |                       |--reactive update-->|
  |               |                      |                       |                   |--render OfferCards-->DOM
  |<--updated offer list shown-----------------------------------------DOM update----|
```

## Related

- Architecture dynamic view: `CouponsAstroWebAppComponents`
- Related flows: [Merchant Page Request](merchant-page-request.md)
- Store definition: `src/lib/stores/offers.ts`
