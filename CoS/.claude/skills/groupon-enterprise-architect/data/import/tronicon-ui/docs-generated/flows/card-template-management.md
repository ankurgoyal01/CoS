---
service: "tronicon-ui"
title: "Card Template Management"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "card-template-management"
flow_type: synchronous
trigger: "Operator submits a card template definition or update via the Tronicon UI browser application"
participants:
  - "troniconUiWeb"
  - "troniconUi_webControllers"
  - "troniconUi_dataAccess"
  - "continuumTroniconUiDatabase"
  - "cardUiPreview"
architecture_ref: "dynamic-troniconUi-card-template-management"
---

# Card Template Management

## Summary

This flow covers the process by which a Groupon merchandising operator defines, configures, and applies reusable card templates within Tronicon UI. Templates standardize card layout and field configuration across campaigns. Operators create or update templates via the `/cardatron/templates` endpoints, and the resulting template definitions are stored in `continuumTroniconUiDatabase`. Card UI Preview is used to verify the visual output of a template before it is applied to live cards.

## Trigger

- **Type**: user-action
- **Source**: Operator accesses the templates management page at `GET /cardatron/templates` and submits a create or update form
- **Frequency**: On-demand, when a new card layout is needed or an existing template requires modification

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator (browser) | Defines template properties and triggers preview | — |
| Tronicon UI Web App | Handles HTTP routing and orchestrates persistence and preview calls | `troniconUiWeb` |
| Web Controllers | Routes template requests and validates submitted configuration | `troniconUi_webControllers` |
| Data Access Layer | Reads and writes template records in the database | `troniconUi_dataAccess` |
| Tronicon UI Database | Persists template definitions | `continuumTroniconUiDatabase` |
| Card UI Preview | Renders a sample card using the new template for operator review | `cardUiPreview` |

## Steps

1. **Lists existing templates**: Operator navigates to `GET /cardatron/templates`; controller queries the data access layer and returns the template list.
   - From: `Operator`
   - To: `troniconUi_webControllers`
   - Protocol: REST/HTTP (browser GET)

2. **Reads templates from database**: Data access layer executes SELECT query against `continuumTroniconUiDatabase`.
   - From: `troniconUi_dataAccess`
   - To: `continuumTroniconUiDatabase`
   - Protocol: SQL over TCP

3. **Submits template definition**: Operator fills in template name, field mappings, and layout configuration, then submits `POST /cardatron/templates`.
   - From: `Operator`
   - To: `troniconUi_webControllers`
   - Protocol: REST/HTTP (browser form POST)

4. **Validates template configuration**: Controller validates the submitted template against the property schema defined in `gconfig/cardatron.json`.
   - From: `troniconUi_webControllers`
   - To: `bootstrapService` (in-process config)
   - Protocol: direct (in-process)

5. **Persists template**: Data access layer executes INSERT or UPDATE for the template record.
   - From: `troniconUi_dataAccess`
   - To: `continuumTroniconUiDatabase`
   - Protocol: SQL over TCP

6. **Requests template preview**: Operator navigates to the preview for a card using the new template; controller requests Card UI Preview to render a sample card with the template applied.
   - From: `troniconUiWeb`
   - To: `cardUiPreview`
   - Protocol: REST/HTTP

7. **Returns rendered preview**: Card UI Preview renders and returns the sample card; operator reviews the visual output.
   - From: `cardUiPreview`
   - To: `troniconUiWeb`
   - Protocol: REST/HTTP

8. **Applies template to cards**: Operator creates or updates cards referencing the confirmed template via `POST /cardatron/cards` or `POST /cardatron/card/:id`.
   - From: `Operator`
   - To: `troniconUi_webControllers`
   - Protocol: REST/HTTP (browser form POST)

9. **Writes card-template association**: Data access layer updates card records to reference the new template ID.
   - From: `troniconUi_dataAccess`
   - To: `continuumTroniconUiDatabase`
   - Protocol: SQL over TCP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Template validation fails (schema mismatch with cardatron.json) | Controller returns validation error response | Operator sees error; template not persisted; operator must correct configuration |
| Database write fails | SQLAlchemy raises exception; controller returns HTTP 500 | Template not saved; operator must retry |
| Card UI Preview unavailable during template preview | HTTP error surfaced to browser | Template is saved; preview unavailable until service recovers |

## Sequence Diagram

```
Operator -> troniconUiWeb: GET /cardatron/templates
troniconUiWeb -> continuumTroniconUiDatabase: SELECT templates
continuumTroniconUiDatabase --> troniconUiWeb: Template list
troniconUiWeb --> Operator: Templates page

Operator -> troniconUiWeb: POST /cardatron/templates
troniconUiWeb -> troniconUiWeb: Validate against gconfig/cardatron.json
troniconUiWeb -> continuumTroniconUiDatabase: INSERT/UPDATE template
continuumTroniconUiDatabase --> troniconUiWeb: OK
troniconUiWeb --> Operator: Template saved

Operator -> troniconUiWeb: GET /cardatron/card/preview/:id
troniconUiWeb -> cardUiPreview: GET /render/:id (with template)
cardUiPreview --> troniconUiWeb: Rendered sample card
troniconUiWeb --> Operator: Template preview

Operator -> troniconUiWeb: POST /cardatron/card/:id
troniconUiWeb -> continuumTroniconUiDatabase: UPDATE card SET template_id=...
continuumTroniconUiDatabase --> troniconUiWeb: OK
troniconUiWeb --> Operator: Card updated with template
```

## Related

- Architecture dynamic view: `dynamic-troniconUi-card-template-management`
- Related flows: [Campaign Card Creation](campaign-card-creation.md)
- See [Configuration](../configuration.md) for `gconfig/cardatron.json` details
- See [Data Stores](../data-stores.md) for `templates` and `cards` entity context
