---
service: "gdpr"
title: "Data Collection Pipeline"
generated: "2026-03-03"
type: flow
flow_name: "data-collection-pipeline"
flow_type: synchronous
trigger: "GDPR Orchestrator initiates sequential data collection after request validation"
participants:
  - "continuumGdprService.gdprOrchestrator"
  - "continuumGdprService.ordersCollector"
  - "continuumGdprService.preferencesCollector"
  - "continuumGdprService.subscriptionsCollector"
  - "continuumGdprService.ugcCollector"
  - "continuumGdprService.profileAddressCollector"
  - "continuumGdprService.csvWriter"
  - "continuumGdprService.zipExporter"
  - "cs-token-service"
  - "api-lazlo"
  - "global-subscription-service"
  - "ugc-api-jtier"
  - "m3-placeread"
  - "continuumConsumerDataService"
architecture_ref: "dynamic-GdprManualExport"
---

# Data Collection Pipeline

## Summary

The Data Collection Pipeline is the core processing sequence of the GDPR export. The GDPR Orchestrator drives five sequential data collectors, each of which calls one or more internal Groupon services, transforms the response into rows, and writes a CSV file to the staging directory. After all collectors complete successfully, the ZIP Exporter packages all CSV files into a single archive. The pipeline runs synchronously — if any collector fails, the entire export is aborted and an error is returned to the requesting agent.

## Trigger

- **Type**: api-call (internal orchestration)
- **Source**: Called by `getGdprData()` (CLI mode) or sequentially within `PostData()` handler (web mode) after input validation passes
- **Frequency**: Once per export request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GDPR Orchestrator | Drives the sequential pipeline; aborts on first error | `continuumGdprService` (gdprOrchestrator component) |
| Orders Collector | Fetches paginated order history; writes Orders CSV | `continuumGdprService` (ordersCollector component) |
| Preferences Collector | Fetches preference/interest data; writes Preference Center CSV | `continuumGdprService` (preferencesCollector component) |
| Subscriptions Collector | Fetches subscription records; writes Subscriptions CSV | `continuumGdprService` (subscriptionsCollector component) |
| UGC Collector | Fetches reviews and enriches with place data; writes Reviews CSV | `continuumGdprService` (ugcCollector component) |
| Profile Address Collector | Fetches profile addresses; writes Addresses CSV | `continuumGdprService` (profileAddressCollector component) |
| CSV Writer | Writes each collector's output to disk as a named CSV file | `continuumGdprService` (csvWriter component) |
| ZIP Exporter | Packages all staged CSV files into a ZIP archive | `continuumGdprService` (zipExporter component) |
| `cs-token-service` | Issues scoped tokens for Lazlo API calls | `tokenService_9f1c2a` (stub) |
| `api-lazlo` | Provides orders and preferences data | `lazloService_c7b4e1` (stub) |
| `global-subscription-service` | Provides subscription records | `subscriptionService_a2f7c0` (stub) |
| `ugc-api-jtier` | Provides user reviews and answer metadata | `ugcService_31a0e8` (stub) |
| `m3-placeread` | Provides merchant name and city for review enrichment | `placeService_6b9d42` (stub) |
| `consumer-data-service` | Provides profile-level location addresses | `continuumConsumerDataService` |

## Steps

1. **Collect orders**: Orchestrator calls `getOrders()`
   - Acquires token from `cs-token-service` (resource: `get_orders`) via [Token Acquisition](token-acquisition.md) flow
   - Fetches order pages from `api-lazlo` at `GET /api/mobile/{country}/users/{uuid}/orders?client_id=...&type=all&show=default,order(adjustments,unitPrice),deal(dealUrl),groupons&offset={n}&limit=10` until `offset >= pagination.count`
   - Transforms orders into rows with fields: `Purchase_Date`, `Groupon_ID`, `Expiration_Date`, `Redemption_Status`, `Order_Status`, `Groupon_Amount`, `Order_Discount`, `Deal_Title`, `Deal_URL`, shipping address fields (10 fields)
   - Sorts rows by `Purchase_Date` ascending
   - Writes `{uuid}-Orders.csv` via CSV Writer
   - From: `ordersCollector` → `cs-token-service` → `api-lazlo` → `csvWriter`
   - Protocol: HTTP POST (token), HTTP GET (orders)

2. **Collect preferences**: Orchestrator calls `getPreferences()`
   - Fetches preference data from `api-lazlo` at `GET /api/mobile/{country}/consumers/{uuid}/v2/preferences?client_id=...` (no auth token — uses unauthenticated Lazlo call)
   - Filters to only "liked" interests (`selection == "like"`)
   - Writes `{uuid}-Preference_Center.csv` with column: `Selected_Interest_Category`
   - From: `preferencesCollector` → `api-lazlo` → `csvWriter`
   - Protocol: HTTP GET

3. **Collect subscriptions**: Orchestrator calls `getSubscriptions()`
   - Fetches subscriptions from `global-subscription-service` at `GET /v2/subscriptions/user/{uuid}?inactives=true&ineligibles=true&countryCode={country}&listTypes=division,channel,notification,coupon_merchant&resolveOptout=true`
   - Transforms to rows with fields: `Subscribed_Category_or_City`, `Subscription_Type`, `Status` (Active/Inactive)
   - Writes `{uuid}-Subscriptions.csv`
   - From: `subscriptionsCollector` → `global-subscription-service` → `csvWriter`
   - Protocol: HTTP GET

4. **Collect user-generated content**: Orchestrator calls `getUserGeneratedContent()`
   - Fetches review pages from `ugc-api-jtier` at `GET /v1.0/users/{uuid}/reviews?order_by=time&offset={n}&limit=50` until `total <= 49` or `total >= offset`
   - For each review: fetches answer type from `ugc-api-jtier` at `GET /v1.0/answers/{review_id}`; fetches merchant name and city from `m3-placeread` at `GET /placereadservice/v3.0/places/{place_uuid}?view_type=internal&legacy=true&client_id=...`
   - Transforms to rows with fields: `Date`, `Rating`, `Review_Text`, `Question_Type`, `Survey_Type`, `Merchant_Name`, `City`
   - Writes `{uuid}-Reviews.csv`
   - From: `ugcCollector` → `ugc-api-jtier` → `m3-placeread` → `csvWriter`
   - Protocol: HTTP GET

5. **Collect profile addresses**: Orchestrator calls `getProfileAddresses()`
   - Fetches location records from `consumer-data-service` at `GET v1/consumers/{uuid}/locations` with `X-API-KEY` header
   - Transforms to rows with fields: `Name`, `Street_Number`, `Street`, `City`, `State`, `District`, `Post_Code`, `Country`
   - Writes `{uuid}-Addresses.csv`
   - From: `profileAddressCollector` → `continuumConsumerDataService` → `csvWriter`
   - Protocol: HTTP GET

6. **Package ZIP archive**: Orchestrator calls `zipFile(path, consumerUuid)`
   - ZIP Exporter reads all CSV files from `os.TempDir()/{uuid}/`
   - Creates `os.TempDir()/{uuid}.zip`
   - Returns ZIP file path for delivery
   - From: `zipExporter` → local filesystem
   - Protocol: direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Any collector returns a non-nil error | Orchestrator propagates error immediately; subsequent collectors are not called | Export aborts; HTTP 500 returned in web mode |
| `global-subscription-service` returns unparseable JSON | `panic()` in `getSubscriptions()` | Container restart; no graceful error to agent |
| UGC review pagination loop exits early | Logged; partial reviews may be written | Partial Reviews CSV — no explicit error returned to agent |
| Place details unavailable for a review | Error returned; `getUserGeneratedContent()` returns error | Export aborts at UGC step |
| ZIP packaging fails | Error returned from `zipFile()` | HTTP 500 returned; temp files may remain in `os.TempDir()` |

## Sequence Diagram

```
Orchestrator -> OrdersCollector: getOrders()
OrdersCollector -> TokenService: POST /api/v1/{country}/token (get_orders)
TokenService --> OrdersCollector: {token}
OrdersCollector -> Lazlo: GET /api/mobile/{country}/users/{uuid}/orders (paginated)
Lazlo --> OrdersCollector: orders JSON
OrdersCollector -> CSVWriter: write {uuid}-Orders.csv

Orchestrator -> PreferencesCollector: getPreferences()
PreferencesCollector -> Lazlo: GET /api/mobile/{country}/consumers/{uuid}/v2/preferences
Lazlo --> PreferencesCollector: preferences JSON
PreferencesCollector -> CSVWriter: write {uuid}-Preference_Center.csv

Orchestrator -> SubscriptionsCollector: getSubscriptions()
SubscriptionsCollector -> SubscriptionService: GET /v2/subscriptions/user/{uuid}?...
SubscriptionService --> SubscriptionsCollector: subscriptions JSON
SubscriptionsCollector -> CSVWriter: write {uuid}-Subscriptions.csv

Orchestrator -> UGCCollector: getUserGeneratedContent()
UGCCollector -> UGCService: GET /v1.0/users/{uuid}/reviews (paginated)
UGCService --> UGCCollector: reviews JSON
UGCCollector -> UGCService: GET /v1.0/answers/{review_id} (per review)
UGCService --> UGCCollector: answer type JSON
UGCCollector -> PlaceService: GET /placereadservice/v3.0/places/{place_uuid} (per review)
PlaceService --> UGCCollector: place name + city JSON
UGCCollector -> CSVWriter: write {uuid}-Reviews.csv

Orchestrator -> ProfileAddressCollector: getProfileAddresses()
ProfileAddressCollector -> ConsumerDataService: GET v1/consumers/{uuid}/locations
ConsumerDataService --> ProfileAddressCollector: locations JSON
ProfileAddressCollector -> CSVWriter: write {uuid}-Addresses.csv

Orchestrator -> ZIPExporter: zipFile(path, uuid)
ZIPExporter --> Orchestrator: {uuid}.zip path
```

## Related

- Architecture dynamic view: `dynamic-GdprManualExport`
- Related flows: [Web Export Request](web-export-request.md), [Token Acquisition](token-acquisition.md), [Manual CLI Export](manual-cli-export.md)
