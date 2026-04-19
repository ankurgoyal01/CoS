---
service: "deal_wizard"
title: "Merchant Fine Print Configuration"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "merchant-fine-print-configuration"
flow_type: synchronous
trigger: "Sales representative reaches the Fine Prints step in the deal creation wizard"
participants:
  - "dealWizardWebUi"
  - "redisCache"
architecture_ref: "dynamic-merchantFinePrintConfiguration"
---

# Merchant Fine Print Configuration

## Summary

This flow handles the selection and customization of fine print content for a deal during the wizard process. Fine prints are locale-specific legal terms, exclusions, and usage conditions that appear on published Groupon deals. The Web UI loads available fine print options from MySQL (filtered by locale from Redis feature flags), presents them for selection and optional customization by the sales representative, and persists the final selection to MySQL.

## Trigger

- **Type**: user-action
- **Source**: Sales representative navigates to the Fine Prints step of the deal wizard (via `GET /deals/:id/fine_prints`)
- **Frequency**: On-demand; during each deal wizard session (may be revisited for edits)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Sales Representative (User) | Selects and customizes fine print clauses for the deal | — |
| Deal Wizard Web UI | Renders fine print selection form; validates and persists selections | `dealWizardWebUi` |
| Redis Cache | Reads locale flags to filter applicable fine print content | `redisCache` |
| MySQL | Source of fine print content records; target for persisted selections | `continuumDealWizardWebApp` (owned DB) |

## Steps

1. **Receive Fine Prints Request**: Web UI receives `GET /deals/:id/fine_prints` from the sales rep's browser.
   - From: `Sales Representative`
   - To: `dealWizardWebUi`
   - Protocol: HTTPS (browser)

2. **Read Locale Flags**: Web UI reads locale feature flags from Redis to determine the applicable region and locale for fine print filtering.
   - From: `dealWizardWebUi`
   - To: `redisCache`
   - Protocol: Direct (in-process Redis)

3. **Load Fine Print Options**: Web UI queries MySQL for fine print records matching the deal's locale.
   - From: `dealWizardWebUi`
   - To: MySQL (`dealWizardMysql`)
   - Protocol: Direct (ActiveRecord — `fine_prints` table filtered by `locale_id`)

4. **Render Fine Prints Form**: Web UI renders the fine print selection UI, displaying available clauses with optional text customization fields.
   - From: `dealWizardWebUi`
   - To: `Sales Representative`
   - Protocol: HTTPS (browser)

5. **Submit Fine Prints Selection**: Sales representative submits selected fine print clauses with any customizations.
   - From: `Sales Representative`
   - To: `dealWizardWebUi`
   - Protocol: HTTPS / `PUT /deals/:id/fine_prints`

6. **Validate Selections**: Web UI validates that required fine print categories are covered for the deal's locale and deal type.
   - From: `dealWizardWebUi`
   - To: `dealWizardWebUi` (in-process validation)
   - Protocol: Direct

7. **Persist Fine Print Selections**: Validated fine print associations are written to MySQL.
   - From: `dealWizardWebUi`
   - To: MySQL (`dealWizardMysql`)
   - Protocol: Direct (ActiveRecord)

8. **Advance Wizard**: Web UI redirects the sales rep to the next wizard step (Payments).
   - From: `dealWizardWebUi`
   - To: `Sales Representative`
   - Protocol: HTTPS (browser redirect)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis unavailable | Locale flag defaults used; full fine print catalog may be shown | Sales rep may see fine prints beyond their locale; risk of incorrect selection |
| No fine prints found for locale | Empty state with warning message rendered | Sales rep notified; must contact admin to add fine prints for locale |
| Required fine print category not selected | Form re-rendered with validation error | Sales rep must select all required categories before advancing |
| MySQL write failure | Rails exception; error page rendered | Fine print selections not saved; sales rep must retry |

## Sequence Diagram

```
Sales Rep -> dealWizardWebUi: GET /deals/:id/fine_prints
dealWizardWebUi -> redisCache: Read locale flags
redisCache --> dealWizardWebUi: Locale configuration
dealWizardWebUi -> MySQL: SELECT fine_prints WHERE locale_id = ?
MySQL --> dealWizardWebUi: Fine print records
dealWizardWebUi --> Sales Rep: Render fine prints selection form
Sales Rep -> dealWizardWebUi: PUT /deals/:id/fine_prints (submit selections)
dealWizardWebUi -> MySQL: INSERT deal_fine_prints (associations)
MySQL --> dealWizardWebUi: Success
dealWizardWebUi --> Sales Rep: Redirect to /deals/:id/payments
```

## Related

- Architecture dynamic view: `dynamic-merchantFinePrintConfiguration`
- Related flows: [Deal Creation Wizard](deal-wizard-creation.md), [Deal Option & Pricing Configuration](deal-option-pricing-configuration.md), [Deal Approval & Submission](deal-approval-and-submission.md)
