---
service: "gdpr"
title: "Web Export Request"
generated: "2026-03-03"
type: flow
flow_name: "web-export-request"
flow_type: synchronous
trigger: "Agent submits the GDPR offboarding web form (POST /data)"
participants:
  - "Application Operations Agent (browser)"
  - "continuumGdprService.webServer"
  - "continuumGdprService.gdprOrchestrator"
  - "cs-token-service"
  - "api-lazlo"
  - "global-subscription-service"
  - "ugc-api-jtier"
  - "m3-placeread"
  - "continuumConsumerDataService"
  - "continuumGdprService.zipExporter"
  - "SMTP relay"
architecture_ref: "dynamic-GdprManualExport"
---

# Web Export Request

## Summary

An Application Operations agent opens the GDPR tool's web UI, fills in a consumer UUID, consumer email, country code, and their own agent credentials, then submits the form. The service validates the inputs, sequentially collects all personal data categories for the specified consumer from six internal Groupon services, packages the data into a ZIP archive of CSV files, streams the archive back to the agent's browser as a file download, emails a copy of the archive to the agent, and then deletes all temporary files.

## Trigger

- **Type**: user-action
- **Source**: Application Operations agent submits `POST /data` via the web UI at `/`
- **Frequency**: On demand (one request per GDPR Subject Access Request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Application Operations Agent | Submits the export request form and receives the resulting ZIP archive | External user |
| Web Server | Validates form inputs, orchestrates the export pipeline, returns the file download response | `continuumGdprService` (webServer component) |
| GDPR Orchestrator | Coordinates sequential calls to all data collectors | `continuumGdprService` (gdprOrchestrator component) |
| `cs-token-service` | Issues scoped access tokens for Lazlo API calls | `tokenService_9f1c2a` (stub) |
| `api-lazlo` | Source of orders, preferences, user profile, Groupon Bucks, and SMS consent data | `lazloService_c7b4e1` (stub) |
| `global-subscription-service` | Source of consumer subscription records | `subscriptionService_a2f7c0` (stub) |
| `ugc-api-jtier` | Source of user-generated reviews | `ugcService_31a0e8` (stub) |
| `m3-placeread` | Enriches reviews with merchant name and city | `placeService_6b9d42` (stub) |
| `consumer-data-service` | Source of consumer profile address locations | `continuumConsumerDataService` |
| ZIP Exporter | Packages all CSV files into a single ZIP archive | `continuumGdprService` (zipExporter component) |
| SMTP relay | Delivers a copy of the ZIP archive to the agent's email | External (email infrastructure) |

## Steps

1. **Agent submits export form**: Agent navigates to `GET /` (renders `index.html`) and submits `POST /data` with `consumer_uuid`, `consumer_email`, `agent_id`, `agent_email`, and `country`
   - From: `Agent browser`
   - To: `continuumGdprService.webServer`
   - Protocol: HTTP POST (form-encoded)

2. **Input validation**: Web Server validates that all five fields are present and that `agent_email` contains the string `groupon`. If validation fails, the form is re-rendered with flash error messages and the flow terminates.
   - From: `continuumGdprService.webServer`
   - To: `continuumGdprService.webServer` (internal)
   - Protocol: direct

3. **Create staging directory**: Web Server creates a temporary directory at `os.TempDir()/{consumer_uuid}/`
   - From: `continuumGdprService.webServer`
   - To: local filesystem
   - Protocol: OS filesystem call

4. **Collect orders**: Web Server calls `getOrders()`, which first requests a token from `cs-token-service` (resource: `get_orders`), then fetches paginated order history from `api-lazlo` at `/api/mobile/{country}/users/{uuid}/orders` (page size 10), and writes `{uuid}-Orders.csv`
   - From: `continuumGdprService.ordersCollector`
   - To: `cs-token-service`, then `api-lazlo`
   - Protocol: HTTP POST (token), HTTP GET (orders)

5. **Collect preferences**: Calls `getPreferences()`, which fetches consumer preference/interest data from `api-lazlo` at `/api/mobile/{country}/consumers/{uuid}/v2/preferences` (no auth token required), and writes `{uuid}-Preference_Center.csv`
   - From: `continuumGdprService.preferencesCollector`
   - To: `api-lazlo`
   - Protocol: HTTP GET

6. **Collect subscriptions**: Calls `getSubscriptions()`, which fetches all subscription records from `global-subscription-service` at `/v2/subscriptions/user/{uuid}` (with `inactives=true&ineligibles=true&countryCode={country}&listTypes=division,channel,notification,coupon_merchant&resolveOptout=true`), and writes `{uuid}-Subscriptions.csv`
   - From: `continuumGdprService.subscriptionsCollector`
   - To: `global-subscription-service`
   - Protocol: HTTP GET

7. **Collect user-generated content**: Calls `getUserGeneratedContent()`, which fetches paginated reviews from `ugc-api-jtier` at `/v1.0/users/{uuid}/reviews` (page size 50), then for each review fetches answer type from `/v1.0/answers/{review_id}` and merchant details from `m3-placeread` at `/placereadservice/v3.0/places/{place_uuid}`, and writes `{uuid}-Reviews.csv`
   - From: `continuumGdprService.ugcCollector`
   - To: `ugc-api-jtier`, `m3-placeread`
   - Protocol: HTTP GET

8. **Collect profile addresses**: Calls `getProfileAddresses()`, which fetches location records from `consumer-data-service` at `v1/consumers/{uuid}/locations` using `X-API-KEY` authentication, and writes `{uuid}-Addresses.csv`
   - From: `continuumGdprService.profileAddressCollector`
   - To: `continuumConsumerDataService`
   - Protocol: HTTP GET

9. **Package ZIP archive**: ZIP Exporter reads all CSV files from the staging directory and creates `{uuid}.zip` in `os.TempDir()`
   - From: `continuumGdprService.zipExporter`
   - To: local filesystem
   - Protocol: direct

10. **Deliver ZIP to browser**: Web Server streams the ZIP file to the agent's browser as an HTTP file download (`ctx.File(filename)`)
    - From: `continuumGdprService.webServer`
    - To: Agent browser
    - Protocol: HTTP response (binary file)

11. **Email ZIP to agent**: `sendfile()` sends the ZIP archive as an email attachment to `agent_email` via the configured SMTP relay. From address is set from `email.from` config.
    - From: `continuumGdprService.webServer`
    - To: SMTP relay
    - Protocol: SMTP

12. **Clean up temporary files**: Web Server deletes the staging directory (`cleanUp`) and the ZIP file (`cleanupZip`) from the OS temp directory
    - From: `continuumGdprService.webServer`
    - To: local filesystem
    - Protocol: OS filesystem call

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing or empty form fields | Flash message added to session; form re-rendered | Agent sees error message on form; no export |
| Agent email does not contain "groupon" | Flash message added; form re-rendered | Agent sees error message; no export |
| Token acquisition failure | Returns error from `getToken()`; HTTP 500 JSON response | Export aborts; agent receives `{"Orders error": "..."}` |
| Lazlo API returns HTTP 400 | Logged as "Bad request"; `nil` response returned | Downstream collector may produce empty CSV |
| Any collector returns a non-nil error | HTTP 500 JSON response with error message | Export aborts at the failing step |
| Subscription JSON unmarshal failure | `panic()` — no graceful recovery | Container restarts; agent request fails |
| ZIP packaging failure | HTTP 500 JSON response | Export aborts; temp files may not be cleaned up |

## Sequence Diagram

```
Agent -> WebServer: POST /data (consumer_uuid, consumer_email, agent_id, agent_email, country)
WebServer -> WebServer: Validate inputs
WebServer -> filesystem: mkdir os.TempDir()/{uuid}/
WebServer -> TokenService: POST /api/v1/{country}/token (method=get_orders)
TokenService --> WebServer: {token}
WebServer -> Lazlo: GET /api/mobile/{country}/users/{uuid}/orders
Lazlo --> WebServer: paginated orders JSON
WebServer -> filesystem: write {uuid}-Orders.csv
WebServer -> Lazlo: GET /api/mobile/{country}/consumers/{uuid}/v2/preferences
Lazlo --> WebServer: preferences JSON
WebServer -> filesystem: write {uuid}-Preference_Center.csv
WebServer -> SubscriptionService: GET /v2/subscriptions/user/{uuid}?inactives=true&...
SubscriptionService --> WebServer: subscriptions JSON
WebServer -> filesystem: write {uuid}-Subscriptions.csv
WebServer -> UgcService: GET /v1.0/users/{uuid}/reviews
UgcService --> WebServer: reviews JSON
WebServer -> PlaceService: GET /placereadservice/v3.0/places/{place_uuid}
PlaceService --> WebServer: place details JSON
WebServer -> filesystem: write {uuid}-Reviews.csv
WebServer -> ConsumerDataService: GET v1/consumers/{uuid}/locations
ConsumerDataService --> WebServer: locations JSON
WebServer -> filesystem: write {uuid}-Addresses.csv
WebServer -> filesystem: zip all CSVs -> {uuid}.zip
WebServer --> Agent: HTTP file download ({uuid}.zip)
WebServer -> SMTPRelay: send email with {uuid}.zip attachment
WebServer -> filesystem: rm -rf staging dir + zip file
```

## Related

- Architecture dynamic view: `dynamic-GdprManualExport`
- Related flows: [Manual CLI Export](manual-cli-export.md), [Token Acquisition](token-acquisition.md), [Data Collection Pipeline](data-collection-pipeline.md)
