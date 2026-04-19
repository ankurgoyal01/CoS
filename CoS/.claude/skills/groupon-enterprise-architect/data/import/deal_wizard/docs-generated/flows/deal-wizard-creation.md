---
service: "deal_wizard"
title: "Deal Creation Wizard"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-wizard-creation"
flow_type: synchronous
trigger: "Sales representative initiates deal creation from a Salesforce Opportunity"
participants:
  - "dealWizardWebUi"
  - "salesforceClient"
  - "dealManagementClient"
  - "dealGuideClient"
  - "redisCache"
  - "salesForce"
  - "continuumDealManagementApi"
architecture_ref: "dynamic-dealWizardCreation"
---

# Deal Creation Wizard

## Summary

The Deal Creation Wizard is the primary end-to-end flow that guides a sales representative from a Salesforce Opportunity through all wizard steps to produce a complete, structured deal record. The wizard loads Opportunity and Account data from Salesforce, presents step-by-step forms for deal configuration (options, fine prints, payments, merchants, distributions), and stores intermediate state until the deal is submitted for approval. It is the entry point for all other deal configuration flows.

## Trigger

- **Type**: user-action
- **Source**: Sales representative clicks "Create Deal" from a Salesforce Opportunity in their browser
- **Frequency**: On-demand; per new deal creation session

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Sales Representative (User) | Initiates wizard, completes each step | — |
| Deal Wizard Web UI | Renders wizard steps, orchestrates form state and navigation | `dealWizardWebUi` |
| Salesforce Client | Fetches Opportunity and Account data; writes deal on submission | `salesforceClient` |
| Deal Management Client | Resolves deal UUIDs for the new deal record | `dealManagementClient` |
| Deal Guide Client | Loads wizard question templates and step definitions | `dealGuideClient` |
| Redis Cache | Persists session state and locale feature flags across steps | `redisCache` |
| Salesforce | Source of Opportunity and Account CRM data | `salesForce` |
| Deal Management API | Issues deal UUIDs and validates deal structure | `continuumDealManagementApi` |

## Steps

1. **Authenticate User**: Sales rep accesses Deal Wizard; session is validated against Redis.
   - From: `Sales Representative`
   - To: `dealWizardWebUi`
   - Protocol: HTTPS (browser)

2. **Load Locale Flags**: Web UI reads locale feature flags from Redis to determine available regions and fine print options.
   - From: `dealWizardWebUi`
   - To: `redisCache`
   - Protocol: Direct (in-process Redis)

3. **Fetch Salesforce Opportunity**: Salesforce Client retrieves the target Opportunity and associated Account from Salesforce using the OAuth access token.
   - From: `dealWizardWebUi` via `salesforceClient`
   - To: `salesForce`
   - Protocol: REST / APEX API

4. **Load Wizard Templates**: Deal Guide Client fetches the wizard question templates and step structure applicable to this deal type.
   - From: `dealWizardWebUi` via `dealGuideClient`
   - To: Deal Guide Service (stub)
   - Protocol: REST (stub — not currently active)

5. **Request Deal UUID**: Deal Management Client requests a new deal UUID from the Deal Management API to anchor the wizard session.
   - From: `dealWizardWebUi` via `dealManagementClient`
   - To: `continuumDealManagementApi`
   - Protocol: REST

6. **Present Wizard Steps**: Web UI renders each sequential step (Options, Fine Prints, Payments, Merchants, Distributions), collecting form input and persisting intermediate state.
   - From: `dealWizardWebUi`
   - To: `Sales Representative`
   - Protocol: HTTPS (browser)

7. **Persist Step Data**: On each step submission, Web UI writes validated step data to MySQL via ActiveRecord.
   - From: `dealWizardWebUi`
   - To: MySQL (`dealWizardMysql`)
   - Protocol: Direct (ActiveRecord)

8. **Complete Wizard Session**: On final step completion, the deal record is marked ready for submission and the user is directed to the approval flow.
   - From: `dealWizardWebUi`
   - To: `Sales Representative`
   - Protocol: HTTPS (browser)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce OAuth session expired | Redirect to Salesforce OAuth re-authentication | User must re-authenticate; wizard state preserved in session if Redis is available |
| Salesforce Opportunity not found | Error rendered in wizard UI | Sales rep sees error message; must select a valid Opportunity |
| Deal Management API unavailable | HTTP error rendered in wizard step | Wizard creation step fails; sales rep must retry |
| Deal Guide Service unavailable | Step templates use fallback defaults (stub service) | Wizard may render with reduced template guidance |
| MySQL write failure | Rails ActiveRecord exception; error page rendered | Step data not saved; sales rep must retry the step |

## Sequence Diagram

```
Sales Rep -> dealWizardWebUi: GET /deals/new (browser)
dealWizardWebUi -> redisCache: Read session + locale flags
dealWizardWebUi -> salesforceClient: Fetch Opportunity + Account
salesforceClient -> salesForce: GET Opportunity (APEX REST)
salesForce --> salesforceClient: Opportunity + Account data
salesforceClient --> dealWizardWebUi: Opportunity data
dealWizardWebUi -> dealManagementClient: Request deal UUID
dealManagementClient -> continuumDealManagementApi: POST /deals
continuumDealManagementApi --> dealManagementClient: Deal UUID
dealManagementClient --> dealWizardWebUi: Deal UUID
dealWizardWebUi --> Sales Rep: Render wizard step 1 (Options)
Sales Rep -> dealWizardWebUi: POST /deals/:id/options (submit step)
dealWizardWebUi -> MySQL: Persist step data
dealWizardWebUi --> Sales Rep: Render next step
```

## Related

- Architecture dynamic view: `dynamic-dealWizardCreation`
- Related flows: [Deal Option & Pricing Configuration](deal-option-pricing-configuration.md), [Merchant Fine Print Configuration](merchant-fine-print-configuration.md), [Deal Approval & Submission](deal-approval-and-submission.md)
