---
service: "vouchercloud-idl"
title: "Offer Redemption (Wallet)"
generated: "2026-03-03"
type: flow
flow_name: "offer-redemption-wallet"
flow_type: synchronous
trigger: "Authenticated user sends POST /users/{id}/offers/{offerId}/redeem"
participants:
  - "continuumRestfulApi"
  - "continuumVcSqlDb"
  - "continuumVcMongoDb"
  - "continuumVcRedisCache"
  - "awsSqs_7c8e"
architecture_ref: "dynamic-vouchercloud-idl"
---

# Offer Redemption (Wallet)

## Summary

This flow describes the process by which an authenticated user clips/redeems an offer into their wallet. The `UserOffersService` validates the user session, checks offer validity, executes the redemption command against MongoDB and SQL, publishes an analytics event to AWS SQS, and returns the updated wallet state. Users can also save offers to wallet (deferred redemption) and remove saved offers.

## Trigger

- **Type**: api-call
- **Source**: Vouchercloud Web, White Label Web, or mobile app (authenticated user)
- **Frequency**: per-request (on-demand user action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Vouchercloud Restful API | Receives redemption request, orchestrates all steps | `continuumRestfulApi` |
| Vouchercloud SQL | Reads/writes wallet records and redemption history | `continuumVcSqlDb` |
| Vouchercloud MongoDB | Reads offer details; updates offer statistics | `continuumVcMongoDb` |
| Vouchercloud Redis | Session lookup for authenticated user | `continuumVcRedisCache` |
| AWS SQS (VcEventQueue) | Receives analytics event after redemption | `awsSqs_7c8e` |

## Steps

1. **Receives redemption request**: Authenticated user sends POST with session cookie (`ss-id`) and `X-ApiKey`.
   - From: Client (web/mobile)
   - To: `continuumRestfulApi`
   - Protocol: REST (HTTPS)

2. **Validates session**: ServiceStack resolves session from `ss-id` cookie via `continuumVcRedisCache` (or SQL fallback).
   - From: `continuumRestfulApi`
   - To: `continuumVcRedisCache`
   - Protocol: Redis

3. **Validates API key and authorisation**: `ApiKeyAuthorisation` and `AuthenticationRequiredAttribute` ensure valid API key and authenticated session.
   - From: `continuumRestfulApi` (filter)
   - To: `continuumVcSqlDb`
   - Protocol: SQL

4. **Loads offer details**: `IOfferDetailsQuery` fetches offer from MongoDB to validate it is active and eligible for the user's country.
   - From: `continuumRestfulApi`
   - To: `continuumVcMongoDb`
   - Protocol: MongoDB wire protocol

5. **Executes redemption command**: `IUserRedeemOfferCommand` writes the redemption record to SQL (user wallet entry) and increments offer use count in MongoDB.
   - From: `continuumRestfulApi`
   - To: `continuumVcSqlDb` (wallet write)
   - To: `continuumVcMongoDb` (statistics update)
   - Protocol: SQL + MongoDB wire protocol

6. **Publishes analytics event**: Redemption event is published to `VcEventQueue` SQS queue (via Lambda if `analyticsUseSqsLambda=true`).
   - From: `continuumRestfulApi`
   - To: `awsSqs_7c8e`
   - Protocol: AWS SDK (HTTPS)

7. **Returns redemption response**: Updated wallet/offer state returned to caller.
   - From: `continuumRestfulApi`
   - To: Client
   - Protocol: REST (HTTPS, JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unauthenticated request | HTTP 401 by `AuthenticationRequiredAttribute` | Request rejected |
| Offer not found or expired | `OfferNotFoundException` thrown; HTTP 404 returned | Redemption rejected |
| Offer already redeemed by user | `BadRequestException` thrown; HTTP 400 returned | Redemption rejected with error code |
| MongoDB write failure | HTTP 500; redemption not recorded | Transient failure; user can retry |
| SQS publish failure | Analytics event silently dropped; primary redemption succeeds | Redemption succeeds; analytics gap |
| Vouchercloud/Groupon staff email attempt | Redemption blocked for `@vouchercloud.` / `@groupon.` email suffixes | HTTP 400 returned |

## Sequence Diagram

```
Client -> continuumRestfulApi: POST /users/123/offers/456/redeem (X-ApiKey, ss-id cookie)
continuumRestfulApi -> continuumVcRedisCache: GET session (ss-id)
continuumVcRedisCache --> continuumRestfulApi: User session
continuumRestfulApi -> continuumVcMongoDb: GET offer details (offerId=456)
continuumVcMongoDb --> continuumRestfulApi: Offer document (active, country=GB)
continuumRestfulApi -> continuumVcSqlDb: INSERT wallet record (userId=123, offerId=456)
continuumRestfulApi -> continuumVcMongoDb: INCREMENT offer use count
continuumRestfulApi -> awsSqs_7c8e: PUBLISH RedemptionEvent (userId=123, offerId=456)
continuumRestfulApi --> Client: 200 OK { offer: { redeemed: true, ... } }
```

## Related

- Architecture dynamic view: `dynamic-vouchercloud-idl`
- Related flows: [Offer Discovery and Search](offer-discovery-and-search.md), [Reward Redemption (Giftcloud)](reward-redemption-giftcloud.md), [User Authentication](user-authentication.md)
