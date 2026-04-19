---
service: "merchant-center-web"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 7
---

# Flows

Process and flow documentation for Merchant Center Web.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Merchant Login](merchant-login.md) | synchronous | User navigates to `/login` | SSO-based merchant authentication via Doorman |
| [Merchant Onboarding](merchant-onboarding.md) | synchronous | User enters `/onboarding/*` wizard | Multi-step onboarding flow for new merchants |
| [Deal Creation](deal-creation.md) | synchronous | Merchant submits deal creation form | Creates a new deal/campaign via UMAPI |
| [Voucher Redemption](voucher-redemption.md) | synchronous | Merchant redeems a customer voucher | Records voucher redemption via UMAPI |
| [Report Generation](report-generation.md) | synchronous | Merchant requests a performance report | Fetches analytics data from AIDG and renders charts |
| [2FA Enrollment](2fa-enrollment.md) | synchronous | Merchant opts in to two-factor authentication | Enrolls 2FA device/method via UMAPI |
| [Performance Monitoring](performance-monitoring.md) | synchronous | Merchant views performance dashboard | Loads and renders campaign analytics from AIDG |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 7 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All flows in this service are cross-service by nature — the SPA orchestrates calls to UMAPI and AIDG for every user-initiated action. The central Continuum architecture model tracks the dynamic view relationships between `merchantCenterWebSPA`, `continuumUmapi`, and `continuumAidg`.
