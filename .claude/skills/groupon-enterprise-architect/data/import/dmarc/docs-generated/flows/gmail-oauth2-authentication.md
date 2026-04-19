---
service: "dmarc"
title: "Gmail OAuth2 Authentication"
generated: "2026-03-03"
type: flow
flow_name: "gmail-oauth2-authentication"
flow_type: synchronous
trigger: "NewGmailClient() called at service startup or at the start of each polling cycle"
participants:
  - "gmailClient"
architecture_ref: "dynamic-dmarcProcessing"
---

# Gmail OAuth2 Authentication

## Summary

Before any Gmail API call can be made, the DMARC service must authenticate using OAuth2 credentials for the `svc_dmarc@groupon.com` account. This flow describes how the service loads the OAuth2 client credentials from `credentials.json`, reads the persisted refresh token from `token.json`, and constructs an authenticated `http.Client` that the Gmail API service uses for all subsequent requests. If no valid cached token exists, the service falls back to an interactive browser-based authorisation code flow (used only during initial credential setup, not in normal operation).

## Trigger

- **Type**: synchronous (called inline during service startup or polling cycle start)
- **Source**: `NewGmailClient(config)` → `NewGmailConn(cfg)` → `getClient(tokenFilePath, config)`
- **Frequency**: Once per polling cycle (production) or once per container start (staging)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Gmail Client | Orchestrates credential loading, token retrieval, and OAuth2 client construction | `gmailClient` |
| Filesystem | Provides `credentials.json` and `token.json` | container filesystem (secrets volume) |
| Google OAuth2 API | Issues or refreshes access tokens | external (Google) |

## Steps

1. **Load client credentials**: `os.ReadFile(cfg.CredentialsFilePath)` reads `credentials/credentials.json` from disk. This file contains the OAuth2 client ID and client secret registered with the Google Cloud project.
   - From: `gmailClient` (`NewGmailConn`)
   - To: filesystem at `/app/credentials/credentials.json`
   - Protocol: file I/O

2. **Parse OAuth2 config**: `google.ConfigFromJSON(b, gmail.MailGoogleComScope)` deserialises the credentials JSON into an `oauth2.Config` struct with `https://mail.google.com/` scope.
   - From: `gmailClient`
   - To: `google.golang.org/api` library (in-process)
   - Protocol: in-process

3. **Attempt token load from file**: `tokenFromFile(tokenFilePath)` opens `token/token.json` and JSON-decodes an `oauth2.Token` struct containing the access token, refresh token, and expiry.
   - From: `gmailClient` (`getClient`)
   - To: filesystem at `/app/token/token.json`
   - Protocol: file I/O

4. **Refresh access token (if expired)**: The `oauth2.Config.Client()` call wraps the token in a `TokenSource` that automatically calls the Google token endpoint to exchange the refresh token for a new access token when the existing one has expired.
   - From: `gmailClient` (oauth2 library)
   - To: Google OAuth2 token endpoint (`https://oauth2.googleapis.com/token`)
   - Protocol: HTTPS

5. **Fallback: interactive auth code flow (initial setup only)**: If `tokenFromFile` returns an error (file missing or invalid), `getTokenFromWeb(config)` prints an authorisation URL to stdout and reads an authorisation code from stdin. This path is not used in normal Kubernetes operation — it requires the secrets volume to be populated prior to deployment.
   - From: `gmailClient`
   - To: operator (manual step)
   - Protocol: browser / stdin

6. **Persist new token (initial setup only)**: After interactive authorisation, `saveToken(tokenFile, tok)` writes the new token to `token.json` for future runs.
   - From: `gmailClient`
   - To: filesystem
   - Protocol: file I/O

7. **Create Gmail service**: `gmail.NewService(context.Background(), option.WithHTTPClient(client))` wraps the authenticated HTTP client in a `gmail.Service` struct used for all subsequent API calls.
   - From: `gmailClient`
   - To: Google Gmail API (connection initialised)
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `credentials.json` missing or unreadable | `log.Fatalf("Unable to parse client secret file")` | Process exits; Kubernetes restarts pod |
| `token.json` missing | Falls back to interactive auth code flow | Not viable in Kubernetes; pod will hang waiting for stdin |
| OAuth2 token refresh failure | `oauth2` library returns error on first API call | Subsequent Gmail API calls fail; cycle errors are logged |
| `gmail.NewService` failure | `log.Fatalf("Unable to retrieve Gmail client")` | Process exits; Kubernetes restarts pod |

## Sequence Diagram

```
GmailClient -> FileSystem: ReadFile(credentials.json)
FileSystem --> GmailClient: client_id, client_secret
GmailClient -> OAuth2Lib: ConfigFromJSON(scope=gmail.MailGoogleComScope)
OAuth2Lib --> GmailClient: oauth2.Config{}
GmailClient -> FileSystem: Open(token.json)
FileSystem --> GmailClient: oauth2.Token{AccessToken, RefreshToken, Expiry}
alt access token expired
  GmailClient -> GoogleOAuth2: POST /token (refresh_token)
  GoogleOAuth2 --> GmailClient: new access_token
end
GmailClient -> GmailAPI: gmail.NewService(WithHTTPClient)
GmailAPI --> GmailClient: gmail.Service{}
```

## Related

- Architecture dynamic view: `dynamic-dmarcProcessing`
- Related flows: [Production Polling Cycle](production-polling-cycle.md), [Staging Single-Message Run](staging-single-message-run.md)
