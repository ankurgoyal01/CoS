---
service: "cs-token"
title: "Test Token Creation"
generated: "2026-03-03"
type: flow
flow_name: "test-token-creation"
flow_type: synchronous
trigger: "POST /api/v1/:country_code/token/create_token from test tooling"
participants:
  - "customerServiceApps"
  - "continuumCsTokenService"
  - "csTokenRedis"
architecture_ref: "dynamic-cs-token"
---

# Test Token Creation

## Summary

CS Token Service provides a test-only endpoint (`POST /api/v1/:country_code/token/create_token`) that creates tokens with a 30-day TTL for testing and QA purposes. This endpoint is guarded by the `tokenizer_redis.test_enabled` setting, which is `true` in development and staging environments but `false` (or absent) in production. Test tokens use the same Redis storage mechanism as production tokens but apply a fixed 30-day expiration regardless of the method parameter.

## Trigger

- **Type**: api-call
- **Source**: Test tooling, QA automation, or manual testing by developers
- **Frequency**: On-demand during development and staging testing

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Test caller / QA tooling | Initiates test token creation request | `customerServiceApps` |
| CS Token Service | Validates test mode is enabled, generates and caches long-lived token | `continuumCsTokenService` |
| TokenController | Guards endpoint with `test_enabled` check; validates params | `continuumCsTokenService` (`tokenController` component) |
| TokensHelper | Generates token, sets 30-day TTL, stores in Redis | `continuumCsTokenService` (`tokensHelper` component) |
| Redis (csTokenRedis) | Stores token payload with 30-day TTL | `csTokenRedis` |

## Steps

1. **Receive create_token request**: Test caller sends `POST /api/v1/:country_code/token/create_token` with `consumer_id`, `email`, and `method` (or `methods`) in the request body.
   - From: `customerServiceApps` (test tooling)
   - To: `continuumCsTokenService`
   - Protocol: HTTPS/JSON

2. **Validate test mode is enabled**: `TokenController#validate_test_params` checks that `Settings.tokenizer_redis.test_enabled` is present and truthy. Returns HTTP 401 `{"message":"forbidden"}` if test mode is not enabled (i.e., in production).
   - From: `tokenController`
   - To: Settings (in-process)
   - Protocol: direct

3. **Validate required params**: Confirms `consumer_id` is present and at least one of `method` or `methods` is present, plus `email`. Returns HTTP 400 if validation fails.
   - From: `tokenController`
   - To: request params (in-process)
   - Protocol: direct

4. **Resolve method(s)**: `TokensHelper#get_method` handles both single `method` param and comma-separated `methods` param, returning either a string or array.
   - From: `tokensHelper`
   - To: request params (in-process)
   - Protocol: direct

5. **Generate random token**: `TokensHelper#get_auth_token` calls `SecureRandom.hex(32)`.
   - From: `tokensHelper`
   - To: Ruby stdlib (in-process)
   - Protocol: direct

6. **Apply defaults for missing agent fields**: If `csAgentEmail` is not provided, defaults to `abhattacharyya@groupon.com`. If `csAgentId` is not provided, defaults to `6acea264-da11-11e6-9a81-000a27020065`.
   - From: `tokensHelper`
   - To: in-process (in-process)
   - Protocol: direct

7. **Compute 30-day expiration**: Sets `tokenExpiration` to `DateTime.now + 30.days` (ISO 8601).
   - From: `tokensHelper`
   - To: in-process
   - Protocol: direct

8. **Encrypt token key (conditional)**: Same AES-256-GCM encryption path as production if `token_encryption_enabled` is `true`.
   - From: `tokensHelper`
   - To: OpenSSL / Ruby stdlib (in-process)
   - Protocol: direct

9. **Store token in Redis with 30-day TTL**: `redis.setex(encrypted_key, 30.days, json_payload)`.
   - From: `tokensHelper`
   - To: `csTokenRedis`
   - Protocol: Redis

10. **Return test token to caller**: HTTP 200 with `token` (plain token string) and `tokenExpiration` (30 days from now).
    - From: `continuumCsTokenService`
    - To: test caller
    - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `test_enabled` not set (production) | HTTP 401 `{"message":"forbidden"}` | Endpoint is disabled; use production token creation endpoint |
| Missing `consumer_id`, `method`/`methods`, or `email` | HTTP 400 `{"message":"Invalid Params"}` | Caller must supply required fields |
| Redis write failure | Unhandled exception; HTTP 500 | Check Redis availability in test environment |

## Sequence Diagram

```
TestCaller -> TokenController: POST /api/v1/:country_code/token/create_token (consumer_id, email, method/methods)
TokenController -> TokenController: validate_test_params (test_enabled check, required params)
TokenController -> TokensHelper: create_auth_token_info_for_test(params)
TokensHelper -> TokensHelper: get_method(params) -> method string or array
TokensHelper -> TokensHelper: get_auth_token() -> SecureRandom.hex(32)
TokensHelper -> TokensHelper: apply default agent fields if missing
TokensHelper -> TokensHelper: set tokenExpiration = DateTime.now + 30.days
TokensHelper -> TokensHelper: get_encrypted_token(token) -> encrypt if enabled
TokensHelper -> csTokenRedis: SETEX encrypted_key 2592000 json_payload
csTokenRedis --> TokensHelper: OK
TokensHelper --> TokenController: {key: token, value: {tokenExpiration, ...}}
TokenController --> TestCaller: HTTP 200 {token, tokenExpiration, status: 200}
```

## Related

- Architecture dynamic view: `dynamic-cs-token`
- Related flows: [Token Creation](token-creation.md), [Token Verification](token-verification.md)
