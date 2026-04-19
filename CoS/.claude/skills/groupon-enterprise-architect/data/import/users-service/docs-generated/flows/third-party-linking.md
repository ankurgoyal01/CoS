---
service: "users-service"
title: "Third-Party Account Linking Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "third-party-linking"
flow_type: synchronous
trigger: "POST /v1/third_party_links"
participants:
  - "consumer"
  - "continuumUsersService"
  - "googleOAuth"
  - "continuumUsersFacebookGraphApi"
  - "continuumUsersAppleIdentityApi"
  - "continuumUsersDb"
architecture_ref: "containers-users-service"
---

# Third-Party Account Linking Flow

## Summary

Third-party account linking allows authenticated users to associate their Groupon account with a Google, Facebook, or Apple identity. The Third-Party Account Links Controller validates the external token against the appropriate OAuth provider, creates a `third_party_links` record in MySQL, and returns the updated link list. Links can be removed via `DELETE /v1/third_party_links/:id` and synchronized (to refresh external attributes) via the sync endpoint.

## Trigger

- **Type**: api-call
- **Source**: Authenticated user adding or removing a social identity from their account
- **Frequency**: On-demand per user preference change

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (client) | Submits OAuth token and link request | `consumer` |
| Users Service API | Validates token, orchestrates link creation or deletion | `continuumUsersService` |
| Google OAuth | Validates Google identity token during link creation | `googleOAuth` |
| Facebook Graph API | Validates Facebook token during link creation | `continuumUsersFacebookGraphApi` |
| Apple Identity API | Exchanges Apple OAuth code during link creation | `continuumUsersAppleIdentityApi` |
| Users DB | Stores and retrieves third_party_links records | `continuumUsersDb` |

## Steps

### Link Creation (`POST /v1/third_party_links`)

1. **Receive link request**: Authenticated client sends `POST /v1/third_party_links` with provider name and OAuth token/code.
   - From: `consumer`
   - To: `continuumUsersService`
   - Protocol: HTTPS / REST

2. **Validate external identity token**: Third-Party Account Links Controller invokes Account Strategies, which call the appropriate OAuth provider:
   - Google: validates token via `googleOAuth`
   - Facebook: validates token via `continuumUsersFacebookGraphApi`
   - Apple: exchanges code via `continuumUsersAppleIdentityApi`
   - From: `continuumUsersServiceApi_accountStrategies`
   - To: `googleOAuth` / `continuumUsersFacebookGraphApi` / `continuumUsersAppleIdentityApi`
   - Protocol: HTTPS

3. **Check for existing link**: Account Repository checks whether the external identity is already linked to this or another account.
   - From: `continuumUsersServiceApi_accountStrategies`
   - To: `continuumUsersDb`
   - Protocol: MySQL / ActiveRecord

4. **Create third-party link record**: Account Repository inserts a `third_party_links` record with provider, external_id, and profile attributes.
   - From: `continuumUsersServiceApi_accountStrategies`
   - To: `continuumUsersDb`
   - Protocol: MySQL / ActiveRecord

5. **Return links response**: API returns the updated list of third-party links (HTTP 201).
   - From: `continuumUsersService`
   - To: `consumer`
   - Protocol: HTTPS / REST

### Link Deletion (`DELETE /v1/third_party_links/:id`)

1. **Receive unlink request**: Authenticated client sends `DELETE /v1/third_party_links/:id`.
   - From: `consumer`
   - To: `continuumUsersService`
   - Protocol: HTTPS / REST

2. **Validate ownership**: Third-Party Account Links Controller verifies the link belongs to the authenticated account.
   - From: `continuumUsersServiceApi_thirdPartyLinksController`
   - To: `continuumUsersDb`
   - Protocol: MySQL / ActiveRecord

3. **Delete link record**: Account Repository removes the `third_party_links` record.
   - From: `continuumUsersServiceApi_accountStrategies`
   - To: `continuumUsersDb`
   - Protocol: MySQL / ActiveRecord

4. **Return success**: API returns HTTP 200/204.
   - From: `continuumUsersService`
   - To: `consumer`
   - Protocol: HTTPS / REST

### Sync (`POST /v1/third_party_links/sync`)

1. **Receive sync request**: Client sends `POST /v1/third_party_links/sync` to refresh external profile attributes.
   - From: `consumer`
   - To: `continuumUsersService`
   - Protocol: HTTPS / REST

2. **Fetch current external attributes**: Account Strategies calls the OAuth provider to retrieve up-to-date profile data.
   - From: `continuumUsersServiceApi_accountStrategies`
   - To: OAuth provider
   - Protocol: HTTPS

3. **Update link record**: Account Repository updates the `third_party_links` record with refreshed attributes.
   - From: `continuumUsersServiceApi_accountStrategies`
   - To: `continuumUsersDb`
   - Protocol: MySQL / ActiveRecord

4. **Return updated link**: API returns HTTP 200 with refreshed link data.
   - From: `continuumUsersService`
   - To: `consumer`
   - Protocol: HTTPS / REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| OAuth provider token invalid | Provider returns error; Account Strategies raises | 422 Unprocessable Entity |
| OAuth provider unreachable | HTTP error from OAuth client | 503 Service Unavailable |
| External identity already linked to another account | Repository detects conflict | 422 with conflict detail |
| Link not found during DELETE | Repository returns nil | 404 Not Found |
| Unauthorized DELETE attempt | Controller checks account ownership | 403 Forbidden |

## Sequence Diagram

```
[Link Creation]
Consumer          -> UsersServiceAPI         : POST /v1/third_party_links (provider, token)
UsersServiceAPI   -> AccountStrategies       : link_identity(account, provider, token)
AccountStrategies -> OAuthProvider           : validate_token / exchange_code
OAuthProvider     --> AccountStrategies      : external_id, profile attributes
AccountStrategies -> AccountRepository       : SELECT third_party_links WHERE external_id = ?
AccountStrategies -> AccountRepository       : INSERT third_party_links (account_id, provider, external_id)
UsersServiceAPI   --> Consumer               : 201 Created (link list)

[Link Deletion]
Consumer          -> UsersServiceAPI         : DELETE /v1/third_party_links/:id
UsersServiceAPI   -> AccountRepository       : SELECT third_party_links WHERE id = ?
AccountRepository --> UsersServiceAPI        : link record
UsersServiceAPI   -> AccountStrategies       : delete_link(link)
AccountStrategies -> AccountRepository       : DELETE third_party_links WHERE id = ?
UsersServiceAPI   --> Consumer               : 200 OK
```

## Related

- Related flows: [Authentication](authentication.md), [Account Creation](account-creation.md)
