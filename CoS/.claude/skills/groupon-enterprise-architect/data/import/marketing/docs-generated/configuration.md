---
service: "marketing"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: []
---

# Configuration

## Overview

> No evidence found in codebase. Configuration sources, patterns, and mechanisms are not discoverable from the architecture DSL model. The following sections are placeholders for service owners to populate.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` (inferred) | MySQL connection string for Marketing Platform DB | yes | - | env / vault |
| `KAFKA_BROKERS` (inferred) | Kafka broker addresses for event logging | yes | - | env |
| `MBUS_CONNECTION` (inferred) | Message Bus connection configuration | yes | - | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed. Actual variable names are inferred from typical Continuum service patterns.

## Feature Flags

> No evidence found in codebase.

## Config Files

> No evidence found in codebase.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Database credentials (inferred) | MySQL authentication for Marketing Platform DB | vault (inferred) |
| Kafka credentials (inferred) | Authentication for Kafka event logging | vault (inferred) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

> No evidence found in codebase. Environment-specific configuration differences are not discoverable from the architecture model.
