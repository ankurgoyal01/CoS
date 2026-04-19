---
service: "deal-alerts"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 1
---

# Integrations

## Overview

Deal Alerts integrates with 4 external systems (Salesforce, Twilio, BigQuery, Google OAuth) and 1 internal Groupon service (Marketing Deal Service). All integrations are orchestrated through the n8n workflow layer except Google OAuth which is handled directly by the web app's BetterAuth configuration.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | HTTPS/REST | Resolves merchant contacts and creates tasks for alert actions | yes | `salesForce` |
| Twilio | HTTPS | Sends SMS notifications and receives delivery/reply webhooks | yes | `twilio` |
| BigQuery | BigQuery API | Imports external alert signals (daily) | no | `bigQuery` |
| Google OAuth | HTTPS/OAuth2 | SSO authentication for web app users (Groupon domain only) | yes | N/A |

### Salesforce Detail

- **Protocol**: HTTPS/REST
- **Base URL / SDK**: Salesforce REST API accessed via n8n Salesforce node
- **Auth**: OAuth2 (credentials managed in n8n)
- **Purpose**: Resolves merchant contacts (Get Contacts Resolver workflow), creates Salesforce tasks for alert actions (Execute Alert Actions workflow), and tracks task status for attribution
- **Failure mode**: Alert actions that require Salesforce tasks will fail and be recorded with error messages in the `actions` table with retry tracking
- **Circuit breaker**: No explicit circuit breaker; n8n workflow error handling with retry_count tracking

### Twilio Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: Twilio Messaging API accessed via n8n Twilio node
- **Auth**: Account SID + Auth Token (credentials managed in n8n)
- **Purpose**: Sends SMS notifications to merchants for SoldOut alerts, receives delivery status callbacks and inbound reply webhooks. Handles opt-out (STOP/START) commands.
- **Failure mode**: Failed SMS delivery is tracked in `notification_status_history` with Twilio error codes (e.g., 21610 for unsubscribed). Unsubscribed recipients are filtered from future sends.
- **Circuit breaker**: No explicit circuit breaker; status tracked per notification

### BigQuery Detail

- **Protocol**: BigQuery API
- **Base URL / SDK**: Google BigQuery API accessed via n8n BigQuery node
- **Auth**: Service account credentials (managed in n8n)
- **Purpose**: Daily import of external alert signals that supplement the internal snapshot-derived alerts
- **Failure mode**: External alert import is non-critical; internal alerts continue to function independently
- **Circuit breaker**: No

### Google OAuth Detail

- **Protocol**: HTTPS/OAuth2
- **Base URL / SDK**: Google OAuth2 API via BetterAuth social provider
- **Auth**: Client ID + Client Secret via `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` environment variables
- **Purpose**: Single sign-on for the web application restricted to `@groupon.com` email domain
- **Failure mode**: Users cannot authenticate; web app remains accessible for public (read-only) endpoints
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Marketing Deal Service (MDS) | HTTP | Source of deal data for snapshot ingestion. n8n workflow pages the MDS API to fetch all active deals. | `continuumMarketingDealService` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. The web app is consumed by internal operations teams and merchant success managers through their browsers.

## Dependency Health

- **Database**: Health check endpoint (`/rpc/health.check`) verifies PostgreSQL connectivity with a `SELECT 1` probe. Returns `healthy`/`unhealthy` with `connected`/`disconnected` database status.
- **Liveness**: Lightweight liveness probe at `/rpc/health.live` returns "OK" without dependency checks.
- **External services**: No explicit health checks or circuit breakers for Salesforce, Twilio, or BigQuery. Failures are tracked per-action/per-notification with error messages and retry counts in the database. The Logs API aggregates errors across all action sources for operational visibility.
