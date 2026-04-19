---
service: "Netsuite"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [netsuite-script-parameters, netsuite-custom-records]
---

# Configuration

## Overview

All NetSuite SuiteScript customizations are configured through NetSuite Script Deployment Parameters (`custscript_*`). These are set per-deployment in the NetSuite administration UI and read at runtime via `nlapiGetContext().getSetting('SCRIPT', 'custscript_...')`. There are no `.env` files, Helm charts, Vault secrets, or Kubernetes config maps. Credentials for outbound integrations (SnapLogic Bearer tokens) are currently embedded in Suitelet script source in some cases, which is a known security concern. The `customrecord_poes_auto_ctrl` custom record stores runtime state (last run timestamp, running flag) for scheduled scripts.

## Environment Variables

> Not applicable. NetSuite SuiteScript does not use OS-level environment variables. All configuration is via Script Deployment Parameters below.

## Script Deployment Parameters (equivalent to environment configuration)

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `custscript_vb_asynchronous` | Controls sync vs. async response mode for vendor bill RESTlet (`T` = async) | yes | `F` | NetSuite Script Deployment |
| `custscript_vb_min_usage` | Minimum remaining governance units before halting RESTlet batch processing | yes | none | NetSuite Script Deployment |
| `custscript_vb_expense_account` | Internal ID of default expense account for vendor bill lines | yes | none | NetSuite Script Deployment |
| `custscript_vb_payment_type_expense` | Payment type field value for expense-type vendor bills | yes | none | NetSuite Script Deployment |
| `custscript_vb_sales_channel` | Sales channel (class) to assign to vendor bill records | yes | none | NetSuite Script Deployment |
| `custscript_vb_ap_account` | Internal ID of AP account to set on vendor bill records | yes | none | NetSuite Script Deployment |
| `custscript_vb_appr_status` | Approval status to set on newly created vendor bills | yes | none | NetSuite Script Deployment |
| `custscript_vb_cost_center` | Department / cost center to assign to vendor bill expense lines | yes | none | NetSuite Script Deployment |
| `custscript_push_emea_save_folder` | NetSuite File Cabinet folder ID for EMEA OTP JSON export files | yes | none | NetSuite Script Deployment |
| `custscript_push_emea_nbr_to_send` | Number of purchase orders to include per JSON batch (EMEA OTP) | yes | none | NetSuite Script Deployment |
| `custscript_push_emea_max_kb_to_send` | Maximum file size in KB per JSON batch (EMEA OTP) | yes | none | NetSuite Script Deployment |
| `custscript_push_emea_running_reset` | Minutes threshold before resetting stuck running flag (EMEA OTP) | yes | none | NetSuite Script Deployment |
| `custscript_push_emea_testing` | Testing mode flag — bypasses actual API call when `T` | no | `F` | NetSuite Script Deployment |
| `custscript_push_gls_otp_save_folder` | File Cabinet folder ID for DS OTP JSON export files (GLS) | yes | none | NetSuite Script Deployment |
| `custscript_push_gls_otp_nbr_to_send` | Number of purchase orders per JSON batch (GLS OTP) | yes | none | NetSuite Script Deployment |
| `custscript_push_gls_otp_max_kb_to_send` | Maximum file size in KB per JSON batch (GLS OTP) | yes | none | NetSuite Script Deployment |
| `custscript_push_gls_otp_running_reset` | Minutes threshold before resetting stuck running flag (GLS OTP) | yes | none | NetSuite Script Deployment |
| `custscript_push_gls_otp_testing` | Testing mode flag for GLS OTP script | no | `F` | NetSuite Script Deployment |
| `custscript_vbn_subsidiary` | Comma-separated list of subsidiary internal IDs for vendor bill numbering | yes | none | NetSuite Script Deployment |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `custscript_vb_asynchronous` | Switches vendor bill RESTlet between synchronous (returns results inline) and asynchronous (fires callback to GLS) response modes | `F` (synchronous) | per-deployment |
| `custscript_push_emea_testing` | When `T`, bypasses the actual HTTP call to PO Manager EMEA and returns a hardcoded 200 response | `F` | per-deployment |
| `custscript_push_gls_otp_testing` | When `T`, bypasses the actual HTTP call to GLS and returns a hardcoded 200 response | `F` | per-deployment |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `GOODS/package.json` | JSON | Node.js dev dependencies for SuiteCloud unit testing (jest, @oracle/suitecloud-unit-testing) |
| `GOODS/jest.config.js` | JavaScript | Jest test runner configuration for SuiteScript unit tests |
| `.service.yml` | YAML | Service registry metadata: team, owner, SRE contacts, PagerDuty, Slack channel, documentation links |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| SnapLogic Bearer tokens (per-pipeline) | Authenticate NetSuite-to-SnapLogic pipeline trigger requests | Currently embedded in Suitelet JS source (e.g., JPM, Kyriba, Reconciliation suitelets) |
| GLS callback credentials (`getGLSCredentials()`) | Authenticate NetSuite callback to GLS invoicing service (`x-client-id`, `x-signature`) | NetSuite custom record or script parameter (credential lookup function in shared library) |
| PO Manager credentials (`getPOmgrCredentials()`) | Authenticate NetSuite push to PO Manager EMEA (`emea_clientid`, `emea_xsig`) | NetSuite custom record or script parameter |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

NetSuite supports Sandbox and Production environments. Scripts detect the current environment via `nlapiGetContext().getEnvironment()`. The OTP push scripts and vendor bill RESTlet use this to select environment-appropriate credential sets (via `getGLSCredentials(Environment)` and `getPOmgrCredentials(Environment)`). SnapLogic Suitelet URLs and Bearer tokens differ between production (`GrouponProd`) and sandbox (`GrouponDev`) SnapLogic organizations — the production URLs are currently active in deployed script source. Testing mode flags (`custscript_push_emea_testing`, `custscript_push_gls_otp_testing`) allow script execution in production without making actual outbound API calls.
