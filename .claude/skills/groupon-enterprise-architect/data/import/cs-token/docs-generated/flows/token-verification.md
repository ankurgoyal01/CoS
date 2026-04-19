---
service: "cs-token"
title: "Token Verification"
generated: "2026-03-03"
type: flow
flow_name: "token-verification"
flow_type: synchronous
trigger: "GET /api/v1/:country_code/verify_auth from Cyclops or downstream service"
participants:
  - "customerServiceApps"
  - "continuumCsTokenService"
  - "csTokenRedis"
architecture_ref: "dynamic-cs-token"
---

# Token Verification

## Summary

Before passing a CS agent token to Lazlo for a customer action, Cyclops (or another authorized caller) calls `GET /api/v1/:country_code/verify_auth` to confirm the token is still valid. CS Token Service looks up the encrypted token in Redis, parses the cached payload, and validates three conditions: the requested `method` matches the token's scope, the `consumer_id` matches the stored `accountId`, and the `tokenExpiration` has not passed. If all checks pass, the service returns the customer and agent identity fields. If any check fails, it returns HTTP 401.

## Trigger

- **Type**: api-call
- **Source**: Cyclops (CS agent tooling) or authorized caller
- **Frequency**: On-demand, before each downstream Lazlo API call that requires agent authorization

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cyclops / AppOps | Initiates verification; passes token in `Authorization` header plus `method` and `consumer_id` query params | `customerServiceApps` |
| CS Token Service | Validates request params, looks up token in Redis, performs in-process validation, returns result | `continuumCsTokenService` |
| TokenController | Orchestrates validation sequence; enforces client ID check if feature flag is enabled | `continuumCsTokenService` (`tokenController` component) |
| TokensHelper | Encrypts incoming token key, reads Redis, runs method/consumer/expiry validation logic | `continuumCsTokenService` (`tokensHelper` component) |
| Redis (csTokenRedis) | Stores token payloads; returns cached JSON payload for lookup | `csTokenRedis` |

## Steps

1. **Receive verify auth request**: Caller sends `GET /api/v1/:country_code/verify_auth` with `Authorization: OAuth <token>` header plus `method` and `consumer_id` query params. Optionally includes `client_id` if client ID validation is enabled.
   - From: `customerServiceApps`
   - To: `continuumCsTokenService`
   - Protocol: HTTPS/JSON

2. **Validate client ID (conditional)**: If `client_id_validation_for_tokenizer_enabled` is `true`, `TokenController#validate_client_id` checks that `client_id` is present and is in `Settings.tokenizer_clients`. Returns HTTP 401 if invalid.
   - From: `tokenController`
   - To: Settings (in-process)
   - Protocol: direct

3. **Extract and validate Authorization header**: `TokenController#validate_params` reads `Authorization` header; returns HTTP 401 `{"message":"Must supply oauth_token"}` if absent. Also confirms `consumer_id` and `method` params are present.
   - From: `tokenController`
   - To: request headers / params (in-process)
   - Protocol: direct

4. **Encrypt incoming token for Redis lookup**: `TokensHelper#get_auth_token_info` strips the `OAuth ` prefix from the Authorization header value, then applies the same AES-256-GCM encryption (if `token_encryption_enabled` is `true`) to reconstruct the Redis key.
   - From: `tokensHelper`
   - To: OpenSSL / Ruby stdlib (in-process)
   - Protocol: direct

5. **Look up token in Redis**: Calls `redis.get(encrypted_key)`. Records response time via `STENO_LOGGER`.
   - From: `tokensHelper`
   - To: `csTokenRedis`
   - Protocol: Redis

6. **Parse cached payload**: If a value is returned, parses the JSON string into a Ruby hash containing `method`, `accountId`, `email`, `csAgentId`, `csAgentEmail`, `tokenExpiration`.
   - From: `tokensHelper`
   - To: in-process JSON parser
   - Protocol: direct

7. **Validate method scope**: `TokensHelper#verify_auth_token_info?` checks whether the requested `method` is in the token's stored method (handles both string and array formats, comma-separated values). Fails with `invalid_method_name` if mismatch.
   - From: `tokensHelper`
   - To: cached payload (in-process)
   - Protocol: direct

8. **Validate consumer ID**: Confirms `cached_token_response["accountId"]` equals the request's `consumer_id`. Fails with `invalid_consumer_id` if mismatch.
   - From: `tokensHelper`
   - To: cached payload (in-process)
   - Protocol: direct

9. **Validate expiration**: Parses `tokenExpiration` as a DateTime and confirms it is in the future (UTC). Fails with `token_expired` if past. Also fails if the field is absent or unparseable.
   - From: `tokensHelper`
   - To: cached payload (in-process)
   - Protocol: direct

10. **Return verification result**: On success, `TokenController#show` renders HTTP 200 with `accountId`, `email`, `csAgentId`, `csAgentEmail`, `tokenExpiration`. On any validation failure, renders HTTP 401 `{"message":"Invalid Token"}`.
    - From: `continuumCsTokenService`
    - To: `customerServiceApps`
    - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing `Authorization` header | HTTP 401 `{"message":"Must supply oauth_token"}` | Caller must include token |
| Missing `method` or `consumer_id` params | HTTP 400 `{"message":"Invalid Params"}` | Caller must supply required query params |
| Invalid or missing `client_id` (when flag enabled) | HTTP 401 with specific message | Caller must use a registered client ID |
| Token not found in Redis (expired key or invalid token) | HTTP 401 `{"message":"Invalid Token"}` | Token has expired or was never created |
| Method mismatch | Logs `token_unverified` with reason `invalid_method_name`; HTTP 401 | Caller is verifying with wrong method scope |
| Consumer ID mismatch | Logs `token_unverified` with reason `invalid_consumer_id`; HTTP 401 | Token belongs to a different customer |
| Token past expiration | Logs `token_unverified` with reason `token_expired`; HTTP 401 | Token TTL has passed; new token must be created |
| Redis read failure | Unhandled exception; HTTP 500 | Escalate to `#redis-memcached` |

## Sequence Diagram

```
Cyclops/AppOps -> TokenController: GET /api/v1/:country_code/verify_auth (Authorization: OAuth <token>, method=..., consumer_id=...)
TokenController -> TokenController: validate_client_id (if flag enabled)
TokenController -> TokenController: validate_params (Authorization header, method, consumer_id)
TokenController -> TokensHelper: get_auth_token_info(Authorization header value)
TokensHelper -> TokensHelper: strip "OAuth " prefix; encrypt token key if enabled
TokensHelper -> csTokenRedis: GET encrypted_key
csTokenRedis --> TokensHelper: JSON payload (or nil)
TokensHelper -> TokensHelper: JSON.parse(cached_payload)
TokensHelper -> TokensHelper: verify_auth_token_info?(payload, params) -> method / consumer_id / expiry checks
TokensHelper --> TokenController: {is_verified: true} or {is_verified: false, reason: ...}
TokenController --> Cyclops/AppOps: HTTP 200 {accountId, email, csAgentId, csAgentEmail, tokenExpiration} OR HTTP 401 {message: "Invalid Token"}
```

## Related

- Architecture dynamic view: `dynamic-cs-token`
- Related flows: [Token Creation](token-creation.md)
