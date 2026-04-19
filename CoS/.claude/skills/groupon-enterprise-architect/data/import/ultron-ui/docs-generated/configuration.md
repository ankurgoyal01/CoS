---
service: "ultron-ui"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, helm-values]
---

# Configuration

## Overview

Ultron UI is configured primarily through environment variables injected at container startup. Kubernetes Helm values supply environment-specific overrides for staging and production. Play Framework application configuration is managed via `conf/application.conf`; runtime secrets (LDAP credentials, API URLs) are supplied as environment variables and never committed to source.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ULTRON_API_URL` | Base URL for the Ultron API backend (`continuumUltronApi`) | yes | None | env / helm |
| `LDAP_URL` | LDAP server URL for operator authentication | yes | None | env / helm |
| `LDAP_BIND_DN` | LDAP bind distinguished name for directory lookups | yes | None | env / k8s-secret |
| `LDAP_BIND_PASSWORD` | LDAP bind password | yes | None | env / k8s-secret |
| `APPLICATION_SECRET` | Play Framework CSRF/session signing secret | yes | None | env / k8s-secret |
| `JAVA_OPTS` | JVM startup flags (heap, GC tuning) | no | None | env / helm |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found for feature flags in this service.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `conf/application.conf` | HOCON | Play Framework runtime configuration — routes, filters, LDAP settings |
| `conf/routes` | Play routes DSL | HTTP route definitions mapping paths to controller actions |
| `project/build.properties` | Properties | SBT version pin (`sbt.version=0.13.18`) |
| `build.sbt` | SBT DSL | Dependency declarations, Play version, project metadata |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `LDAP_BIND_PASSWORD` | Authenticates the service against the LDAP directory for operator login | k8s-secret |
| `APPLICATION_SECRET` | Signs Play Framework sessions and CSRF tokens | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Staging** (`us-west-2`): `ULTRON_API_URL` points to the staging Ultron API instance; LDAP URL targets the staging directory. Deployed via Deploybot with staging Helm values.
- **Production** (`us-west-2`, `us-central1`): `ULTRON_API_URL` points to the production Ultron API instance; LDAP URL targets the production directory. Multi-region Kubernetes deployment with production Helm values.
