---
service: "deal_wizard"
title: "Deal Option & Pricing Configuration"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-option-pricing-configuration"
flow_type: synchronous
trigger: "Sales representative reaches the Options step in the deal creation wizard"
participants:
  - "dealWizardWebUi"
  - "dealManagementClient"
  - "dealBookClient"
  - "redisCache"
  - "continuumDealManagementApi"
architecture_ref: "dynamic-dealOptionPricingConfiguration"
---

# Deal Option & Pricing Configuration

## Summary

This flow handles the configuration of deal options — including pricing tiers, discount percentages, voucher face values, and quantity limits — within the deal creation wizard. The Web UI loads existing inventory product definitions from the Deal Management API and Deal Book pricing structures, presents the options form to the sales representative, and persists validated option data to MySQL. Multiple options (pricing tiers) can be configured for a single deal.

## Trigger

- **Type**: user-action
- **Source**: Sales representative navigates to the Options step of the deal wizard (via `GET /deals/:id/options`)
- **Frequency**: On-demand; during each deal wizard session (may be revisited for edits)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Sales Representative (User) | Enters pricing tiers, discount values, and quantity limits | — |
| Deal Wizard Web UI | Renders options form; validates and persists configuration | `dealWizardWebUi` |
| Deal Management Client | Fetches inventory product definitions for this deal | `dealManagementClient` |
| Deal Book Client | Loads Deal Book pricing structures for calculator inputs | `dealBookClient` |
| Redis Cache | Reads locale flags to determine available currency and pricing rules | `redisCache` |
| Deal Management API | Returns inventory product data for the deal UUID | `continuumDealManagementApi` |

## Steps

1. **Receive Options Request**: Web UI receives `GET /deals/:id/options` from the sales rep's browser.
   - From: `Sales Representative`
   - To: `dealWizardWebUi`
   - Protocol: HTTPS (browser)

2. **Read Locale Flags**: Web UI reads locale feature flags from Redis to determine applicable currency rules and pricing constraints.
   - From: `dealWizardWebUi`
   - To: `redisCache`
   - Protocol: Direct (in-process Redis)

3. **Fetch Inventory Products**: Deal Management Client calls Deal Management API to retrieve current inventory product definitions linked to this deal UUID.
   - From: `dealWizardWebUi` via `dealManagementClient`
   - To: `continuumDealManagementApi`
   - Protocol: REST

4. **Load Deal Book Structures**: Deal Book Client fetches pricing calculator structures applicable to this deal type and locale.
   - From: `dealWizardWebUi` via `dealBookClient`
   - To: Deal Book Service (stub — not currently active)
   - Protocol: REST (stub)

5. **Render Options Form**: Web UI renders the options configuration form pre-populated with inventory products and Deal Book pricing defaults.
   - From: `dealWizardWebUi`
   - To: `Sales Representative`
   - Protocol: HTTPS (browser)

6. **Submit Options**: Sales representative submits the completed options form with pricing tiers and quantity limits.
   - From: `Sales Representative`
   - To: `dealWizardWebUi`
   - Protocol: HTTPS / `PUT /deals/:id/options`

7. **Validate Options**: Web UI validates the submitted option data (price ranges, discount percentages, quantity limits) against locale and deal type rules.
   - From: `dealWizardWebUi`
   - To: `dealWizardWebUi` (in-process validation)
   - Protocol: Direct

8. **Persist Options**: Validated option data is written to MySQL.
   - From: `dealWizardWebUi`
   - To: MySQL (`dealWizardMysql`)
   - Protocol: Direct (ActiveRecord)

9. **Advance Wizard**: Web UI redirects the sales rep to the next wizard step (Fine Prints).
   - From: `dealWizardWebUi`
   - To: `Sales Representative`
   - Protocol: HTTPS (browser redirect)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal Management API unavailable | HTTP error displayed in options step | Sales rep sees error; must retry loading the step |
| Deal Book Service unavailable | Pricing calculator uses defaults (stub) | Pricing structures may be incomplete; sales rep proceeds with reduced guidance |
| Validation failure (invalid pricing) | Form re-rendered with field-level error messages | Sales rep must correct invalid values before advancing |
| MySQL write failure | Rails exception; error page rendered | Options not saved; sales rep must retry submission |

## Sequence Diagram

```
Sales Rep -> dealWizardWebUi: GET /deals/:id/options
dealWizardWebUi -> redisCache: Read locale flags
dealWizardWebUi -> dealManagementClient: Fetch inventory products
dealManagementClient -> continuumDealManagementApi: GET /deals/:uuid/products
continuumDealManagementApi --> dealManagementClient: Inventory product list
dealManagementClient --> dealWizardWebUi: Inventory products
dealWizardWebUi --> Sales Rep: Render options form
Sales Rep -> dealWizardWebUi: PUT /deals/:id/options (submit pricing config)
dealWizardWebUi -> MySQL: Persist deal options
dealWizardWebUi --> Sales Rep: Redirect to /deals/:id/fine_prints
```

## Related

- Architecture dynamic view: `dynamic-dealOptionPricingConfiguration`
- Related flows: [Deal Creation Wizard](deal-wizard-creation.md), [Deal Inventory Allocation](deal-inventory-allocation.md), [Merchant Fine Print Configuration](merchant-fine-print-configuration.md)
