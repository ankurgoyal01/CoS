---
service: "AIGO-CheckoutBot"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars]
---

# Configuration

## Overview

AIGO-CheckoutBot is configured primarily through environment variables injected at runtime. No config file management system (Consul, Vault, Helm values) is directly evidenced in the DSL inventory; secrets are expected to be supplied as environment variables. The service connects to PostgreSQL and Redis using connection strings provided via environment variables. LLM provider API keys and external integration credentials are also supplied this way.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | PostgreSQL connection string for `continuumAigoPostgresDb` (ng_design/ng_engine/ng_analytics/ng_simulation schemas) | yes | None | env |
| `REDIS_URL` | Redis connection string for `continuumAigoRedisCache` | yes | None | env |
| `OPENAI_API_KEY` | API key for OpenAI GPT integration | yes (if using OpenAI) | None | env |
| `GOOGLE_GENAI_API_KEY` | API key for Google Gemini integration | yes (if using Gemini) | None | env |
| `SALESFORCE_BASE_URL` | Base URL for the Salesforce REST API | yes (if escalation enabled) | None | env |
| `SALESFORCE_CLIENT_ID` | Salesforce OAuth2 client ID | yes (if escalation enabled) | None | env |
| `SALESFORCE_CLIENT_SECRET` | Salesforce OAuth2 client secret | yes (if escalation enabled) | None | env |
| `ASANA_API_TOKEN` | Asana personal access token or OAuth2 token | yes (if Asana enabled) | None | env |
| `ASANA_PROJECT_ID` | Target Asana project for operational tasks | yes (if Asana enabled) | None | env |
| `SALTED_API_KEY` | API key for Salted engagement platform | yes (if Salted enabled) | None | env |
| `SALTED_BASE_URL` | Base URL for the Salted platform API | yes (if Salted enabled) | None | env |
| `JWT_SECRET` | Secret used by `jsonwebtoken` to sign and verify API JWTs | yes | None | env |
| `PORT` | HTTP port the Express server listens on | no | 3000 | env |
| `NODE_ENV` | Runtime environment identifier (`development`, `staging`, `production`) | yes | None | env |
| `LOG_LEVEL` | Winston logging level (`debug`, `info`, `warn`, `error`) | no | `info` | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found of a feature flag system in the inventory. Per-project LLM provider selection (OpenAI vs. Google Gemini) is managed through project configuration stored in `ng_design` schema, not a runtime flag system.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `package.json` | JSON | Dependency manifest and npm scripts for build, migration, and start |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `OPENAI_API_KEY` | OpenAI GPT API authentication | env (rotation policy to be defined by service owner) |
| `GOOGLE_GENAI_API_KEY` | Google Gemini API authentication | env |
| `SALESFORCE_CLIENT_SECRET` | Salesforce OAuth2 client secret | env |
| `ASANA_API_TOKEN` | Asana API authentication token | env |
| `SALTED_API_KEY` | Salted platform API key | env |
| `JWT_SECRET` | JWT signing secret for backend API authentication | env |

> Secret values are NEVER documented. Only names and rotation policies are noted. Rotation policies are to be defined by the service owner.

## Per-Environment Overrides

Environment-specific configuration is supplied through separate environment variable sets per deployment environment (development, staging, production). The `NODE_ENV` variable controls environment-aware behavior within the application. Specific override values and deployment environment configurations are managed externally to this repository.
