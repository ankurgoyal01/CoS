---
service: "getaways-partner-integrator"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, helm-values, jtier-platform]
---

# Configuration

## Overview

Getaways Partner Integrator is configured via JTier platform conventions (environment variables injected by Kubernetes/Helm at deploy time). Configuration varies by per-partner deployment variant: separate deployments exist for `aps`, `siteminder`, and `travelgatex`. Secrets (database credentials, WS-Security credentials, MBus connection details) are managed externally and injected at runtime.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_ENV` | Identifies the runtime environment (dev, staging, prod) | yes | none | env / helm |
| `DB_URL` | JDBC URL for `continuumGetawaysPartnerIntegratorDb` MySQL instance | yes | none | env / vault |
| `DB_USERNAME` | MySQL username for the service database | yes | none | vault |
| `DB_PASSWORD` | MySQL password for the service database | yes | none | vault |
| `KAFKA_BOOTSTRAP_SERVERS` | Kafka broker addresses for the partner inbound consumer | yes | none | env / helm |
| `KAFKA_GROUP_ID` | Consumer group ID for the Kafka partner inbound consumer | yes | none | env / helm |
| `MBUS_BROKER_URL` | JMS broker URL for Groupon MBus connectivity | yes | none | env / vault |
| `MBUS_USERNAME` | MBus authentication username | yes | none | vault |
| `MBUS_PASSWORD` | MBus authentication password | yes | none | vault |
| `WS_SECURITY_USERNAME` | WS-Security username used for outbound SOAP authentication | yes | none | vault |
| `WS_SECURITY_PASSWORD` | WS-Security password/credential for outbound SOAP calls | yes | none | vault |
| `INVENTORY_SERVICE_BASE_URL` | Base URL for the Getaways Inventory Service REST API | yes | none | env / helm |
| `PARTNER_VARIANT` | Identifies the active channel manager partner (aps, siteminder, travelgatex) | yes | none | env / helm |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found of runtime feature flags in the architecture inventory. Contact the Travel team for any dynamic flag configuration.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| Dropwizard YAML config | YAML | Service port, logging, database pool, health check configuration — managed by JTier base image conventions |
| Helm values (per variant) | YAML | Per-partner deployment configuration for aps, siteminder, travelgatex variants |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DB_PASSWORD` | MySQL database password for `continuumGetawaysPartnerIntegratorDb` | vault / k8s-secret |
| `MBUS_PASSWORD` | Groupon MBus authentication credential | vault / k8s-secret |
| `WS_SECURITY_PASSWORD` | WS-Security credential for outbound SOAP calls to channel managers | vault / k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies are referenced here.

## Per-Environment Overrides

The service is deployed in three per-partner variants (`aps`, `siteminder`, `travelgatex`), each with its own Kubernetes deployment. Helm values provide per-variant overrides for:

- Active SOAP endpoint configuration (which partner WSDL and endpoint URL to use)
- Partner-specific WS-Security credentials
- Kafka consumer topic names (partner-specific inbound topics)
- MBus queue/topic names

Environment differences (dev, staging, production) are handled via JTier's standard `JTIER_ENV` convention, which controls database, broker, and external service URLs.
