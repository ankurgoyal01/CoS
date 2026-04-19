---
service: "merchant-prep-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [client-id]
---

# API Surface

## Overview

The Merchant Preparation Service exposes a REST API consumed by the Merchant Center front-end (via UMAPI) and by internal Continuum services. All endpoints follow a resource-oriented design rooted at `/merchant-self-prep/` with versioned sub-paths (`v1`, `v2`, `v3`). Additional administrative endpoints exist under `/msse-api/` and root-level paths (`/v0/validations/`, `/v1/beta_subscription`, `/v1/navigation/`). Authentication is enforced via client-id role mapping using the JTier auth bundle. The OpenAPI specification is at `doc/swagger/swagger.yaml`.

## Endpoints

### Account Information

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchant-self-prep/v1/accounts/{salesforceId}` | Retrieve account data by Salesforce ID | client-id |
| GET | `/merchant-self-prep/v1/accounts/{salesforceId}/contacts` | List all contacts for an account | client-id |
| POST | `/merchant-self-prep/v1/accounts/{salesforceId}/contacts` | Create a new account contact | client-id |
| GET | `/merchant-self-prep/v1/accounts/{salesforceId}/businessOwners` | Retrieve business owners for an account | client-id |
| PUT | `/merchant-self-prep/v1/accounts/{salesforceId}/businessOwners/{contactId}` | Update a business owner (primary contact) | client-id |
| GET | `/merchant-self-prep/v1/accounts/{salesforceId}/supportInfo` | Retrieve account support information | client-id |
| GET | `/merchant-self-prep/v1/accounts/{salesforceId}/featureFlags` | Get feature flags for an account | client-id |
| GET | `/merchant-self-prep/v1/accounts/{salesforceId}/optedOutOfPromotionsFeatureFlag` | Check promotions opt-out flag | client-id |
| PUT | `/merchant-self-prep/v1/accounts/{salesforceId}/lastLoginInfo` | Record merchant last-login timestamp | client-id |
| GET | `/merchant-self-prep/v1/accounts/{salesforceId}/lockBankingFields` | Check if banking fields are locked | client-id |

### Billing Address

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchant-self-prep/v1/accounts/{salesforceId}/billingAddress` | Retrieve billing address | client-id |
| PUT | `/merchant-self-prep/v1/accounts/{salesforceId}/billingAddress` | Update billing address | client-id |

### Business Information

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| PUT | `/merchant-self-prep/v1/accounts/{salesforceId}/businessInfo` | Update business information | client-id |
| GET | `/merchant-self-prep/v1/accounts/{salesforceId}/companyType` | Retrieve company type | client-id |
| PUT | `/merchant-self-prep/v1/accounts/{salesforceId}/companyType` | Update company type | client-id |
| PUT | `/merchant-self-prep/v1/accounts/{salesforceId}/deiInfo` | Update DEI (Diversity, Equity, Inclusion) information | client-id |
| PUT | `/merchant-self-prep/v1/accounts/{salesforceId}/merchantGoals` | Update merchant goals | client-id |

### Tax Information

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchant-self-prep/v1/accounts/{salesforceId}/taxInfo` | Retrieve tax information | client-id |
| PUT | `/merchant-self-prep/v1/accounts/{salesforceId}/taxInfo` | Update tax information (v1) | client-id |
| PUT | `/merchant-self-prep/v2/accounts/{salesforceId}/taxInfo` | Update tax information (v2) | client-id |

### Payment Information

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchant-self-prep/v1/accounts/{salesforceId}/paymentInfo` | Retrieve payment/banking information | client-id |
| PUT | `/merchant-self-prep/v1/accounts/{salesforceId}/paymentInfo` | Update payment information (v1) | client-id |
| PUT | `/merchant-self-prep/v2/accounts/{salesforceId}/paymentInfo` | Update payment information (v2) | client-id |
| GET | `/merchant-self-prep/v2/accounts/{salesforceId}/paymentInfoVerification` | Get payment MO verification status | client-id |
| PUT | `/merchant-self-prep/v2/accounts/{salesforceId}/paymentInfoVerification` | Submit payment info for verification (v3 handler) | client-id |
| DELETE | `/merchant-self-prep/v2/accounts/{salesforceId}/paymentInfoVerification` | Delete pending payment verification | client-id |
| GET | `/merchant-self-prep/v1/accounts/{salesforceId}/getPaymentHoldInfo` | Retrieve payment hold status and reason codes | client-id |
| GET | `/merchant-self-prep/v1/accounts/{salesforceId}/rrdpFields` | Retrieve RRDP fields | client-id |
| PUT | `/merchant-self-prep/v1/accounts/{salesforceId}/rrdpFields` | Update RRDP fields | client-id |
| POST | `/merchant-self-prep/v3/payment/{caseId}/paymentInfo` | Retrieve payment info by case ID (v3) | client-id |
| GET | `/merchant-self-prep/v3/payment/{caseId}/paymentStatus` | Get payment case status | client-id |
| GET | `/merchant-self-prep/v3/payment/{caseId}/rejectedPaymentInfo` | Get rejected payment details for a case | client-id |

### Self-Prep State and Steps

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchant-self-prep/v1/accounts/{salesforceId}/selfPrepState` | Retrieve account-level self-prep state | client-id |
| PUT | `/merchant-self-prep/v1/accounts/{salesforceId}/selfPrepState` | Update account-level self-prep state | client-id |
| PUT | `/merchant-self-prep/v1/accounts/{salesforceId}/lastStepCompleted` | Record last completed prep step | client-id |
| GET | `/merchant-self-prep/v1/accounts/{salesforceId}/opportunities` | List opportunities for an account | client-id |
| GET | `/merchant-self-prep/v1/accounts/{salesforceId}/opportunities/{opportunityId}` | Retrieve a single opportunity | client-id |
| GET | `/merchant-self-prep/v1/accounts/{salesforceId}/opportunities/{opportunityId}/selfPrepState` | Get self-prep step state for an opportunity | client-id |
| PUT | `/merchant-self-prep/v1/accounts/{salesforceId}/opportunities/{opportunityId}/selfPrepState` | Update self-prep step state for an opportunity | client-id |
| PUT | `/merchant-self-prep/v1/accounts/{salesforceId}/opportunities/{opportunityId}/selfPrepProgress` | Record progress through self-prep steps | client-id |
| PUT | `/merchant-self-prep/v1/accounts/{salesforceId}/opportunities/{opportunityId}/selfPrepComplete` | Mark self-prep as complete for an opportunity | client-id |

### Tasks

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchant-self-prep/v1/accounts/{salesforceId}/tasks` | List Salesforce tasks for an account | client-id |
| POST | `/merchant-self-prep/v1/accounts/{salesforceId}/tasks` | Create a Salesforce task for an account | client-id |
| GET | `/merchant-self-prep/v1/accounts/{salesforceId}/opportunities/{opportunityId}/tasks` | List tasks for an opportunity | client-id |
| POST | `/merchant-self-prep/v1/accounts/{salesforceId}/opportunities/{opportunityId}/tasks` | Create a task for an opportunity | client-id |

### Onboarding Checklists

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/merchant-self-prep/v1/accounts/{salesforceId}/merchantChecklistOnboarding` | Retrieve onboarding checklist status | client-id |
| POST | `/merchant-self-prep/v1/accounts/{salesforceId}/merchantChecklistOnboarding/{checklistId}` | Update a checklist item (skip or complete) | client-id |
| GET | `/merchant-self-prep/v1/accounts/{salesforceId}/merchantChecklistOnboardingStatus` | Get overall onboarding completion status | client-id |
| POST | `/merchant-self-prep/v1/accounts/{salesforceId}/merchantCampaignOnboarding` | Get campaign onboarding status | client-id |
| POST | `/merchant-self-prep/v1/accounts/{salesforceId}/merchantCampaignOnboarding/{checklistId}` | Dismiss a campaign onboarding pop-up item | client-id |

### Validation and Documents

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/merchant-self-prep/v1/accounts/{salesforceId}/validation` | Submit a validation request | client-id |
| GET | `/merchant-self-prep/v1/accounts/{salesforceId}/validation/{verificationId}` | Retrieve validation request status | client-id |
| POST | `/merchant-self-prep/v1/accounts/{salesforceId}/uploadDocument` | Upload a merchant document | client-id |
| POST | `/merchant-self-prep/v1/verification/code/generate` | Generate a verification code | client-id |
| POST | `/merchant-self-prep/v1/verification/code/validate` | Validate a submitted verification code | client-id |
| GET | `/v0/validations/tin_validation` | Legacy TIN validation lookup | client-id |

### Contracts

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchant-self-prep/v1/accounts/{opportunityId}/contract` | Retrieve contract for an opportunity | client-id |
| GET | `/msse-api/v0/contracts/{contract_id}.html` | Render contract as HTML | client-id |
| GET | `/msse-api/v0/contracts/{contract_id}.pdf` | Download contract as PDF | client-id |

### Navigation Templates

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/navigation/template` | Retrieve navigation template (device/OS/region-aware) | client-id |
| POST | `/v1/navigation/template` | Create a navigation template | client-id |
| GET | `/v1/navigation/template/{id}` | Retrieve a navigation template by ID | client-id |
| GET | `/v1/navigation/templates` | List navigation templates | client-id |
| GET | `/v1/navigation/script.sql` | Export navigation template SQL script | client-id |

### Beta Subscriptions

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/beta_subscription` | Check beta program subscription status for a merchant | client-id |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` for all JSON bodies.
- Authentication headers enforced by the UMAPI proxy upstream; internally, client-id tokens are validated per the JTier auth bundle.

### Error format

> No standardized error response schema is documented in the OpenAPI spec. Responses carry default HTTP status codes.

### Pagination

> No evidence found in codebase. Endpoints return full result sets.

## Rate Limits

> No rate limiting configured.

## Versioning

URL path versioning is used. Three API generations are present:
- `v1` — original self-prep and onboarding endpoints.
- `v2` — updated payment and tax info endpoints with extended models.
- `v3` — payment case-centric endpoints for change-payment workflows.

## OpenAPI / Schema References

- OpenAPI 2.0 (Swagger) spec: `doc/swagger/swagger.yaml`
- Server-side stubs generated from: `src/main/resources/swagger/open-api.yaml`
- Client stubs generated from specs in: `src/main/resources/swagger/client/` (force.yaml, m3Merchant.yaml, nots.yaml, mlsRin.yaml, accounting.yaml, readingRainbow.yaml, adobeClient.yaml, fonoa.yaml)
