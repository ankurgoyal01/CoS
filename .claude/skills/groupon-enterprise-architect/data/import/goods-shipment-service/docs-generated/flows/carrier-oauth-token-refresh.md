---
service: "goods-shipment-service"
title: "Carrier OAuth Token Refresh"
generated: "2026-03-03"
type: flow
flow_name: "carrier-oauth-token-refresh"
flow_type: scheduled
trigger: "Quartz Auth Token Refresh Job"
participants:
  - "continuumGoodsShipmentService"
  - "continuumGoodsShipmentDatabase"
  - "upsApi"
  - "dhlApi"
  - "fedexApi"
architecture_ref: "components-goodsShipmentService"
---

# Carrier OAuth Token Refresh

## Summary

The Auth Token Refresh Job runs on a Quartz schedule and proactively renews OAuth2 access tokens for carriers that require OAuth2 authentication — UPS, DHL, and FedEx. Tokens are stored in MySQL with expiry metadata. The job resolves each carrier's OAuth adapter, exchanges client credentials for a new access token, and persists the refreshed token. A buffer of `OAUTH2_TOKEN_BUFFER` (2) minutes is applied to refresh tokens before they expire.

## Trigger

- **Type**: schedule
- **Source**: Quartz `AuthTokenRefreshJob`; feature flag `featureFlags.authTokenRefreshJob` must be true
- **Frequency**: Per Quartz schedule (Cron stored in MySQL Quartz tables)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Auth Token Refresh Job | Schedules and initiates the token refresh cycle | `authTokenRefreshJobComponent` |
| Auth Service | Iterates carriers and delegates to OAuth adapters | `authServiceComponent` |
| Carrier OAuth Registry | Resolves the OAuth adapter for each carrier | `carrierOauthRegistryComponent` |
| UPS OAuth Adapter | Fetches a new UPS access token | `upsOauthAdapterComponent` |
| DHL OAuth Adapter | Fetches a new DHL access token | `dhlOauthAdapterComponent` |
| FedEx OAuth Adapter | Fetches a new FedEx access token | `fedexOauthAdapterComponent` |
| UPS API Client | Calls UPS OAuth token endpoint | `upsApiClientComponent` |
| DHL API Client | Calls DHL OAuth token endpoint | `dhlApiClientComponent` |
| FedEx API Client | Calls FedEx OAuth token endpoint | `fedexApiClientComponent` |
| OAuth2 DAO | Reads current token expiry; writes refreshed token | `oauth2DaoComponent` |
| Goods Shipment MySQL | Persistent store for OAuth2 tokens | `continuumGoodsShipmentDatabase` |

## Steps

1. **Job fires**: Quartz fires `AuthTokenRefreshJob` per schedule. Feature flag `featureFlags.authTokenRefreshJob` must be true.
   - From: Quartz scheduler
   - To: `authTokenRefreshJobComponent`
   - Protocol: internal

2. **Delegate to Auth Service**: Job delegates to `authServiceComponent` to process all OAuth-enabled carriers.
   - From: `authTokenRefreshJobComponent`
   - To: `authServiceComponent`
   - Protocol: direct

3. **Check token expiry**: Auth Service reads the current token record from `oauth2DaoComponent`. If the token expires within `OAUTH2_TOKEN_BUFFER` minutes (2 minutes), it triggers a refresh.
   - From: `authServiceComponent`
   - To: `oauth2DaoComponent` → `continuumGoodsShipmentDatabase`
   - Protocol: JDBC/MySQL

4. **Resolve OAuth adapter**: Auth Service queries `carrierOauthRegistryComponent` to get the carrier-specific `CarrierOauthAdapter`.
   - From: `authServiceComponent`
   - To: `carrierOauthRegistryComponent`
   - Protocol: direct

5. **Fetch new token — UPS**: UPS OAuth Adapter calls `UpsApi.generateToken("client_credentials")` at `security/v1/oauth/token` using configured UPS client credentials (from `ups.*` config block).
   - From: `upsOauthAdapterComponent` → `upsApiClientComponent`
   - To: `upsApi`
   - Protocol: REST/HTTPS (form-encoded POST)

6. **Fetch new token — DHL**: DHL OAuth Adapter calls `DhlApi.generateToken("client_credentials", clientId, clientSecret)` at `auth/v4/accesstoken` using configured DHL credentials.
   - From: `dhlOauthAdapterComponent` → `dhlApiClientComponent`
   - To: `dhlApi`
   - Protocol: REST/HTTPS (form-encoded POST)

7. **Fetch new token — FedEx**: FedEx OAuth Adapter calls `FedexApi.generateToken("client_credentials", clientId, clientSecret)` at `oauth/token` using configured FedEx credentials.
   - From: `fedexOauthAdapterComponent` → `fedexApiClientComponent`
   - To: `fedexApi`
   - Protocol: REST/HTTPS (form-encoded POST)

8. **Persist refreshed token**: Auth Service writes the new access token and expiry timestamp to MySQL via `oauth2DaoComponent`.
   - From: `authServiceComponent`
   - To: `oauth2DaoComponent` → `continuumGoodsShipmentDatabase`
   - Protocol: JDBC/MySQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Carrier OAuth API unavailable | Logged as ERROR with prefix `Couldn't get token for <carrier>:` | Token not refreshed; existing token used until expiry; carrier tracking calls will fail when token expires |
| Feature flag disabled | Job does not execute | Tokens not refreshed automatically; manual refresh via `POST /carrier/{carrier}/oauth2-token` endpoint is available |
| Token already valid | Token expiry check prevents unnecessary refresh | No API call made; existing token reused |

## Sequence Diagram

```
QuartzScheduler -> AuthTokenRefreshJob: fire (schedule)
AuthTokenRefreshJob -> AuthService: refreshTokens()
AuthService -> OAuth2DAO: getToken(carrier)
OAuth2DAO -> MySQL: SELECT oauth2 WHERE carrier=<carrier>
MySQL --> OAuth2DAO: token with expiry
AuthService -> CarrierOauthRegistry: getAdapter(carrier)
CarrierOauthRegistry --> AuthService: CarrierOauthAdapter
AuthService -> UpsOauthAdapter: fetchToken()
UpsOauthAdapter -> UpsApiClient: POST security/v1/oauth/token (grant_type=client_credentials)
UpsApiClient -> UpsAPI: token request
UpsAPI --> UpsApiClient: access_token, expiry
UpsOauthAdapter --> AuthService: token
AuthService -> OAuth2DAO: saveToken(carrier, accessToken, expiry)
OAuth2DAO -> MySQL: UPSERT oauth2
[Repeat for DHL and FedEx adapters]
```

## Related

- Architecture dynamic view: `components-goodsShipmentService`
- Related flows: [Carrier Status Refresh](carrier-status-refresh.md)
