---
service: "api-lazlo-sox"
title: "User Authentication Flow"
generated: "2026-03-03"
type: flow
flow_name: "user-authentication-flow"
flow_type: synchronous
trigger: "User login, OTP request, or session validation"
participants:
  - "continuumApiLazloService_httpApi"
  - "continuumApiLazloService_commonFiltersAndViews"
  - "continuumApiLazloService_usersApi"
  - "continuumApiLazloService_usersBlsModule"
  - "continuumApiLazloService_downstreamServiceClients"
  - "continuumApiLazloService_redisAccess"
  - "continuumApiLazloRedisCache"
architecture_ref: "dynamic-api-lazlo-user-auth"
---

# User Authentication Flow

## Summary

This flow describes how API Lazlo handles user authentication, including account lookups, OTP (one-time password) generation and validation, email verification, and session management. The Users and Accounts API controller receives authentication requests, delegates to the Users BLS module for orchestration, which in turn calls downstream identity and consumer services. Session-like state and user context are cached in Redis for subsequent authenticated requests.

## Trigger

- **Type**: User action
- **Source**: Mobile app login screen, session refresh, OTP request, email verification link
- **Frequency**: On demand (per user login attempt, session validation)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Mobile Client | Initiates authentication request | External |
| HTTP Mobile API Gateway | Receives and routes the auth request | `continuumApiLazloService_httpApi` |
| Common Filters, Params and Views | Validates request headers, applies locale | `continuumApiLazloService_commonFiltersAndViews` |
| Users and Accounts API | Handles /users auth endpoints (OTP, login, email verification) | `continuumApiLazloService_usersApi` |
| Users Domain BLS Module | Orchestrates auth flows (UsersService, BLSUserServiceImpl) | `continuumApiLazloService_usersBlsModule` |
| Downstream Service Clients | Calls Users Service, Consumer Service for identity resolution | `continuumApiLazloService_downstreamServiceClients` |
| Redis Cache Access | Caches session-like state and user context | `continuumApiLazloService_redisAccess` |
| API Lazlo Redis Cache | Distributed cache for session and user data | `continuumApiLazloRedisCache` |

## Steps

1. **Client sends auth request**: Mobile client sends an authentication request (e.g., POST `/api/mobile/{countryCode}/users/otp` for OTP, or login credentials).
   - From: Mobile Client
   - To: `continuumApiLazloService_httpApi`
   - Protocol: HTTPS/JSON

2. **Apply common filters**: Request passes through locale, header, and basic validation filters. No full authentication is required at this stage (pre-auth endpoint).
   - From: `continuumApiLazloService_httpApi`
   - To: `continuumApiLazloService_commonFiltersAndViews`
   - Protocol: in-process

3. **Route to Users API**: The HTTP gateway routes the request to the Users and Accounts API controller based on the `/users` path prefix.
   - From: `continuumApiLazloService_httpApi`
   - To: `continuumApiLazloService_usersApi`
   - Protocol: in-process

4. **Delegate to Users BLS**: The Users controller delegates the authentication flow to the Users Domain BLS Module via EventBus promises. The BLS module orchestrates the multi-step auth sequence.
   - From: `continuumApiLazloService_usersApi`
   - To: `continuumApiLazloService_usersBlsModule`
   - Protocol: Lazlo EventBus / Promises

5. **Call Users Service**: The BLS module calls the downstream Users Service for identity lookup, credential validation, or OTP generation.
   - From: `continuumApiLazloService_usersBlsModule`
   - To: `continuumApiLazloService_downstreamServiceClients` (UsersServiceClient)
   - Protocol: HTTP/JSON over internal network

6. **Call Consumer Service**: For profile enrichment and consumer context, the BLS module calls the Consumer Service.
   - From: `continuumApiLazloService_usersBlsModule`
   - To: `continuumApiLazloService_downstreamServiceClients` (Consumer client)
   - Protocol: HTTP/JSON over internal network

7. **Cache user context**: On successful authentication, user context and session-like data are cached in Redis for fast access on subsequent authenticated requests.
   - From: `continuumApiLazloService_usersBlsModule`
   - To: `continuumApiLazloService_redisAccess`
   - Protocol: Redis client

8. **Return auth response**: The composed authentication response (user profile, session token, OTP confirmation) is returned to the mobile client.
   - From: `continuumApiLazloService_httpApi`
   - To: Mobile Client
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid credentials | Users Service returns auth failure | 401 Unauthorized returned to client |
| OTP expired | Users Service validates OTP TTL | 401 Unauthorized with expired OTP message |
| Users Service unavailable | Timeout and error from downstream client | 502 Bad Gateway; user cannot authenticate |
| Redis cache unavailable | Authentication proceeds without caching (subsequent requests slower) | Successful auth but degraded session performance |
| Rate limit on OTP requests | Upstream rate limiting or downstream Users Service rate control | 429 Too Many Requests |
| Email verification token invalid | Users Service validates token | 400 Bad Request with validation error |

## Sequence Diagram

```
Mobile Client -> continuumApiLazloService_httpApi: POST /api/mobile/{cc}/users/otp
continuumApiLazloService_httpApi -> continuumApiLazloService_commonFiltersAndViews: Apply filters
continuumApiLazloService_commonFiltersAndViews --> continuumApiLazloService_httpApi: Filters applied
continuumApiLazloService_httpApi -> continuumApiLazloService_usersApi: Route to Users controller
continuumApiLazloService_usersApi -> continuumApiLazloService_usersBlsModule: Delegate auth flow
continuumApiLazloService_usersBlsModule -> continuumApiLazloService_downstreamServiceClients: Call Users Service (validate/generate OTP)
continuumApiLazloService_downstreamServiceClients --> continuumApiLazloService_usersBlsModule: Auth result
continuumApiLazloService_usersBlsModule -> continuumApiLazloService_downstreamServiceClients: Call Consumer Service (enrich profile)
continuumApiLazloService_downstreamServiceClients --> continuumApiLazloService_usersBlsModule: Consumer context
continuumApiLazloService_usersBlsModule -> continuumApiLazloService_redisAccess: Cache user context
continuumApiLazloService_redisAccess -> continuumApiLazloRedisCache: SET user session data
continuumApiLazloRedisCache --> continuumApiLazloService_redisAccess: OK
continuumApiLazloService_usersBlsModule --> continuumApiLazloService_usersApi: Auth result composed
continuumApiLazloService_usersApi --> continuumApiLazloService_httpApi: Controller response
continuumApiLazloService_httpApi --> Mobile Client: HTTPS JSON auth response
```

## Related

- Architecture component view: `components-continuum-continuumApiLazloService_httpApi-lazlo-service`
- Related flows: [Mobile API Request Flow](mobile-api-request-flow.md), [SOX Request Flow](sox-request-flow.md)
