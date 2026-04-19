---
service: "merchant-booking-tool"
title: "Google Calendar Sync Auth Flow"
generated: "2026-03-03"
type: flow
flow_name: "google-calendar-sync-auth-flow"
flow_type: synchronous
trigger: "Merchant initiates Google Calendar connection from the booking tool"
participants:
  - "merchant"
  - "continuumMerchantBookingTool"
  - "mbtWebRoutes"
  - "googleOAuth"
architecture_ref: "dynamic-merchant-booking-primary-flow"
---

# Google Calendar Sync Auth Flow

## Summary

Merchants can connect their Google Calendar to the booking tool to enable calendar synchronization. When a merchant initiates this connection, the Merchant Booking Tool coordinates an OAuth 2.0 authorization code flow with Google's OAuth endpoints. The routing layer handles the OAuth redirect, receives the authorization code, and exchanges it for access and refresh tokens to enable ongoing calendar sync.

## Trigger

- **Type**: user-action
- **Source**: Merchant clicks "Connect Google Calendar" or similar action within the booking tool UI
- **Frequency**: On demand, per merchant calendar connection or re-authorization

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Initiates calendar connection; completes OAuth authorization in Google's UI | `merchant` |
| Merchant Booking Tool | Hosts the OAuth initiation and callback endpoints | `continuumMerchantBookingTool` |
| Routing and Page Composition | Handles OAuth initiation redirect and authorization callback route | `mbtWebRoutes` |
| Google OAuth | Provides OAuth 2.0 authorization and token issuance | `googleOAuth` |

## Steps

1. **Merchant initiates calendar connection**: Merchant clicks the calendar sync action within the booking tool UI.
   - From: `merchant`
   - To: `mbtWebRoutes`
   - Protocol: HTTPS

2. **Routing layer constructs OAuth authorization URL**: `mbtWebRoutes` builds the Google OAuth 2.0 authorization URL with the appropriate scopes for calendar access and a redirect URI back to the Merchant Booking Tool.
   - From: `mbtWebRoutes`
   - To: (builds URL for client redirect)
   - Protocol: In-process

3. **Redirect merchant to Google OAuth**: The tool redirects the merchant's browser to the Google OAuth 2.0 authorization endpoint.
   - From: `continuumMerchantBookingTool`
   - To: `googleOAuth`
   - Protocol: OAuth 2.0 / HTTPS (browser redirect)

4. **Merchant authorizes calendar access**: Merchant authenticates with Google and grants the requested calendar permissions in Google's UI.
   - From: `merchant`
   - To: `googleOAuth`
   - Protocol: HTTPS

5. **Google redirects back with authorization code**: Google OAuth redirects the merchant's browser back to the Merchant Booking Tool callback URL with an authorization code.
   - From: `googleOAuth`
   - To: `mbtWebRoutes`
   - Protocol: OAuth 2.0 / HTTPS (browser redirect)

6. **Token exchange**: `mbtWebRoutes` exchanges the authorization code for Google OAuth access and refresh tokens via a server-side call to the Google token endpoint.
   - From: `continuumMerchantBookingTool`
   - To: `googleOAuth`
   - Protocol: OAuth 2.0 / HTTPS

7. **Store tokens and confirm sync**: Tokens are stored (via `continuumUniversalMerchantApi` or internal storage per I-tier conventions) and the merchant is shown a confirmation that calendar sync is active.
   - From: `mbtWebRoutes`
   - To: `merchant`
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Merchant denies Google OAuth authorization | OAuth error response handled; user redirected with error message | Calendar sync not connected; merchant shown error |
| Google OAuth endpoint unavailable | Request fails; error surfaced to merchant | Calendar sync unavailable; core booking functions unaffected |
| Token exchange fails | Error returned from Google; surfaced to merchant | Calendar sync not completed; merchant prompted to retry |
| Invalid OAuth credentials configured | Server-side OAuth initiation fails | Calendar sync unavailable; requires configuration fix |

## Sequence Diagram

```
Merchant -> mbtWebRoutes: Initiate Google Calendar connection (HTTPS)
mbtWebRoutes --> Merchant: Redirect to Google OAuth authorization URL
Merchant -> googleOAuth: Authorize calendar access (HTTPS)
googleOAuth --> Merchant: Redirect with authorization code
Merchant -> mbtWebRoutes: OAuth callback with authorization code (HTTPS)
mbtWebRoutes -> googleOAuth: Exchange authorization code for tokens (HTTPS)
googleOAuth --> mbtWebRoutes: Access token + refresh token
mbtWebRoutes --> Merchant: Calendar sync confirmation page (HTTPS)
```

## Related

- Architecture dynamic view: `dynamic-merchant-booking-primary-flow`
- Related flows: [Primary Booking Data Flow](primary-booking-data-flow.md)
- See [Integrations](../integrations.md) for Google OAuth dependency details
