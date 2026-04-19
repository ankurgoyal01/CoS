---
service: "mobile-flutter-merchant"
title: "Deal Creation and Publishing"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-creation-and-publishing"
flow_type: synchronous
trigger: "Merchant initiates a new deal from the deals screen"
participants:
  - "continuumMobileFlutterMerchantApp"
  - "mmaPresentationLayer"
  - "mmaApiOrchestrator"
  - "continuumDealManagementApi"
  - "continuumUniversalMerchantApi"
architecture_ref: "dynamic-deal-creation-and-publishing"
---

# Deal Creation and Publishing

## Summary

The Deal Creation and Publishing flow allows a Groupon merchant to draft a new deal, edit its attributes, and submit it for review and publishing through the Deal Management API. The `mmaPresentationLayer` renders the deal creation UI; `mmaApiOrchestrator` sends draft creation and update requests to `continuumDealManagementApi`. Once submitted, the deal enters the Continuum publishing pipeline for review and activation.

## Trigger

- **Type**: user-action
- **Source**: Merchant taps "Create Deal" or "New Deal" on the deals screen
- **Frequency**: On-demand (when merchant creates or edits a deal)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Presentation Layer | Renders deal creation form, validates input, displays submission status | `mmaPresentationLayer` |
| API Orchestrator | Issues draft creation, update, and submit requests to Deal Management API | `mmaApiOrchestrator` |
| Deal Management API | Accepts draft creation and change requests; manages deal lifecycle | `continuumDealManagementApi` |
| Universal Merchant API | Provides existing deal list and merchant account context | `continuumUniversalMerchantApi` |

## Steps

1. **Load Existing Deals**: `mmaPresentationLayer` requests the merchant's current deal list to provide context.
   - From: `mmaPresentationLayer`
   - To: `mmaApiOrchestrator`
   - Protocol: Direct

2. **Fetch Deals from API**: `mmaApiOrchestrator` calls `continuumUniversalMerchantApi` to retrieve the merchant's deal portfolio.
   - From: `mmaApiOrchestrator`
   - To: `continuumUniversalMerchantApi`
   - Protocol: REST/HTTP

3. **Render Deal Creation Form**: Merchant taps to create a new deal; `mmaPresentationLayer` displays the deal creation form fields (title, discount, dates, category, etc.).
   - From: `mmaPresentationLayer`
   - To: Merchant (UI render)
   - Protocol: Direct

4. **Create Deal Draft**: Merchant fills in deal attributes and saves; `mmaApiOrchestrator` sends a draft creation request to `continuumDealManagementApi`.
   - From: `mmaApiOrchestrator`
   - To: `continuumDealManagementApi`
   - Protocol: REST/HTTP

5. **Receive Draft ID**: `continuumDealManagementApi` returns a draft deal ID; `mmaApiOrchestrator` returns it to `mmaPresentationLayer` for state management.
   - From: `continuumDealManagementApi`
   - To: `mmaApiOrchestrator`
   - Protocol: REST/HTTP

6. **Edit and Update Draft**: Merchant continues editing deal fields; each save triggers an update request via `mmaApiOrchestrator` to `continuumDealManagementApi`.
   - From: `mmaApiOrchestrator`
   - To: `continuumDealManagementApi`
   - Protocol: REST/HTTP

7. **Submit Deal for Publishing**: Merchant taps "Submit"; `mmaApiOrchestrator` sends the final submission request to `continuumDealManagementApi`.
   - From: `mmaApiOrchestrator`
   - To: `continuumDealManagementApi`
   - Protocol: REST/HTTP

8. **Display Submission Confirmation**: `continuumDealManagementApi` confirms the submission; `mmaPresentationLayer` shows a success state and returns the merchant to the deals list.
   - From: `continuumDealManagementApi`
   - To: `mmaPresentationLayer` (via `mmaApiOrchestrator`)
   - Protocol: REST/HTTP → Direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Validation failure on deal fields | Client-side validation in `mmaPresentationLayer` before API call | Form error messages displayed; submission blocked |
| Draft creation rejected by Deal Management API | API returns error response | Error message displayed; merchant remains on form |
| Network failure during draft save | HTTP error in `mmaApiOrchestrator` | Draft save failure shown; merchant can retry |
| Submission rejected (compliance/review rules) | `continuumDealManagementApi` returns rejection reason | Rejection details displayed; merchant can revise deal |

## Sequence Diagram

```
Merchant -> mmaPresentationLayer: Taps "Create Deal"
mmaPresentationLayer -> mmaApiOrchestrator: fetchDeals()
mmaApiOrchestrator -> continuumUniversalMerchantApi: GET /merchant/deals
continuumUniversalMerchantApi --> mmaApiOrchestrator: Deal list
mmaApiOrchestrator --> mmaPresentationLayer: Deal list
mmaPresentationLayer -> Merchant: Render deal creation form
Merchant -> mmaPresentationLayer: Fills form, taps Save Draft
mmaPresentationLayer -> mmaApiOrchestrator: createDealDraft(attributes)
mmaApiOrchestrator -> continuumDealManagementApi: POST /deals/draft
continuumDealManagementApi --> mmaApiOrchestrator: {draftId}
mmaApiOrchestrator --> mmaPresentationLayer: Draft saved (draftId)
Merchant -> mmaPresentationLayer: Taps Submit
mmaPresentationLayer -> mmaApiOrchestrator: submitDeal(draftId)
mmaApiOrchestrator -> continuumDealManagementApi: POST /deals/{draftId}/submit
continuumDealManagementApi --> mmaApiOrchestrator: Submission confirmed
mmaApiOrchestrator --> mmaPresentationLayer: Success
mmaPresentationLayer -> Merchant: Show confirmation, return to deals list
```

## Related

- Architecture dynamic view: `dynamic-deal-creation-and-publishing`
- Related flows: [Redemption Processing](redemption-processing.md), [Offline and Sync Workflow](offline-and-sync-workflow.md)
