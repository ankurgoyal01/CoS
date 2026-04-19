---
service: "mobile-flutter-merchant"
title: "Offline and Sync Workflow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "offline-and-sync-workflow"
flow_type: asynchronous
trigger: "App detects network connectivity change (offline to online, or app foreground)"
participants:
  - "continuumMobileFlutterMerchantApp"
  - "mmaPresentationLayer"
  - "mmaApiOrchestrator"
  - "continuumUniversalMerchantApi"
  - "continuumDealManagementApi"
  - "continuumPaymentsService"
architecture_ref: "dynamic-offline-and-sync-workflow"
---

# Offline and Sync Workflow

## Summary

The Offline and Sync Workflow ensures the Mobile Flutter Merchant app remains usable when network connectivity is unavailable. The app reads cached deal, voucher, payment, and redemption data from the local Drift SQLite store when offline. When connectivity is restored — either on app foreground or via a connectivity change event — the `mmaApiOrchestrator` triggers a background sync, fetching fresh data from Continuum backend services and writing updated records to the local cache. This flow supports the merchant's ability to process redemptions and review data even in low-connectivity environments.

## Trigger

- **Type**: event (connectivity change) or user-action (app foreground)
- **Source**: Device network connectivity transitions from offline to online; or app returns to foreground
- **Frequency**: Asynchronous — triggered whenever connectivity is restored or app resumes

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Presentation Layer | Displays offline/online indicator and stale data banners; triggers refresh on foreground | `mmaPresentationLayer` |
| API Orchestrator | Manages sync requests to Continuum services on reconnection; reads from and writes to local cache | `mmaApiOrchestrator` |
| Local SQLite / Drift | Primary local data store; serves cached records when offline | `continuumMobileFlutterMerchantApp` (on-device) |
| Universal Merchant API | Source of truth for deals, vouchers, and dashboard data | `continuumUniversalMerchantApi` |
| Deal Management API | Source of truth for deal drafts and change requests | `continuumDealManagementApi` |
| Payments Service | Source of truth for payment schedules and settlement data | `continuumPaymentsService` |

## Steps

### Path A: Operating Offline

1. **Detect Offline State**: The app detects that network connectivity is unavailable (connectivity plugin or HTTP failure).
   - From: Device OS (network state)
   - To: `mmaApiOrchestrator`
   - Protocol: Platform connectivity API

2. **Display Offline Indicator**: `mmaPresentationLayer` shows an offline/connectivity banner to inform the merchant of degraded mode.
   - From: `mmaPresentationLayer`
   - To: Merchant (UI)
   - Protocol: Direct

3. **Serve Cached Data**: All data requests from `mmaPresentationLayer` are routed to the Drift SQLite local store instead of making network calls.
   - From: `mmaApiOrchestrator`
   - To: Local SQLite (Drift ORM)
   - Protocol: Direct

4. **Process Redemptions Offline**: Merchants can still process redemptions; results are written to the local Drift store with a "pending sync" status.
   - From: `mmaApiOrchestrator`
   - To: Local SQLite (Drift ORM)
   - Protocol: Direct

### Path B: Reconnection and Sync

5. **Detect Connectivity Restored**: The app detects that network connectivity has been restored.
   - From: Device OS (network state)
   - To: `mmaApiOrchestrator`
   - Protocol: Platform connectivity API

6. **Dismiss Offline Indicator**: `mmaPresentationLayer` hides the offline banner and signals sync in progress.
   - From: `mmaPresentationLayer`
   - To: Merchant (UI)
   - Protocol: Direct

7. **Sync Pending Redemptions**: `mmaApiOrchestrator` submits any redemption records with "pending sync" status to `continuumUniversalMerchantApi`.
   - From: `mmaApiOrchestrator`
   - To: `continuumUniversalMerchantApi`
   - Protocol: REST/HTTP

8. **Refresh Deals Data**: `mmaApiOrchestrator` fetches updated deals and voucher data from `continuumUniversalMerchantApi` and writes results to the Drift store.
   - From: `mmaApiOrchestrator`
   - To: `continuumUniversalMerchantApi`
   - Protocol: REST/HTTP

9. **Refresh Deal Drafts**: `mmaApiOrchestrator` fetches updated deal draft status from `continuumDealManagementApi` and writes to the Drift store.
   - From: `mmaApiOrchestrator`
   - To: `continuumDealManagementApi`
   - Protocol: REST/HTTP

10. **Refresh Payment Data**: `mmaApiOrchestrator` fetches updated payment schedule data from `continuumPaymentsService` and writes to the Drift store.
    - From: `mmaApiOrchestrator`
    - To: `continuumPaymentsService`
    - Protocol: REST/HTTP

11. **Update UI with Fresh Data**: Redux state is updated with synced data; `mmaPresentationLayer` re-renders screens with current information.
    - From: `mmaApiOrchestrator`
    - To: `mmaPresentationLayer` (via Redux)
    - Protocol: Direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Pending redemption sync fails on reconnection | `mmaApiOrchestrator` retries; marks record with retry count | Retry attempted; if max retries exceeded, merchant shown error to manually re-verify |
| Partial sync failure (one service unavailable) | Other sync requests complete; failed domain retried | Affected screen shows stale data indicator; other screens refresh normally |
| Drift SQLite read error during offline mode | Database error surfaced to `mmaPresentationLayer` | Error state shown; merchant advised to reconnect |
| Data conflict (local vs remote) | Remote data takes precedence on sync | Local records overwritten with server state; pending redemptions take priority |

## Sequence Diagram

```
// Path A: Offline
DeviceOS -> mmaApiOrchestrator: Network offline event
mmaApiOrchestrator --> mmaPresentationLayer: Set offline state (Redux)
mmaPresentationLayer -> Merchant: Show offline banner
Merchant -> mmaPresentationLayer: Navigates / browses screens
mmaPresentationLayer -> mmaApiOrchestrator: fetchData() [all screens]
mmaApiOrchestrator -> LocalSQLite: Read cached records
LocalSQLite --> mmaApiOrchestrator: Cached data
mmaApiOrchestrator --> mmaPresentationLayer: Cached data (stale indicator)

// Path B: Reconnection sync
DeviceOS -> mmaApiOrchestrator: Network online event
mmaApiOrchestrator --> mmaPresentationLayer: Clear offline state
mmaApiOrchestrator -> LocalSQLite: Find pending redemptions
LocalSQLite --> mmaApiOrchestrator: Pending records
mmaApiOrchestrator -> continuumUniversalMerchantApi: POST /vouchers/{code}/redeem (pending)
continuumUniversalMerchantApi --> mmaApiOrchestrator: Sync confirmed
mmaApiOrchestrator -> continuumUniversalMerchantApi: GET /merchant/deals + vouchers
continuumUniversalMerchantApi --> mmaApiOrchestrator: Fresh data
mmaApiOrchestrator -> continuumDealManagementApi: GET /deals/drafts
continuumDealManagementApi --> mmaApiOrchestrator: Fresh draft data
mmaApiOrchestrator -> continuumPaymentsService: GET /merchant/payments/schedule
continuumPaymentsService --> mmaApiOrchestrator: Fresh payment data
mmaApiOrchestrator -> LocalSQLite: Write synced records
mmaApiOrchestrator --> mmaPresentationLayer: Updated data (Redux)
mmaPresentationLayer -> Merchant: Re-render screens with fresh data
```

## Related

- Architecture dynamic view: `dynamic-offline-and-sync-workflow`
- Related flows: [Redemption Processing](redemption-processing.md), [Deal Creation and Publishing](deal-creation-and-publishing.md), [Payment and Settlement Inquiry](payment-and-settlement-inquiry.md)
