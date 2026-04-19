---
service: "amsJavaScheduler"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumAmsSchedulerScheduleStore"
    type: "text-files"
    purpose: "Cron schedule definitions loaded at startup"
---

# Data Stores

## Overview

AMS Java Scheduler owns one logical data store: the Scheduler Schedule Store, which is a set of versioned plain-text schedule definition files bundled inside the application JAR (under `amsJavaScheduler/schedules/`). The service is otherwise stateless — it does not own a relational database, cache, or object store. All persistent audience and SAD state is owned by `continuumAudienceManagementService`.

## Stores

### Scheduler Schedule Store (`continuumAmsSchedulerScheduleStore`)

| Property | Value |
|----------|-------|
| Type | Text files (plain-text cron schedule definitions) |
| Architecture ref | `continuumAmsSchedulerScheduleStore` |
| Purpose | Maps cron expressions to fully-qualified action class names for each region and environment |
| Ownership | owned |
| Migrations path | `amsJavaScheduler/schedules/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `schedule-na.txt` | NA production cron schedule | `<cron-expression>:<action-class-FQCN>` per line |
| `schedule-emea.txt` | EMEA production cron schedule | `<cron-expression>:<action-class-FQCN>` per line |
| `schedule-na-staging.txt` | NA staging cron schedule | `<cron-expression>:<action-class-FQCN>` per line |
| `schedule-emea-staging.txt` | EMEA staging cron schedule | `<cron-expression>:<action-class-FQCN>` per line |
| `schedule-na-uat.txt` | NA UAT cron schedule | `<cron-expression>:<action-class-FQCN>` per line |
| `schedule-emea-uat.txt` | EMEA UAT cron schedule | `<cron-expression>:<action-class-FQCN>` per line |

#### Access Patterns

- **Read**: Schedule files are read once at application startup by `amsScheduler_scheduleLoader`. The file path is resolved from configuration (config file or `RUN_CONFIG` environment variable). Files are bundled in the JAR but the config location can point to an external path.
- **Write**: Schedule files are modified by developers as code changes and bundled into new releases. There is no runtime write access to these files.
- **Indexes**: Not applicable — files are read sequentially, one line per schedule entry.

## Caches

> No evidence found — this service does not use any cache layer.

## Data Flows

Schedule files flow from source control into the application JAR at build time. At startup, the Schedule Definition Loader reads the appropriate schedule file based on the active environment/realm configuration, parses each line into a `(cron-expression, action-class)` pair, and registers each pair with the `cron4j` scheduler engine. From that point, all SAD/SAI state flows exclusively through calls to `continuumAudienceManagementService` — no data is persisted locally by the scheduler.
