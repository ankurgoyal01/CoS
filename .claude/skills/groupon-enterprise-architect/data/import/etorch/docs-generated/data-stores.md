---
service: "etorch"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "etorchDb"
    type: "relational"
    purpose: "Persistent storage for contacts, contact roles, and job state"
---

# Data Stores

## Overview

eTorch owns a relational database (likely PostgreSQL, consistent with standard Continuum platform practice) used to persist merchant contact data, contact role mappings, and background job execution state. The service is not stateless: it writes contact and job records that are queried back through the extranet API.

## Stores

### eTorch Relational Database (`etorchDb`)

| Property | Value |
|----------|-------|
| Type | Relational (PostgreSQL) |
| Architecture ref | `continuumEtorchApp` / `continuumEtorchWorker` |
| Purpose | Stores hotel contacts, contact roles, and worker job state |
| Ownership | owned |
| Migrations path | > No evidence found — managed by service team |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| contacts | Hotel contact records created and managed via the extranet API | hotel UUID, name, email, role |
| contact_roles | Enumerated roles assignable to hotel contacts | role ID, role name |
| job_state | Execution state and result records for background worker jobs | job type, status, run timestamp |

#### Access Patterns

- **Read**: Contacts and contact roles are read by the `etorchAppControllers` on GET requests; job state is read by `etorchWorkerScheduler` to determine next run timing.
- **Write**: Contacts are written on POST requests; job state is updated by `etorchWorkerJobs` on job start and completion.
- **Indexes**: > No evidence found — index details are not visible from the architecture model.

## Caches

> No evidence found for any caching layer.

## Data Flows

Accounting statements and payment data are not stored in eTorch's own database. They are read on demand from `continuumAccountingService` and returned directly to the API caller. Inventory data is similarly delegated to the Getaways Inventory service. eTorch's database is limited to extranet-specific operational data (contacts, roles, job records).
