---
service: "selfsetup-hbw"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumSsuWebApp, continuumSsuDatabase]
---

# Architecture Context

## System Context

selfsetup-hbw is a component of the **Continuum** platform, operating within the EMEA merchant onboarding subdomain. Merchants arrive via a Salesforce-generated invitation URL and interact exclusively through the browser-based setup wizard. The service has no inbound API consumers beyond the merchant browser session. All outbound integrations are synchronous REST: Salesforce provides and receives the authoritative merchant record, and the BookingTool API is the live booking engine that receives the final availability and capacity configuration. Metrics flow to Telegraf (InfluxDB) and logs to a Splunk log aggregation pipeline.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Self Setup HBW Web | `continuumSsuWebApp` | WebApp | PHP, Zend Framework, Apache | 5.6 / 1.11.6 / 2.4 | PHP/Zend MVC application serving the merchant self-setup wizard; hosts all HTTP endpoints and cron entry points |
| SSU HBW Database | `continuumSsuDatabase` | Database | MySQL | — | Stores in-progress and completed self-setup configuration, job queue for reminders and reconciliation |

## Components by Container

### Self Setup HBW Web (`continuumSsuWebApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `ssuWebUi` | Zend MVC controllers and views — handles all inbound HTTP requests, renders setup wizard pages, dispatches to downstream clients | PHP / Zend_Controller |
| `selfsetupHbw_ssuSalesforceClient` | OAuth 2.0 authentication against Salesforce; executes SOQL queries to fetch opportunity/account data; POSTs finalised configuration back to Salesforce | PHP / curl |
| `selfsetupHbw_ssuBookingToolClient` | Calls BookingTool REST API endpoints (per-country, BasicAuth) to push availability schedules and capacity caps | PHP / curl |
| `ssuMetricsReporter` | Writes HTTP request metrics and business-level metrics to Telegraf agent via InfluxDB line protocol | PHP / influxdb-php |
| `ssuLogger` | Emits structured, Splunk-formatted log records for centralised ingestion | PHP / monolog + monolog-splunk-formatter |
| `ssuPersistence` | Zend_Db-based data access layer for all reads and writes to `continuumSsuDatabase` | PHP / Zend_Db |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `ssuWebUi` | `selfsetupHbw_ssuSalesforceClient` | Requests Salesforce opportunity/account data | Direct (in-process) |
| `ssuWebUi` | `selfsetupHbw_ssuBookingToolClient` | Requests BookingTool availability/capacity operations | Direct (in-process) |
| `ssuWebUi` | `ssuPersistence` | Reads and writes self-setup state | Direct (in-process) |
| `selfsetupHbw_ssuSalesforceClient` | `salesForce` | OAuth token exchange + SOQL queries + configuration updates | REST / HTTPS |
| `selfsetupHbw_ssuBookingToolClient` | `bookingToolApi` | Per-country availability and capacity API calls | REST / HTTPS / BasicAuth |
| `ssuPersistence` | `continuumSsuDatabase` | MySQL reads and writes | TCP / MySQL protocol |
| `ssuMetricsReporter` | `telegrafAgent` | InfluxDB line protocol metrics emission | UDP/TCP |
| `ssuLogger` | `logAggregation` | Splunk-formatted log records | TCP / Splunk HEC |

## Architecture Diagram References

- System context: `contexts-selfsetup-hbw`
- Container: `containers-selfsetup-hbw`
- Component: `components-ssuWebApp`
