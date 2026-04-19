---
service: "transporter-itier"
title: "Salesforce OAuth Login Flow"
generated: "2026-03-03"
type: flow
flow_name: "salesforce-oauth-login-flow"
flow_type: synchronous
trigger: "User accesses a protected page and is not yet validated in transporter-jtier"
participants:
  - "continuumTransporterItierWeb"
  - "salesforceOAuth"
  - "jtierClient"
  - "salesForce"
  - "transporterJtierSystem_7f3a2c"
architecture_ref: "dynamic-upload-flow"
---

# Salesforce OAuth Login Flow

## Summary

When a user accesses a protected route (such as `/new-upload`) and is not yet registered or validated in the `transporter-jtier` user store, the Salesforce OAuth Handler reads encrypted Salesforce Connected App credentials from a mounted secrets file, constructs an OAuth2 authorization URL using `jsforce`, and redirects the browser to Salesforce login. After the user authenticates, Salesforce redirects back to `/oauth2/callback`. The callback handler forwards the authorization code to `transporter-jtier /auth`, which completes the token exchange and registers the user. On success, the user is redirected to `/new-upload`.

## Trigger

- **Type**: user-action
- **Source**: User navigates to any protected route while the jtier `/validUser` check returns false (user not in jtier)
- **Frequency**: On demand (first-time access or session expiry)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser | Initiates page request; follows redirects | (external) |
| Salesforce OAuth Handler | Constructs OAuth2 URL, redirects browser, handles callback | `salesforceOAuth` |
| JTIER Client | Calls jtier to validate user and exchange OAuth code | `jtierClient` |
| Salesforce | OAuth2 authorization endpoint and login UI | `salesForce` |
| transporter-jtier | `/validUser` check; `/auth` token exchange and user registration | `transporterJtierSystem_7f3a2c` |

## Steps

1. **User requests protected page**: Browser sends GET request to a protected route (e.g., `/new-upload`).
   - From: `Browser`
   - To: `continuumTransporterItierWeb`
   - Protocol: HTTPS

2. **User validation check**: The page action calls jtier to check if the user (identified by the `x-grpn-username` Okta header) is registered.
   - From: `jtierClient`
   - To: `transporter-jtier GET /validUser?user=<username>`
   - Protocol: HTTP

3. **User not valid — redirect to Salesforce**: jtier returns an error or failure response. The OAuth Handler reads the secrets file to decrypt `TRANSPORTER_ITIER_SF_CLIENT_ID` and `TRANSPORTER_ITIER_SF_CLIENT_SECRET` (Base64-decoded). It constructs a `jsforce.OAuth2` authorization URL with the configured `loginUrl`, `clientId`, `clientSecret`, `redirectUri`, and `grant_type`. The browser is redirected to the Salesforce authorization URL.
   - From: `salesforceOAuth`
   - To: `salesForce` (HTTPS redirect)
   - Protocol: HTTPS/OAuth2

4. **User authenticates at Salesforce**: The user enters their Salesforce credentials at the Salesforce login page.
   - From: `Browser`
   - To: `salesForce`
   - Protocol: HTTPS

5. **Salesforce redirects to callback**: After successful login, Salesforce redirects the browser to the configured `redirectUri` (`/oauth2/callback`) with an `?code=<authorization_code>` query parameter.
   - From: `salesForce`
   - To: `continuumTransporterItierWeb GET /oauth2/callback?code=<code>`
   - Protocol: HTTPS redirect

6. **Callback exchanges authorization code**: The `authCode` handler extracts the `code` query parameter and calls jtier to complete the token exchange.
   - From: `jtierClient`
   - To: `transporter-jtier POST /auth?code=<code>&user=<username>`
   - Protocol: HTTP

7. **jtier confirms success**: jtier returns `{ status: "ok" }` if the exchange succeeded and the user is now registered.
   - From: `transporter-jtier`
   - To: `jtierClient`
   - Protocol: HTTP

8. **Redirect to upload page**: The callback handler receives `status: "ok"` and redirects the browser to `/new-upload`.
   - From: `continuumTransporterItierWeb`
   - To: `Browser`
   - Protocol: HTTPS redirect (302)

9. **User accesses protected page**: The user's next request passes the jtier `/validUser` check and the page renders normally.
   - From: `Browser`
   - To: `continuumTransporterItierWeb`
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Secrets file not found or unreadable | `fs.readFileSync` throws at startup of the route handler | 500 error; page does not render |
| Invalid/expired Salesforce credentials | Salesforce OAuth login fails | User sees Salesforce error page; cannot log in |
| jtier `/auth` returns error | `authCode` handler receives non-`ok` status or reject | `json(authJtier)` — returns the jtier error as JSON to the browser |
| jtier `/auth` endpoint unavailable | Promise rejects | Unhandled rejection propagated as 500 error |
| User navigates to callback without valid code | jtier `/auth` returns error | JSON error response shown |

## Sequence Diagram

```
Browser             -> transporter-itier-web (GET /new-upload): Request protected page
transporter-itier-web -> transporter-jtier (GET /validUser?user=<u>): Check user registration
transporter-jtier   --> transporter-itier-web: Error / user not found
transporter-itier-web (salesforceOAuth) -> secrets file: Read + decrypt SF credentials
transporter-itier-web --> Browser: 302 Redirect to Salesforce OAuth2 authorization URL
Browser             -> salesForce (GET /authorize?...): Salesforce login page
Browser (user)      -> salesForce: Submit credentials
salesForce          --> Browser: 302 Redirect to /oauth2/callback?code=<auth_code>
Browser             -> transporter-itier-web (GET /oauth2/callback?code=<c>): Callback
transporter-itier-web -> transporter-jtier (POST /auth?code=<c>&user=<u>): Exchange code
transporter-jtier   --> transporter-itier-web: { status: "ok" }
transporter-itier-web --> Browser: 302 Redirect to /new-upload
Browser             -> transporter-itier-web (GET /new-upload): Load upload page (now authenticated)
```

## Related

- Architecture dynamic view: `dynamic-upload-flow`
- Related flows: [CSV Upload Flow](csv-upload-flow.md)
- [Flows Index](index.md)
