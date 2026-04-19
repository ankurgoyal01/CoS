---
service: "fraud-arbiter"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-redis, helm-values]
---

# Configuration

## Overview

Fraud Arbiter is configured primarily through environment variables injected at runtime in the Kubernetes deployment. A Config Redis instance (`continuumFraudArbiterConfigRedis`) provides dynamic runtime configuration such as provider routing rules and feature flags. Secrets (API keys, HMAC secrets) are managed externally and injected as environment variables.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | MySQL connection string for fraud decisions DB | yes | none | helm / k8s-secret |
| `REDIS_CONFIG_URL` | Redis URL for Config Redis instance | yes | none | helm |
| `REDIS_CACHE_URL` | Redis URL for App Cache Redis instance | yes | none | helm |
| `REDIS_QUEUE_URL` | Redis URL for Job Queue Redis (Sidekiq) | yes | none | helm |
| `SIGNIFYD_API_KEY` | API key for authenticating with Signifyd | yes | none | vault / k8s-secret |
| `SIGNIFYD_WEBHOOK_SECRET` | HMAC secret for validating Signifyd webhook signatures | yes | none | vault / k8s-secret |
| `RISKIFIED_SHOP_DOMAIN` | Riskified shop domain identifier | yes | none | helm |
| `RISKIFIED_AUTH_TOKEN` | HMAC auth token for Riskified API calls and webhook validation | yes | none | vault / k8s-secret |
| `RAILS_ENV` | Rails environment (production, staging, development) | yes | development | env |
| `RAILS_MAX_THREADS` | Puma thread pool size | no | 5 | helm |
| `SIDEKIQ_CONCURRENCY` | Number of Sidekiq worker threads | no | 10 | helm |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `fraud_provider_routing` | Controls which fraud provider (signifyd/riskified) evaluates a given order | — | per-tenant / global |
| `fraud_review_bypass` | Allows specific order types to bypass fraud review | disabled | global |

> Feature flag details are managed in Config Redis and not fully discoverable from the inventory. Service owners should maintain a flag registry.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/database.yml` | yaml | Rails database connection configuration |
| `config/sidekiq.yml` | yaml | Sidekiq queue definitions and concurrency settings |
| `config/application.rb` | ruby | Rails application-level configuration |
| `config/environments/production.rb` | ruby | Production-specific Rails settings |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `SIGNIFYD_API_KEY` | Signifyd API authentication | vault / k8s-secret |
| `SIGNIFYD_WEBHOOK_SECRET` | Signifyd webhook HMAC signature validation | vault / k8s-secret |
| `RISKIFIED_AUTH_TOKEN` | Riskified API and webhook authentication | vault / k8s-secret |
| `DATABASE_URL` | MySQL credentials embedded in connection string | vault / k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Production uses live Signifyd and Riskified API endpoints with real fraud evaluation. Staging connects to provider sandbox environments. Development typically uses stubbed or mocked provider responses. Redis and MySQL connection URLs differ per environment and are supplied via Helm values or environment-specific k8s secrets.
