---
service: "vss"
title: "GDPR User Obfuscation"
generated: "2026-03-03"
type: flow
flow_name: "gdpr-user-obfuscation"
flow_type: synchronous
trigger: "HTTP POST to /v1/obfuscate/users with valid X-API-KEY header"
participants:
  - "continuumVssService"
  - "vssResource"
  - "voucherUserDataService"
  - "voucherUsersDataDbi"
  - "continuumVssMySql"
architecture_ref: "components-vss-searchService-components"
---

# GDPR User Obfuscation

## Summary

The GDPR user obfuscation flow provides a synchronous API endpoint for erasing or obfuscating personally identifiable information (PII) stored in VSS MySQL for given user account IDs. This endpoint complements the JMS-driven `gdpr.account.v1.erased` event flow by offering a direct, authorized HTTP mechanism to obfuscate user data on demand. Access is controlled by an `X-API-KEY` header validated server-side. Up to 50 user IDs can be submitted per request.

## Trigger

- **Type**: api-call
- **Source**: Authorized internal caller (GDPR compliance tooling or platform) submitting user IDs for erasure
- **Frequency**: On demand, triggered by GDPR erasure requests

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Authorized caller | Submits list of user IDs for obfuscation with valid API key | (external to VSS) |
| VSS Service | Receives and processes the obfuscation request | `continuumVssService` |
| VssResource | REST entry point — validates API key and routes request | `vssResource` |
| VoucherUserDataService | Applies obfuscation to voucher-user records | `voucherUserDataService` |
| VoucherUsersDataDbi | JDBI DAO — executes obfuscation SQL | `voucherUsersDataDbi` |
| VSS MySQL | Stores the obfuscated user records | `continuumVssMySql` |

## Steps

1. **Receives obfuscation request**: Authorized caller sends `POST /v1/obfuscate/users` with `X-API-KEY` header and a JSON body containing a list of user IDs.
   - From: authorized caller
   - To: `vssResource` (via `continuumVssService`)
   - Protocol: REST / JSON

2. **Validates API key**: `vssResource` validates the `X-API-KEY` header value against the configured `deleteUserSecretKey`. If invalid or missing, returns `401 Unauthorized`.
   - From: `vssResource`
   - To: internal validation
   - Protocol: direct

3. **Validates request size**: `vssResource` checks that the number of submitted user IDs does not exceed `MAX_DELETE_USERS_ALLOWED=50`.
   - From: `vssResource`
   - To: internal validation
   - Protocol: direct

4. **Obfuscates user data**: `vssResource` delegates to `voucherUserDataService`, which calls `voucherUsersDataDbi` to replace PII fields (first name, last name, masked email) with obfuscated/redacted values (constant `REDACTED`) for all voucher records matching the submitted account IDs. Emits `ObfuscateUserDetails` event metric.
   - From: `voucherUserDataService`
   - To: `voucherUsersDataDbi` → `continuumVssMySql`
   - Protocol: JDBI / MySQL

5. **Returns response**: `vssResource` returns `200 OK` with a `VSS` response body indicating the number of affected users (`totalUsers`) and the list of processed user IDs.
   - From: `continuumVssService`
   - To: authorized caller
   - Protocol: REST / JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing `X-API-KEY` header | `vssResource` returns `401 Not authorized to delete the user` | Request rejected before any DB operation |
| Invalid `X-API-KEY` value | Same as missing; returns `401` | Request rejected |
| User IDs list exceeds 50 entries | Validation returns 400 Bad Request | Request rejected |
| MySQL write failure during obfuscation | Exception thrown; returns `500` | Partial obfuscation may occur if some IDs were processed before failure |
| User IDs not found in VSS MySQL | SQL UPDATE affects zero rows for those IDs | Operation succeeds silently; response reflects actual rows updated |

## Sequence Diagram

```
AuthorizedCaller -> VssResource: POST /v1/obfuscate/users (X-API-KEY: <key>, body: {users: [id1, id2, ...]})
VssResource -> VssResource: Validate X-API-KEY against deleteUserSecretKey
VssResource -> VssResource: Validate users.size() <= 50
VssResource -> VoucherUserDataService: obfuscateUsers([id1, id2, ...])
VoucherUserDataService -> VoucherUsersDataDbi: obfuscate(userIds)
VoucherUsersDataDbi -> VSSMySQL: UPDATE voucher_users SET firstName='REDACTED', lastName='REDACTED', maskedEmail='REDACTED' WHERE accountId IN (...)
VSSMySQL --> VoucherUsersDataDbi: rows affected
VoucherUsersDataDbi --> VoucherUserDataService: result
VoucherUserDataService --> VssResource: DeleteUserResponse(deletedCount)
VssResource --> AuthorizedCaller: 200 OK {totalUsers, users}
```

## Related

- Architecture dynamic view: `components-vss-searchService-components`
- Related flows: [User Data Sync](user-data-sync.md) — JMS-driven GDPR erasure path
- API endpoint: `POST /v1/obfuscate/users` — documented in [API Surface](../api-surface.md)
- Configuration: `deleteUserSecretKey`, `MAX_DELETE_USERS_ALLOWED` — documented in [Configuration](../configuration.md)
