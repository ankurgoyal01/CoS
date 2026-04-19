---
service: "file-sharing-service"
title: "User Registration"
generated: "2026-03-03"
type: flow
flow_name: "user-registration"
flow_type: synchronous
trigger: "POST /users/register"
participants:
  - "continuumFileSharingService"
  - "continuumFileSharingMySql"
  - "googleOAuth"
architecture_ref: "components-continuumFileSharingService"
---

# User Registration

## Summary

This flow registers a Groupon Google account as a user in File Sharing Service. The caller provides their Google email, an optional description, and a one-time OAuth2 authorization code obtained from the Google OAuth2 Playground. The service exchanges the code for tokens, validates that the account is a `@groupon.com` Google Workspace account, and stores the access and refresh tokens in MySQL. A `uuid` is returned for use in subsequent file operations.

## Trigger

- **Type**: api-call
- **Source**: Administrator or client service calling `POST /users/register` with a JSON body
- **Frequency**: On demand, per new user setup; also used when refreshing a user's OAuth credentials

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| HTTP API | Receives request, handles error cases (invalid token, duplicate user) | `continuumFileSharingService` |
| User Service | Orchestrates token exchange, domain validation, user creation | `continuumFileSharingService` |
| Google Drive Client | Executes OAuth2 token request and user info fetch | `continuumFileSharingService` |
| Google OAuth2 API | Validates auth code, issues access+refresh tokens, returns user info | `googleOAuth` |
| File Sharing MySQL | Stores new user record with tokens | `continuumFileSharingMySql` |

## Steps

1. **Receive registration request**: HTTP API receives `POST /users/register` with JSON body `{email, desc?, auth-code}`.
   - From: external caller
   - To: `continuumFileSharingService` (HTTP API)
   - Protocol: HTTP JSON

2. **Exchange authorization code for tokens**: User Service calls `google/get-token(auth-code)`, which executes a Google OAuth2 token request via the configured `GoogleAuthorizationCodeFlow` (client ID/secret, offline access type, redirect URI `https://developers.google.com/oauthplayground`). Returns a `GoogleTokenResponse` with `access_token`, `refresh_token`, and `expires_in`.
   - From: `continuumFileSharingService` (Google Drive Client)
   - To: `googleOAuth`
   - Protocol: HTTPS (OAuth2 token endpoint)

3. **Fetch user info**: User Service calls `google/get-user-info(credential)` to call the Google OAuth2 userinfo endpoint, retrieving the account's `email` and `hd` (hosted domain) fields.
   - From: `continuumFileSharingService` (Google Drive Client)
   - To: `googleOAuth`
   - Protocol: HTTPS (OAuth2 userinfo endpoint)

4. **Validate domain**: User Service calls `check-user-info` — asserts that `hd == "groupon.com"` and that the returned email matches the submitted email. Throws a `Throwable` if either check fails.
   - From: `continuumFileSharingService` (User Service)
   - To: internal validation
   - Protocol: internal

5. **Create user record**: User Service calls `create(email, desc, token)` — merges a new `uuid`, email, desc, and token attributes (`current-token`, `current-token-expires-at`, `refresh-token`) and inserts into the `users` MySQL table.
   - From: `continuumFileSharingService` (User Service)
   - To: `continuumFileSharingMySql`
   - Protocol: JDBC

6. **Return user UUID**: HTTP API returns JSON `{"user": {"uuid": "<uuid>"}}`.
   - From: `continuumFileSharingService` (HTTP API)
   - To: external caller
   - Protocol: HTTP JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Auth code already used or expired | `TokenResponseException` caught by HTTP API | HTTP 400 `{"error": "Token was previously used or invalid."}` |
| Email already registered | `SQLIntegrityConstraintViolationException` caught by HTTP API | HTTP 400 `{"error": "User already exists."}` |
| Email not `@groupon.com` | `Throwable` thrown in `check-user-info` | HTTP 400 `{"error": "User account is not a 'groupon.com' account."}` |
| Email mismatch | `Throwable` thrown in `check-user-info` | HTTP 400 `{"error": "Email you provide must match the email you authenticate with."}` |
| Any other exception | Caught as `Throwable` by HTTP API | HTTP 400 with exception message |

## Sequence Diagram

```
Caller -> HTTP API: POST /users/register {email, desc?, auth-code}
HTTP API -> User Service: register(email, desc, auth-code)
User Service -> Google Drive Client: get-token(auth-code)
Google Drive Client -> Google OAuth API: POST /token {code, client_id, client_secret, redirect_uri}
Google OAuth API --> Google Drive Client: {access_token, refresh_token, expires_in}
User Service -> Google Drive Client: get-credential(token)
User Service -> Google Drive Client: get-user-info(credential)
Google Drive Client -> Google OAuth API: GET /userinfo
Google OAuth API --> Google Drive Client: {email, hd}
User Service -> User Service: check-user-info(userInfo, email) [validate hd=groupon.com]
User Service -> MySQL: INSERT INTO users (uuid, email, desc, current-token, refresh-token, ...)
MySQL --> User Service: new user record
HTTP API --> Caller: {"user": {"uuid": "<uuid>"}}
```

## Related

- Related flows: [File Upload to Google Drive](file-upload-to-google-drive.md)
- See `README.md` section "Setup a new user" for the manual operator procedure including use of Google Developers OAuth 2.0 Playground
