---
service: "vouchercloud-idl"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key, session-cookie, oauth2, jwt]
---

# API Surface

## Overview

The Vouchercloud Restful API (`continuumRestfulApi`) is a multi-tenant REST API hosted via ServiceStack 4.0.48, available at `https://restfulapi.vouchercloud.com`. It serves offer discovery, merchant data, user account management, rewards, affiliate tracking, and content to vouchercloud web, mobile, and partner consumers. All requests are keyed by an `X-ApiKey` header; authenticated user endpoints additionally require a session cookie (`ss-id` / `ss-pid`). An OpenAPI/Swagger UI is published at `https://restfulapi.vouchercloud.com/swagger-ui/`.

## Endpoints

### Offers

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/offers` | List offers (paginated, filterable by country/category/type) | API key |
| GET | `/offers/{id}` | Offer detail by ID | API key |
| GET | `/offers/featured` | Featured offer listings | API key |
| GET | `/offers/popular` | Popular offers | API key |
| GET | `/offers/expiring` | Soon-to-expire offers | API key |
| GET | `/offers/expired` | Expired offers | API key |
| GET | `/offers/latest` | Latest/newest offers | API key |
| GET | `/offers/search` | Full-text search via Algolia | API key |
| GET | `/offers/nearestbranch` | Geolocation-filtered nearest branch offers | API key |
| GET | `/offers/statistics` | Offer statistics (use counts) | API key |
| GET | `/offers/globalstats` | Aggregate global offer statistics | API key |
| GET | `/offers/categories` | Offer category tree | API key |
| POST | `/offers/{id}/reject` | Report/reject an offer | API key |
| POST | `/offers/communitycode` | Submit a community voucher code | API key + session |

### Merchants

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchants` | List merchants | API key |
| GET | `/merchants/{id}` | Merchant detail | API key |
| GET | `/merchants/{id}/offers` | Offers for a merchant | API key |
| GET | `/merchants/{id}/branches` | Branch listing for a merchant | API key |
| GET | `/merchants/{id}/branches/{branchId}/offers` | Offers at a specific branch | API key |
| GET | `/merchants/{id}/popular` | Popular offers for merchant | API key |
| GET | `/merchants/{id}/expiring` | Expiring offers for merchant | API key |
| GET | `/merchants/{id}/latest` | Latest offers for merchant | API key |
| GET | `/merchants/{id}/similar` | Similar/related merchants | API key |
| GET | `/merchants/{id}/variants` | International variants of a merchant | API key |

### Users and Authentication

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/auth/credentials` | Email/password login | API key |
| POST | `/auth/facebook` | Facebook access token login | API key |
| POST | `/auth/google` | Google Sign-In token login | API key |
| POST | `/auth/apple` | Apple Sign-In token login | API key |
| POST | `/auth/logout` | Session logout | API key + session |
| GET | `/users/{id}` | Get user profile | API key + session |
| PUT | `/users/{id}` | Update user profile | API key + session |
| DELETE | `/users/{id}` | Delete user account | API key + session |
| GET | `/users/{id}/stats` | User engagement statistics | API key + session |
| GET | `/users/{id}/pushpreferences` | Push notification preferences | API key + session |
| PUT | `/users/{id}/pushpreferences` | Update push notification preferences | API key + session |
| POST | `/users/{id}/feedback` | Submit user feedback | API key + session |
| POST | `/users/forgotpassword` | Trigger password reset email | API key |
| POST | `/users/resetpassword` | Complete password reset | API key |

### User Wallet / Offers

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/users/{id}/offers` | User saved/wallet offers | API key + session |
| GET | `/users/{id}/offers/history` | Offer redemption history | API key + session |
| POST | `/users/{id}/offers/{offerId}/save` | Save offer to wallet | API key + session |
| POST | `/users/{id}/offers/{offerId}/redeem` | Redeem/clip an offer | API key + session |
| DELETE | `/users/{id}/offers/{offerId}` | Remove offer from wallet | API key + session |

### User Rewards

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/users/{id}/rewards` | List user rewards | API key + session |
| GET | `/users/{id}/rewards/{rewardId}` | Reward detail | API key + session |
| GET | `/users/{id}/rewards/options` | Available reward options | API key + session |
| POST | `/users/{id}/rewards/redeem` | Redeem reward (Giftcloud) | API key + session |
| GET | `/users/{id}/rewards/{rewardId}/download` | Download reward | API key + session |
| GET | `/users/{id}/cloudcoins` | CloudCoins balance | API key + session |

### Affiliate

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/out/offer/{OfferId}` | Affiliate redirect for offer outlink | API key |
| GET | `/in/offers/{OfferId}` | Offer landing page inlink | API key |
| POST | `/affiliate/purchase` | Track affiliate purchase | API key |

### Other

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/categories` | Category listing | API key |
| GET | `/email` | Email template content | API key |
| GET | `/email/offer` | Email offer content | API key |
| GET | `/competitions/{id}` | Competition details | API key |
| POST | `/competitions/{id}/entry` | Enter a competition | API key + session |
| GET | `/genie/merchants` | All merchants by country (Genie feed) | API key |
| POST | `/syncqueue/merchant/insert` | Insert merchant into sync queue | API key (internal) |
| POST | `/syncqueue/merchant/acquire` | Acquire merchant sync job | API key (internal) |
| POST | `/syncqueue/merchant/resolve` | Resolve merchant sync job | API key (internal) |
| POST | `/syncqueue/merchant/failed` | Mark merchant sync job failed | API key (internal) |
| POST | `/syncqueue/merchant/recovery` | Recover failed sync job | API key (internal) |
| POST | `/webhooks/shortstack` | ShortStack registration webhook | API key |
| GET | `/restful-api-heartbeat.html` | Health check / heartbeat | None |

## Request/Response Patterns

### Common headers
- `X-ApiKey`: Required on all requests. Identifies the API consumer (website, iOS, Android, external partner).
- `Cookie: ss-id` / `ss-pid`: Session cookies issued by ServiceStack on successful authentication.
- `Cookie: ss-opt`: Session persistence option cookie.

### Error format
ServiceStack standard error envelope:
```json
{
  "responseStatus": {
    "errorCode": "string",
    "message": "string",
    "stackTrace": "string (debug only)"
  }
}
```

### Pagination
Paginated endpoints accept `page` and `pageSize` query parameters. Default page size is `20` (configured via `defaultPageSize="20"` in `Web.config` `restfulApi` section). Responses include a `links.next` URL when more results are available.

## Rate Limits

> No rate limiting configured at the application layer. Rate limiting is managed at the AWS ALB / infrastructure level.

## Versioning

No URL versioning is applied. The public API is versioned implicitly by the `continuumRestfulApi` container. Breaking changes are managed via partner coordination.

## OpenAPI / Schema References

Swagger UI: `https://restfulapi.vouchercloud.com/swagger-ui/` (configured via `ServiceStack.Api.Swagger` 4.0.48 in `IDL.Api.Restful/packages.config`).
