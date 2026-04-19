---
service: "ORR"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. The ORR Audit Toolkit reads configuration data from external sources (the `ops-config` git repository and `lbmon1.<colo>.yml` lbmon config files cloned locally) and writes audit results to ephemeral, timestamped flat files in the operator's home directory (`~/`) and `/tmp/`. No database, cache, or persistent store is provisioned or managed by this toolkit.

## Stores

> This service is stateless and does not own any data stores.

## Caches

> No evidence found in codebase.

## Data Flows

- Reads: Production host YAML files from `ops-config/hosts/` directory (local git clone)
- Reads: Load balancer monitor config files `lbmon1.snc1.yml`, `lbmon1.sac1.yml`, `lbmon1.dub1.yml` from the local `ops-config` clone
- Writes: Audit report files to `~/orr_audit_pd.report.*` (timestamped, per-script, per-run)
- Writes: Orphaned host list to `/tmp/hosts_without_service.txt`
- All writes are append/overwrite on each script invocation; no retention policy is enforced by the toolkit itself
