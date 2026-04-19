---
service: "cs-token"
title: "Token Creation"
generated: "2026-03-03"
type: flow
flow_name: "token-creation"
flow_type: synchronous
trigger: "POST /api/v1/:country_code/token from Cyclops or AppOps"
participants:
  - "customerServiceApps"
  - "continuumCsTokenService"
  - "csTokenRedis"
architecture_ref: "dynamic-cs-token"
---

# Token Creation

## Summary

When a CS agent initiates a scoped action on a customer account (e.g., viewing vouchers, creating an order), Cyclops or AppOps sends a `POST /api/v1/:country_code/token` request to CS Token Service. The service validates the caller's API key, generates a cryptographically random token, computes a method-scoped expiration time, optionally encrypts the token key with AES-256-GCM, and stores the payload in Redis with a TTL. The plain token string is returned to the caller for use in downstream Lazlo API calls.

## Trigger

- **Type**: api-call
- **Source**: Cyclops (CS agent tooling) or AppOps
- **Frequency**: On-demand, once per agent-initiated customer action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cyclops / AppOps | Initiates token creation; passes customer and agent identifiers | `customerServiceApps` |
| CS Token Service | Validates request, generates token, stores in Redis, returns token to caller | `continuumCsTokenService` |
| TokenController | Validates API key and request params; delegates to TokensHelper | `continuumCsTokenService` (`tokenController` component) |
| TokensHelper | Generates random token, encrypts key, computes TTL, writes to Redis | `continuumCsTokenService` (`tokensHelper` component) |
| Redis (csTokenRedis) | Stores token payload with TTL | `csTokenRedis` |

## Steps

1. **Receive create token request**: Cyclops or AppOps sends `POST /api/v1/:country_code/token` with `consumer_id`, `customer_email`, `agent_id`, `agent_email`, and `method` in the request body, plus `X-API-KEY` header.
   - From: `customerServiceApps`
   - To: `continuumCsTokenService`
   - Protocol: HTTPS/JSON

2. **Validate API key**: `TokenController#validate_create_token_params` checks `X-API-KEY` header against `Settings.supported_api_keys` when `api_key_authentication_for_token_creation_enabled` is `true`. Returns HTTP 401 if key is absent or invalid.
   - From: `tokenController`
   - To: Settings (in-process)
   - Protocol: direct

3. **Validate required params**: Confirms `consumer_id`, `agent_id`, `agent_email`, and `method` are all present. Returns HTTP 400 if any are missing.
   - From: `tokenController`
   - To: request params (in-process)
   - Protocol: direct

4. **Validate method is supported**: Checks `params[:method]` against `Settings.supported_methods`. Returns HTTP 400 `{"message":"Method is not supported"}` if method is unknown.
   - From: `tokenController`
   - To: Settings (in-process)
   - Protocol: direct

5. **Generate random token**: `TokensHelper#get_auth_token` calls `SecureRandom.hex(32)` to produce a 64-character hex token string.
   - From: `tokensHelper`
   - To: Ruby stdlib (in-process)
   - Protocol: direct

6. **Compute expiration**: `TokensHelper#get_token_expiration` looks up TTL for the requested method from `Settings.token_expiration`; defaults to 5 minutes if not configured. Returns ISO 8601 UTC expiration timestamp.
   - From: `tokensHelper`
   - To: Settings (in-process)
   - Protocol: direct

7. **Encrypt token key (conditional)**: If `token_encryption_enabled` is `true`, `TokensHelper#encrypt` applies AES-256-GCM using `Settings.token_encryption.secret` and `.iv`, then Base64url-encodes the ciphertext. The encrypted form is used as the Redis key.
   - From: `tokensHelper`
   - To: OpenSSL / Ruby stdlib (in-process)
   - Protocol: direct

8. **Store token payload in Redis**: `TokensHelper#setex_key` calls `redis.setex(encrypted_key, ttl_seconds, json_payload)` where the JSON payload contains `method`, `accountId`, `email`, `csAgentId`, `csAgentEmail`, `tokenExpiration`.
   - From: `tokensHelper`
   - To: `csTokenRedis`
   - Protocol: Redis

9. **Return token to caller**: `TokenController#create` renders HTTP 200 JSON with `token` (the plain, unencrypted token string) and `tokenExpiration`.
   - From: `continuumCsTokenService`
   - To: `customerServiceApps`
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing or invalid `X-API-KEY` | Returns HTTP 401 `{"message":"Invalid X-API-KEY"}` | Caller must fix API key configuration |
| Missing required params | Returns HTTP 400 `{"message":"Invalid Params"}` | Caller must supply all required fields |
| Unsupported method | Returns HTTP 400 `{"message":"Method is not supported"}` | Caller must use a method listed in `supported_methods` |
| `tokenizer_redis` not configured | Returns HTTP 401 `{"message":"forbidden"}` | Service misconfiguration; escalate to ops |
| Redis write failure | Unhandled exception; HTTP 500 | Escalate to `#redis-memcached`; check Redis health |

## Sequence Diagram

```
Cyclops/AppOps -> TokenController: POST /api/v1/:country_code/token (X-API-KEY, consumer_id, agent_id, agent_email, method, customer_email)
TokenController -> TokenController: validate_create_token_params (API key, required params, method)
TokenController -> TokensHelper: create_auth_token_info(params)
TokensHelper -> TokensHelper: get_auth_token() -> SecureRandom.hex(32)
TokensHelper -> TokensHelper: get_token_expiration(method) -> ISO8601 timestamp
TokensHelper -> TokensHelper: get_encrypted_token(token) -> AES-256-GCM encrypt if enabled
TokensHelper -> csTokenRedis: SETEX encrypted_key ttl_seconds json_payload
csTokenRedis --> TokensHelper: OK
TokensHelper --> TokenController: {token, expiration}
TokenController --> Cyclops/AppOps: HTTP 200 {token, tokenExpiration, status: 200}
```

## Related

- Architecture dynamic view: `dynamic-cs-token`
- Related flows: [Token Verification](token-verification.md)
