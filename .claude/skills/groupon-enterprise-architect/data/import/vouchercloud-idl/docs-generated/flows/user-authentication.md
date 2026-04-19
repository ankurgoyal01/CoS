---
service: "vouchercloud-idl"
title: "User Authentication"
generated: "2026-03-03"
type: flow
flow_name: "user-authentication"
flow_type: synchronous
trigger: "Consumer sends POST /auth/credentials, /auth/facebook, /auth/google, or /auth/apple"
participants:
  - "continuumRestfulApi"
  - "continuumVcSqlDb"
  - "continuumVcRedisCache"
architecture_ref: "dynamic-vouchercloud-idl"
---

# User Authentication

## Summary

This flow covers all user authentication paths in the Vouchercloud Restful API: email/password (credentials), Facebook access token, Google Sign-In token, and Apple Sign-In. On successful authentication, a ServiceStack session is created in Redis (and optionally persisted in SQL via `ISqlBackedCacheClient`). The flow also handles affiliate link tracking updates and email campaign subscription state on login.

## Trigger

- **Type**: api-call
- **Source**: Vouchercloud Web, White Label Web, or mobile apps (iOS/Android)
- **Frequency**: per-request (on-demand user login)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Vouchercloud Restful API | Receives and validates auth request; orchestrates auth providers | `continuumRestfulApi` |
| External OAuth provider (Facebook/Google/Apple) | Validates third-party access token | External |
| Vouchercloud SQL | User credential lookup (email/password); session persistence | `continuumVcSqlDb` |
| Vouchercloud Redis | Session storage (`ss-id`, `ss-pid` cookies) | `continuumVcRedisCache` |

## Steps

1. **Receives authentication request**: Client sends POST with credentials or OAuth token and `X-ApiKey` header.
   - From: Mobile app / Web client
   - To: `continuumRestfulApi`
   - Protocol: REST (HTTPS)

2. **Validates API key**: `ApiKeyAuthorisation` filter validates `X-ApiKey`.
   - From: `continuumRestfulApi` (filter)
   - To: `continuumVcSqlDb`
   - Protocol: SQL

3. **Dispatches to auth provider**: `AuthenticationService` selects the appropriate `BaseAuthProvider` based on request type (`VouchercloudCredentialsAuthProvider`, `FacebookAccessTokenAuthProvider`, `GoogleSignInTokenAuthProvider`, `AppleSignInTokenAuthProvider`).
   - From: `continuumRestfulApi`
   - To: `continuumRestfulApi` (internal dispatch)
   - Protocol: direct

4. **Validates external token (OAuth flows)**: For Facebook, Google, or Apple — auth provider calls the external identity provider to validate the access/identity token.
   - From: `continuumRestfulApi`
   - To: Facebook Graph API / Google Auth / Apple ID (`appleid.apple.com/auth/keys`)
   - Protocol: REST (HTTPS)

5. **Looks up user in SQL**: Auth provider queries `VouchercloudAuthRepository` or `VouchercloudAuthRepositorySql` to find or create the user record.
   - From: `continuumRestfulApi`
   - To: `continuumVcSqlDb`
   - Protocol: SQL (Dapper)

6. **Creates ServiceStack session**: On successful validation, ServiceStack creates a session identified by `ss-id` cookie.
   - From: `continuumRestfulApi`
   - To: `continuumVcRedisCache`
   - Protocol: Redis

7. **Updates affiliate link tracking**: If an affiliate tracking ID is present in the request, `IUpdateAffiliateLinkTrackingCommand` updates the affiliate record in SQL.
   - From: `continuumRestfulApi`
   - To: `continuumVcSqlDb`
   - Protocol: SQL

8. **Updates email campaign subscriptions**: `IUserEmailCampaignSubscriptionsUpdateCommand` updates subscription state on login.
   - From: `continuumRestfulApi`
   - To: `continuumVcSqlDb` / `continuumVcMongoDb`
   - Protocol: SQL / MongoDB

9. **Returns authentication response**: Session cookies (`ss-id`, `ss-pid`, `ss-opt`) set in HTTP response; user profile data returned.
   - From: `continuumRestfulApi`
   - To: Client
   - Protocol: REST (HTTPS, JSON + Set-Cookie headers)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid email/password | HTTP 401 returned; account lockout after `maxLoginAttempts=3` failures | Login rejected; lockout for `accountLockoutDuration=30` minutes |
| Invalid Facebook/Google/Apple token | HTTP 401 returned by auth provider | Login rejected |
| User not found (OAuth new user) | New user record created in SQL | Registration-on-first-login |
| Redis session write failure | HTTP 500; session not created | Login fails; user must retry |
| Account locked out | HTTP 403 returned | Login rejected until lockout expires |

## Sequence Diagram

```
Client -> continuumRestfulApi: POST /auth/facebook { accessToken: "..." } (X-ApiKey)
continuumRestfulApi -> continuumRestfulApi: ValidateApiKey
continuumRestfulApi -> FacebookGraphApi: Validate access token
FacebookGraphApi --> continuumRestfulApi: User profile (id, email, name)
continuumRestfulApi -> continuumVcSqlDb: Lookup / create user by email
continuumVcSqlDb --> continuumRestfulApi: User record
continuumRestfulApi -> continuumVcRedisCache: SET session (ss-id)
continuumVcSqlDb --> continuumRestfulApi: (affiliate/subscriptions updated)
continuumRestfulApi --> Client: 200 OK { user: {...} } Set-Cookie: ss-id, ss-pid
```

## Related

- Architecture dynamic view: `dynamic-vouchercloud-idl`
- Related flows: [Offer Redemption (Wallet)](offer-redemption-wallet.md), [Reward Redemption (Giftcloud)](reward-redemption-giftcloud.md)
