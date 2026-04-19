---
service: "transporter-jtier"
title: "Salesforce User Authentication"
generated: "2026-03-03"
type: flow
flow_name: "salesforce-user-authentication"
flow_type: synchronous
trigger: "POST /v0/auth called by Transporter ITier with Salesforce OAuth authorization code"
participants:
  - "continuumTransporterJtierService"
  - "transporterJtier_apiResource"
  - "userTokenService"
  - "salesforceAccess"
  - "continuumTransporterRedisCache"
  - "userService_TraJti"
  - "continuumTransporterMysqlDatabase"
architecture_ref: "dynamic-transporter_jtier_components"
---

# Salesforce User Authentication

## Summary

This flow handles the initial Salesforce user authentication for the Transporter upload UI. When a user completes the Salesforce OAuth login in Transporter ITier, ITier forwards the authorization code to the JTier backend. JTier exchanges the code for a Salesforce access token, caches that token in Redis, and persists or updates the user record in MySQL.

## Trigger

- **Type**: api-call
- **Source**: `transporter-itier` calls `POST /v0/auth`
- **Frequency**: On-demand — once per user login session

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Transporter ITier | Initiates auth by forwarding OAuth code | External caller |
| Transporter API Resource | Receives POST /v0/auth and delegates to User Token Service | `transporterJtier_apiResource` |
| User Token Service | Orchestrates token exchange and caching | `userTokenService` |
| Salesforce Access Client | Calls Salesforce OAuth endpoint to exchange code for token | `salesforceAccess` |
| Transporter Redis | Stores the access token keyed by user identity | `continuumTransporterRedisCache` |
| User Service | Creates or updates the user record in MySQL | `userService_TraJti` |
| Transporter MySQL | Persists user record | `continuumTransporterMysqlDatabase` |

## Steps

1. **Receives auth code**: Transporter ITier sends `POST /v0/auth` with the Salesforce OAuth authorization code.
   - From: `transporter-itier`
   - To: `transporterJtier_apiResource`
   - Protocol: REST (HTTP)

2. **Delegates to User Token Service**: The API Resource passes the auth code to the User Token Service for processing.
   - From: `transporterJtier_apiResource`
   - To: `userTokenService`
   - Protocol: direct (in-process)

3. **Exchanges code for token**: The User Token Service invokes the Salesforce Access Client to exchange the authorization code for a Salesforce OAuth access token and refresh token.
   - From: `userTokenService`
   - To: `salesforceAccess`
   - Protocol: direct (in-process)

4. **Calls Salesforce token endpoint**: The Salesforce Access Client posts to Salesforce's OAuth token endpoint using the connected app credentials.
   - From: `salesforceAccess`
   - To: Salesforce OAuth endpoint
   - Protocol: OAuth2/REST (HTTPS)

5. **Receives access token**: Salesforce returns an access token, refresh token, and user identity information.
   - From: Salesforce
   - To: `salesforceAccess`
   - Protocol: OAuth2/REST (HTTPS)

6. **Caches token in Redis**: The User Token Service stores the access token in Redis, keyed by user identity, to avoid repeated token exchanges on subsequent requests.
   - From: `userTokenService`
   - To: `continuumTransporterRedisCache`
   - Protocol: Redis

7. **Persists user record**: The User Token Service invokes the User Service to create or update the user record in MySQL.
   - From: `userTokenService`
   - To: `userService_TraJti`
   - Protocol: direct (in-process)

8. **Writes user to MySQL**: The User Service uses JDBI to insert or update the user row in the transporter MySQL database.
   - From: `userService_TraJti`
   - To: `continuumTransporterMysqlDatabase`
   - Protocol: JDBI/MySQL

9. **Returns auth result**: The API Resource returns a JSON authentication result to Transporter ITier.
   - From: `transporterJtier_apiResource`
   - To: `transporter-itier`
   - Protocol: REST (HTTP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce token endpoint unreachable | HTTP call fails in Salesforce Access Client | HTTP error returned to ITier; user cannot authenticate |
| Invalid or expired authorization code | Salesforce returns OAuth error | Error propagated to ITier; user prompted to re-authenticate |
| Redis unavailable | Token caching skipped or fails | Authentication may still succeed; subsequent requests will re-fetch from Salesforce |
| MySQL unavailable | User record write fails | Authentication fails; exception returned to ITier |

## Sequence Diagram

```
transporter-itier  ->  transporterJtier_apiResource  : POST /v0/auth (auth code)
transporterJtier_apiResource  ->  userTokenService  : exchange(authCode)
userTokenService  ->  salesforceAccess  : exchangeCodeForToken(authCode)
salesforceAccess  ->  Salesforce  : POST /oauth2/token
Salesforce  -->  salesforceAccess  : access_token, refresh_token, userInfo
salesforceAccess  -->  userTokenService  : token response
userTokenService  ->  continuumTransporterRedisCache  : SET user:<id> token
userTokenService  ->  userService_TraJti  : persistUser(userInfo)
userService_TraJti  ->  continuumTransporterMysqlDatabase  : UPSERT user record
continuumTransporterMysqlDatabase  -->  userService_TraJti  : OK
userService_TraJti  -->  userTokenService  : OK
userTokenService  -->  transporterJtier_apiResource  : auth result
transporterJtier_apiResource  -->  transporter-itier  : 200 JSON auth result
```

## Related

- Architecture dynamic view: `dynamic-transporter_jtier_components`
- Related flows: [CSV Upload Submission](csv-upload-submission.md), [Upload Status Query](upload-status-query.md)
