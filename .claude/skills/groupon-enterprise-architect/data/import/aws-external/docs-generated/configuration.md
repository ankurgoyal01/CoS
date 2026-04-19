---
service: "aws-external"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: []
---

# Configuration

## Overview

> No evidence found in codebase.

`aws-external` contains no application code and therefore has no runtime configuration. The repository's service identity (`name: aws-external`) is declared in `.service.yml`. All configuration relevant to AWS account access and incident routing is managed externally — either within Groupon's incident management tooling or within the individual infrastructure projects (CloudCore, Conveyor, etc.) that provision AWS resources.

## Environment Variables

> No evidence found in codebase.

## Feature Flags

> No evidence found in codebase.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.service.yml` | YAML | Declares the service name `aws-external` for Groupon's service registry and alert-routing tooling |

## Secrets

> No evidence found in codebase.

## Per-Environment Overrides

> No evidence found in codebase.
