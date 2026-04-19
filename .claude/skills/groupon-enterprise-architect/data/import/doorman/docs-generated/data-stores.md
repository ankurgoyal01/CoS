---
service: "doorman"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

Doorman is a stateless service. It owns no databases, caches, or persistent storage. All authentication state is managed externally: Okta holds identity provider session state, Users Service owns user account data and token signing keys, and destination tools are responsible for consuming and storing the issued token. Doorman reads configuration from YAML files on disk (loaded at startup) but writes no persistent data.

## Stores

> This service is stateless and does not own any data stores.

## Caches

> No evidence found in codebase. No caching layer is used.

## Data Flows

Doorman's only data-related flow is read-only at startup: the `EnvConfig` class loads per-environment YAML configuration files (`config/<RACK_ENV>/*.yml`) into memory once when the application starts. These in-memory configuration hashes are referenced during request handling but never written to disk or an external store.
