---
service: "vouchercloud-idl"
title: "Reward Redemption (Giftcloud)"
generated: "2026-03-03"
type: flow
flow_name: "reward-redemption-giftcloud"
flow_type: synchronous
trigger: "Authenticated user sends POST /users/{id}/rewards/redeem"
participants:
  - "continuumRestfulApi"
  - "continuumVcSqlDb"
  - "continuumVcMongoDb"
  - "continuumVcRedisCache"
  - "awsSns_2b51"
architecture_ref: "dynamic-vouchercloud-idl"
---

# Reward Redemption (Giftcloud)

## Summary

When an authenticated user redeems accumulated reward points, the `UserRewardsService` validates eligibility, calls the per-country Giftcloud API to initialise and claim a gift reward, stores the reward record, and returns the reward details to the client. If the Giftcloud initialisation fails, a failure event is published to AWS SNS (`Vouchercloud-{env}-RewardsInitialiseFailed`) for downstream alerting. The flow supports multiple countries (GB, US, IE, FR, DE, IT, AU, ES, USgroupon) each with distinct Giftcloud credentials.

## Trigger

- **Type**: api-call
- **Source**: Authenticated user via Vouchercloud Web or mobile app
- **Frequency**: per-request (on-demand, lower volume than offer redemption)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Vouchercloud Restful API | Receives redemption request, orchestrates Giftcloud call | `continuumRestfulApi` |
| Vouchercloud Redis | Session lookup for authenticated user | `continuumVcRedisCache` |
| Vouchercloud SQL | Reads reward balance; writes reward record | `continuumVcSqlDb` |
| Vouchercloud MongoDB | Reads offer/merchant data for reward validation | `continuumVcMongoDb` |
| Giftcloud API | External rewards platform — initialises and claims gift card | External |
| AWS SNS | Receives `RewardsInitialiseFailed` event on Giftcloud failure | `awsSns_2b51` |

## Steps

1. **Receives reward redemption request**: Authenticated user sends POST with `X-ApiKey` and session cookie.
   - From: Client (web/mobile)
   - To: `continuumRestfulApi`
   - Protocol: REST (HTTPS)

2. **Validates session**: ServiceStack resolves session from Redis.
   - From: `continuumRestfulApi`
   - To: `continuumVcRedisCache`
   - Protocol: Redis

3. **Validates user eligibility**: `UserRewardsService` checks reward balance and country eligibility via `IUserRewardsQuery` against SQL.
   - From: `continuumRestfulApi`
   - To: `continuumVcSqlDb`
   - Protocol: SQL

4. **Loads reward options**: `IRewardOptionsQuery` retrieves available reward options for the user's country.
   - From: `continuumRestfulApi`
   - To: `continuumVcMongoDb` / `continuumVcSqlDb`
   - Protocol: MongoDB / SQL

5. **Initialises reward via Giftcloud API**: `IUserRedeemRewardCommand` calls `Coupons.GiftcloudApiClient` with the per-country credentials (`IDL-VCAPI-GCAPI{country}*`). Rewards `validationEnabled=true` and `isTestMode=false` in production.
   - From: `continuumRestfulApi`
   - To: Giftcloud API (`https://api.giftcloud.com`)
   - Protocol: REST (HTTPS)

6. **Handles Giftcloud failure**: If Giftcloud returns an error, `INotificationService` publishes a `RewardsInitialiseFailed` message to SNS.
   - From: `continuumRestfulApi`
   - To: `awsSns_2b51` (`arn:aws:sns:eu-west-1:...:Vouchercloud-{env}-RewardsInitialiseFailed`)
   - Protocol: AWS SDK (HTTPS)

7. **Stores reward record**: On success, reward record written to SQL with status and Giftcloud reference.
   - From: `continuumRestfulApi`
   - To: `continuumVcSqlDb`
   - Protocol: SQL

8. **Returns reward response**: Reward details (gift card info, download URL) returned to client.
   - From: `continuumRestfulApi`
   - To: Client
   - Protocol: REST (HTTPS, JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unauthenticated request | HTTP 401 | Request rejected |
| Insufficient reward balance | HTTP 400 via `BadRequestException` | Redemption rejected |
| Giftcloud API failure | SNS `RewardsInitialiseFailed` published; HTTP 500 returned | Reward not claimed; ops alerted via OpsGenie |
| Giftcloud test mode enabled in production | Rewards not actually claimed (`isTestMode=true`) | Silent no-op; verify config |
| Country not supported for rewards | HTTP 400 — country not in `supportedCountries` config | Redemption rejected |
| Unclaimed reward expiry | Rewards expire after `unclaimedExpiryMonths=1` (configurable) | Reward invalidated automatically |

## Sequence Diagram

```
Client -> continuumRestfulApi: POST /users/123/rewards/redeem { rewardOptionId: "gold-card" } (X-ApiKey, ss-id)
continuumRestfulApi -> continuumVcRedisCache: GET session (ss-id)
continuumVcRedisCache --> continuumRestfulApi: User session { country: "GB" }
continuumRestfulApi -> continuumVcSqlDb: GET reward balance (userId=123)
continuumVcSqlDb --> continuumRestfulApi: Balance sufficient
continuumRestfulApi -> GiftcloudApi: POST /initialise (country=GB, credentials=GCAPI-GB-*)
GiftcloudApi --> continuumRestfulApi: SUCCESS { giftRef: "gc-abc123" }
continuumRestfulApi -> continuumVcSqlDb: INSERT reward record (userId=123, giftRef, status=claimed)
continuumRestfulApi --> Client: 200 OK { reward: { giftRef: "gc-abc123", downloadUrl: "..." } }

--- Failure path ---
GiftcloudApi --> continuumRestfulApi: ERROR
continuumRestfulApi -> awsSns_2b51: PUBLISH RewardsInitialiseFailed (userId=123, country=GB)
continuumRestfulApi --> Client: 500 Internal Server Error
```

## Related

- Architecture dynamic view: `dynamic-vouchercloud-idl`
- Related flows: [User Authentication](user-authentication.md), [Offer Redemption (Wallet)](offer-redemption-wallet.md)
