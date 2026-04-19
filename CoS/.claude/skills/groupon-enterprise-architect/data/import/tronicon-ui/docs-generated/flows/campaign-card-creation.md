---
service: "tronicon-ui"
title: "Campaign Card Creation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "campaign-card-creation"
flow_type: synchronous
trigger: "Operator submits campaign group creation form in the Tronicon UI browser application"
participants:
  - "troniconUiWeb"
  - "troniconUi_webControllers"
  - "troniconUi_dataAccess"
  - "continuumTroniconUiDatabase"
  - "campaignService"
  - "cardUiPreview"
architecture_ref: "dynamic-troniconUi-campaign-card-creation"
---

# Campaign Card Creation

## Summary

This flow covers the end-to-end process by which a Groupon merchandising operator creates a complete campaign card set within Tronicon UI. The operator progresses through a four-stage hierarchy — campaign group, campaign, deck, and individual cards — before optionally previewing the resulting card. All entities are persisted to `continuumTroniconUiDatabase`, and campaign records are also synchronized to the Campaign Service via the `/c/` proxy. The flow is fully synchronous and browser-driven.

## Trigger

- **Type**: user-action
- **Source**: Operator submits the campaign group creation form at `POST /cpgnGroups/add` in the Tronicon UI browser session
- **Frequency**: On-demand, per operator workflow

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator (browser) | Initiates all form submissions; reviews card preview | — |
| Tronicon UI Web App | Handles all HTTP requests; orchestrates persistence and service calls | `troniconUiWeb` |
| Web Controllers | Routes requests and validates form input | `troniconUi_webControllers` |
| Data Access Layer | Persists campaign group, campaign, deck, and card entities | `troniconUi_dataAccess` |
| Tronicon UI Database | Stores all created entities | `continuumTroniconUiDatabase` |
| Campaign Service | Receives campaign record via proxy for cross-service consistency | `campaignService` |
| Card UI Preview | Renders card preview for operator review | `cardUiPreview` |

## Steps

1. **Creates campaign group**: Operator submits `POST /cpgnGroups/add` with campaign group name and configuration.
   - From: `Operator`
   - To: `troniconUi_webControllers`
   - Protocol: REST/HTTP (browser form POST)

2. **Persists campaign group**: Web controller invokes the data access layer to insert the new campaign group record.
   - From: `troniconUi_webControllers`
   - To: `troniconUi_dataAccess`
   - Protocol: direct (in-process)

3. **Writes campaign group to database**: Data access layer executes INSERT via SQLAlchemy ORM.
   - From: `troniconUi_dataAccess`
   - To: `continuumTroniconUiDatabase`
   - Protocol: SQL over TCP

4. **Creates campaign**: Operator submits campaign creation form associated with the new campaign group.
   - From: `Operator`
   - To: `troniconUi_webControllers`
   - Protocol: REST/HTTP (browser form POST)

5. **Forwards campaign to Campaign Service**: Controller proxies the campaign creation request via `POST /c/campaigns` to ensure cross-service consistency.
   - From: `troniconUiWeb`
   - To: `campaignService`
   - Protocol: REST/HTTP (proxy)

6. **Persists campaign locally**: Data access layer writes the campaign record to `continuumTroniconUiDatabase`.
   - From: `troniconUi_dataAccess`
   - To: `continuumTroniconUiDatabase`
   - Protocol: SQL over TCP

7. **Creates deck**: Operator submits `POST /cardatron/decks` to create a deck associated with the campaign.
   - From: `Operator`
   - To: `troniconUi_webControllers`
   - Protocol: REST/HTTP (browser form POST)

8. **Persists deck**: Data access layer writes the deck record to `continuumTroniconUiDatabase`.
   - From: `troniconUi_dataAccess`
   - To: `continuumTroniconUiDatabase`
   - Protocol: SQL over TCP

9. **Creates cards**: Operator submits `POST /cardatron/cards` one or more times to add cards to the deck, specifying template, content, and configuration for each card.
   - From: `Operator`
   - To: `troniconUi_webControllers`
   - Protocol: REST/HTTP (browser form POST)

10. **Persists cards**: Data access layer writes each card record to `continuumTroniconUiDatabase`.
    - From: `troniconUi_dataAccess`
    - To: `continuumTroniconUiDatabase`
    - Protocol: SQL over TCP

11. **Requests card preview**: Operator navigates to `GET /cardatron/card/preview/:id`; controller calls Card UI Preview service to render the card.
    - From: `troniconUiWeb`
    - To: `cardUiPreview`
    - Protocol: REST/HTTP

12. **Returns rendered preview**: Card UI Preview returns rendered card HTML/content; controller returns preview to operator browser.
    - From: `cardUiPreview`
    - To: `troniconUiWeb`
    - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Database write fails (any step) | SQLAlchemy raises exception; web.py controller returns HTTP 500 | Operator sees error page; entity not persisted; operator must retry |
| Campaign Service proxy returns error | HTTP error from `/c/` proxy surfaced to browser | Campaign may be partially created; operator notified via error response |
| Card UI Preview unavailable | HTTP error returned; preview page shows error | Card exists in database; operator cannot preview until service recovers |

## Sequence Diagram

```
Operator -> troniconUiWeb: POST /cpgnGroups/add
troniconUiWeb -> continuumTroniconUiDatabase: INSERT campaign_group
continuumTroniconUiDatabase --> troniconUiWeb: OK
troniconUiWeb --> Operator: Campaign group created

Operator -> troniconUiWeb: POST /c/campaigns (via proxy)
troniconUiWeb -> campaignService: POST /campaigns
campaignService --> troniconUiWeb: 201 Created
troniconUiWeb -> continuumTroniconUiDatabase: INSERT campaign
continuumTroniconUiDatabase --> troniconUiWeb: OK
troniconUiWeb --> Operator: Campaign created

Operator -> troniconUiWeb: POST /cardatron/decks
troniconUiWeb -> continuumTroniconUiDatabase: INSERT deck
continuumTroniconUiDatabase --> troniconUiWeb: OK
troniconUiWeb --> Operator: Deck created

Operator -> troniconUiWeb: POST /cardatron/cards
troniconUiWeb -> continuumTroniconUiDatabase: INSERT card
continuumTroniconUiDatabase --> troniconUiWeb: OK
troniconUiWeb --> Operator: Card created

Operator -> troniconUiWeb: GET /cardatron/card/preview/:id
troniconUiWeb -> cardUiPreview: GET /render/:id
cardUiPreview --> troniconUiWeb: Rendered card
troniconUiWeb --> Operator: Card preview
```

## Related

- Architecture dynamic view: `dynamic-troniconUi-campaign-card-creation`
- Related flows: [Card Template Management](card-template-management.md), [Geo Polygon Campaign Targeting](geo-polygon-campaign-targeting.md)
- See [API Surface](../api-surface.md) for endpoint details
- See [Data Stores](../data-stores.md) for entity schema context
