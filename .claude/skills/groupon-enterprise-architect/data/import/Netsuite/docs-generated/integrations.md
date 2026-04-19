---
service: "Netsuite"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 5
internal_count: 1
---

# Integrations

## Overview

All three NetSuite instances integrate with five external platforms. SnapLogic serves as the primary integration broker; all treasury, payment, and reconciliation integrations are orchestrated through SnapLogic pipelines triggered by NetSuite Suitelets or scheduled scripts. Direct inbound calls to NetSuite come from external systems (GLS, Coupa) via RESTlets. The Kyriba and JPMorgan Chase payment workflows use a NetSuite-to-SnapLogic-to-bank pattern. BlackLine and Anaplan receive data pushed from NetSuite via SnapLogic pipelines.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| SnapLogic | REST (HTTPS Bearer token) | Integration orchestration broker — all outbound data flows route through SnapLogic pipelines | yes | `snapLogic` |
| Coupa | REST / User Event | AP/procurement data synchronization — vendor bills enriched with Coupa header tax and shipping amounts | yes | `coupa` |
| Kyriba | REST via SnapLogic | Treasury payment file exchange — outbound NS-to-Kyriba and inbound Kyriba-to-NS cash position data | yes | `kyriba` |
| JPMorgan Chase Payments | REST via SnapLogic | ACH payment batch submission — NetSuite-staged payment files submitted to JPM bank | yes | `jpmPayments` |
| BlackLine | REST via SnapLogic | Reconciliation and accounting close — NS balance data pushed to BlackLine for close process | yes | `blackLine` |
| Anaplan | REST via SnapLogic | FX and planning data export — INTL instance publishes multi-currency planning data (INTL only) | no | `anaplan` |

### SnapLogic Detail

- **Protocol**: HTTPS REST POST
- **Base URL / SDK**: `https://elastic.snaplogic.com:443/api/1/rest/slsched/feed/GrouponProd/projects/...`
- **Auth**: Bearer token (per-pipeline token embedded in Suitelet script or script parameters)
- **Purpose**: Acts as the integration middleware layer. NetSuite Suitelets trigger SnapLogic pipelines by sending HTTP POST requests to scheduled-task feed URLs. SnapLogic then orchestrates file pickup, transformation, and delivery to Kyriba, JPM, BlackLine, or Anaplan.
- **Failure mode**: Suitelet displays a form response to the user; errors logged via `nlapiLogExecution`. No automated retry from Suitelets (single attempt). Scheduled scripts retry up to 5 times.
- **Circuit breaker**: No evidence found.

### Coupa Detail

- **Protocol**: NetSuite User Event (synchronous, on vendor bill save) and REST via SnapLogic
- **Base URL / SDK**: Accessed via NetSuite User Event script `HeaderTaxCoupaGoodsUserEvent.js`
- **Auth**: NetSuite platform authentication (User Event runs in NetSuite server context)
- **Purpose**: On vendor bill creation, header-level tax (`custbody_header_tax_coupa`) and shipping (`custbody_header_ship_coupa`) amounts sourced from Coupa are distributed proportionally across all expense lines. Broader AP/procurement document sync handled via SnapLogic.
- **Failure mode**: User Event throws `nlapiCreateError` — bill save is blocked and error displayed to user.
- **Circuit breaker**: No evidence found.

### Kyriba Detail

- **Protocol**: HTTPS REST via SnapLogic
- **Base URL / SDK**: SnapLogic pipelines `Kyriba outbound parent Trigger` and `Kyriba NS2 Inbound Kickoff`
- **Auth**: Bearer token (`Bearer KSdmXYy0NXvApjd1JJJLOdIn7WGd1QiG` for outbound; `Bearer mLZCTEfLvGdyPC1f38pTi8F8S7Eyw953` for inbound — stored in Suitelet script source)
- **Purpose**: Outbound trigger exports NetSuite cash transactions to Kyriba treasury platform. Inbound trigger imports Kyriba payment status and cash position data back into NetSuite.
- **Failure mode**: Suitelet reports `responseCode` from SnapLogic; errors logged. No automated retry.
- **Circuit breaker**: No evidence found.

### JPMorgan Chase Payments Detail

- **Protocol**: HTTPS REST via SnapLogic ACH pipeline
- **Base URL / SDK**: SnapLogic pipeline `GrouponProd/projects/Banking/JPM NS2 Send to ACH`
- **Auth**: Bearer token per pipeline (embedded in Suitelet script)
- **Purpose**: Finance staff select pending ACH payment files from NetSuite File Cabinet and submit them to JPMorgan Chase via SnapLogic for ACH processing. Covers Goods Marketplace (MP) and Goods Trade payment streams, in both US and global variants.
- **Failure mode**: Response code and body logged to NetSuite execution log. No automated retry from Suitelet.
- **Circuit breaker**: No evidence found.

### BlackLine Detail

- **Protocol**: REST via SnapLogic
- **Base URL / SDK**: SnapLogic pipeline `GrouponProd/projects/Reconciliation/NS2 Refresh Balance Trigger`
- **Auth**: Bearer token (`Bearer SfBOjASnEChdU5COpCUvJf2efEEZ4hwx` — stored in Suitelet script source)
- **Purpose**: Finance staff trigger a balance pull from NetSuite NS2 to feed BlackLine's reconciliation workspace for period-end close.
- **Failure mode**: Response code logged; no automated retry.
- **Circuit breaker**: No evidence found.

### Anaplan Detail

- **Protocol**: REST via SnapLogic (INTL instance only)
- **Base URL / SDK**: SnapLogic pipeline (pipeline name not in evidence; relationship confirmed in `models/relations.dsl`)
- **Auth**: Bearer token via SnapLogic
- **Purpose**: INTL NetSuite instance publishes FX rates and planning data exports to Anaplan for corporate financial planning and analysis.
- **Failure mode**: Failure mode managed by SnapLogic pipeline; not directly observable from NetSuite scripts.
- **Circuit breaker**: No evidence found.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| GLS (Groupon Logistics/Invoicing Service) | REST (HTTPS, JSON callback) | Receives vendor bill creation results; sends OTP purchase order data to GLS via scheduled script push | `continuumNetsuiteGoodsCustomizations` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| GLS invoicing service | REST POST to NetSuite RESTlet | Creates vendor bills and credits in NetSuite GOODS instance |
| SnapLogic pipelines | REST POST to NetSuite RESTlet / Suitelet | Delivers inbound data from Coupa, Kyriba, and other platforms into NetSuite |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

No formal health check or circuit breaker patterns are implemented in the SuiteScript layer. Dependency health is monitored via:
- NetSuite Execution Log (per-script DEBUG/ERROR entries via `nlapiLogExecution`)
- `customrecord_poes_auto_ctrl` control record — tracks last success timestamp and running-check flag for OTP scheduled scripts
- SnapLogic pipeline monitoring dashboards
- PagerDuty alert (`https://groupon.pagerduty.com/services/PV35CXK`) configured in `.service.yml`
- NetSuite status page (`https://status.netsuite.com/`) for platform-level health
