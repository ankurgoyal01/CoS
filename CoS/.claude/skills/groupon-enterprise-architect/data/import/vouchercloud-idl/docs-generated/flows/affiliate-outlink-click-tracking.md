---
service: "vouchercloud-idl"
title: "Affiliate Outlink and Click Tracking"
generated: "2026-03-03"
type: flow
flow_name: "affiliate-outlink-click-tracking"
flow_type: synchronous
trigger: "User or crawler sends GET /out/offer/{OfferId} (affiliate outlink redirect)"
participants:
  - "continuumRestfulApi"
  - "continuumVcMongoDb"
  - "continuumVcSqlDb"
  - "continuumVcRedisCache"
  - "awsSqs_7c8e"
architecture_ref: "dynamic-vouchercloud-idl"
---

# Affiliate Outlink and Click Tracking

## Summary

When a user clicks an affiliate offer link on vouchercloud.com or a partner site, the request hits `GET /out/offer/{OfferId}` on the Restful API. The `AffiliateService` loads offer details, records a click in SQL, resolves the affiliate tracking URL (SkimLinks or direct), fires an optional visit-site analytics event to SQS, and redirects the user to the merchant/partner site. This flow is the revenue-generating event for affiliate-backed offers.

## Trigger

- **Type**: api-call (user click or automated link verification)
- **Source**: `continuumVcWebSite`, `continuumWhiteLabelWebSite`, or direct link (mobile/partner)
- **Frequency**: per-request (high volume during peak hours)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Vouchercloud Restful API | Receives click, orchestrates tracking and redirect | `continuumRestfulApi` |
| Vouchercloud MongoDB | Loads offer details and affiliate URL | `continuumVcMongoDb` |
| Vouchercloud SQL | Records affiliate click; resolves tracking ID | `continuumVcSqlDb` |
| Vouchercloud Redis | Response cache lookup for offer details | `continuumVcRedisCache` |
| AWS SQS (VcEventQueue) | Receives VisitSite analytics event | `awsSqs_7c8e` |

## Steps

1. **Receives outlink request**: User browser follows `/out/offer/{OfferId}` with `X-ApiKey` header.
   - From: Browser / mobile app
   - To: `continuumRestfulApi`
   - Protocol: REST (HTTPS GET)

2. **Validates API key**: `ApiKeyAuthorisation` filter validates `X-ApiKey`.
   - From: `continuumRestfulApi` (filter)
   - To: `continuumVcSqlDb`
   - Protocol: SQL

3. **Loads offer details (cached)**: `IApiCacheHandler` checks Redis for cached offer; on miss, loads from MongoDB.
   - From: `continuumRestfulApi`
   - To: `continuumVcRedisCache` then `continuumVcMongoDb`
   - Protocol: Redis / MongoDB wire protocol

4. **Validates offer is active**: Checks offer status and country eligibility.
   - From: `continuumRestfulApi` (internal)
   - To: (in-memory validation)
   - Protocol: direct

5. **Generates affiliate tracking ID**: `IAffiliateTrackingIdQuery` resolves the affiliate tracking identifier for the offer (SkimLinks publisher ID or direct partner ID).
   - From: `continuumRestfulApi`
   - To: `continuumVcSqlDb`
   - Protocol: SQL

6. **Executes affiliate redirect command**: `IAffiliateRedirectCommand` records the click event in SQL (clickId, offerId, userId, timestamp, affiliate network).
   - From: `continuumRestfulApi`
   - To: `continuumVcSqlDb`
   - Protocol: SQL (Dapper)

7. **Fires VisitSite analytics event**: For eligible app types (`_fireVisitSiteEventOnlyForAppTypes`), a `VisitSite` event is published to `VcEventQueue` via SQS.
   - From: `continuumRestfulApi`
   - To: `awsSqs_7c8e`
   - Protocol: AWS SDK (HTTPS)

8. **Redirects user to merchant**: HTTP 302 redirect to the affiliate-tagged merchant URL.
   - From: `continuumRestfulApi`
   - To: Browser (merchant site / SkimLinks)
   - Protocol: HTTP 302

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Offer not found | `OfferNotFoundException`; HTTP 404 returned | No redirect; error returned |
| Offer expired or inactive | `BadRequestException`; HTTP 400 returned | No redirect |
| SQL click record write failure | HTTP 500; click not recorded | Redirect does not happen; transient failure |
| SQS analytics publish failure | Analytics event silently dropped; redirect proceeds | User redirected successfully; analytics gap |
| Invalid API key | HTTP 401 | Request rejected |

## Sequence Diagram

```
Browser -> continuumRestfulApi: GET /out/offer/789 (X-ApiKey)
continuumRestfulApi -> continuumVcRedisCache: GET offer:789
continuumVcRedisCache --> continuumRestfulApi: MISS
continuumRestfulApi -> continuumVcMongoDb: GET offer document (offerId=789)
continuumVcMongoDb --> continuumRestfulApi: Offer { affiliateUrl, status=active }
continuumRestfulApi -> continuumVcSqlDb: GET affiliateTrackingId (offerId=789)
continuumVcSqlDb --> continuumRestfulApi: trackingId
continuumRestfulApi -> continuumVcSqlDb: INSERT affiliateClick (offerId=789, trackingId, timestamp)
continuumRestfulApi -> awsSqs_7c8e: PUBLISH VisitSiteEvent (offerId=789)
continuumRestfulApi --> Browser: 302 Redirect -> https://merchant.com/offer?ref=vc_trackingId
```

## Related

- Architecture dynamic view: `dynamic-vouchercloud-idl`
- Related flows: [Offer Discovery and Search](offer-discovery-and-search.md), [Offer Redemption (Wallet)](offer-redemption-wallet.md)
