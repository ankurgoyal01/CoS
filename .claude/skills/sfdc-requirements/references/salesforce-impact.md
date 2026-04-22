# Salesforce Impact Analysis — Checklist & Guidance

Use this reference when writing Section 2 of the Technical Design Document.
For each area, ask whether the requirement touches it, then document accordingly.

---

## 2.1 Custom Objects & Fields

### Questions to ask about the requirement:
- Does this introduce a new entity not currently tracked in Salesforce?
- Does an existing object need new data attributes?
- Are any existing fields no longer needed (deprecation)?

### Checklist:
- [ ] New custom objects required? (name, API name, sharing model)
- [ ] New fields on existing objects? (for each: object, field label, API name, data type, length/picklist values, required?)
- [ ] Existing fields to be modified? (type change, picklist value additions, required flag change)
- [ ] Validation rules to be added or updated?
- [ ] Duplicate rules affected?
- [ ] Record types affected?
- [ ] Page layouts to be updated?
- [ ] Lightning record pages to be updated?
- [ ] Field dependencies / controlling-dependent picklists?

### Common field types reference:
| Type | Use case |
|---|---|
| Text | Short free-form text (<255 chars) |
| Long Text Area | Notes, descriptions |
| Picklist | Fixed set of values |
| Lookup | Relationship to another object |
| Master-Detail | Parent-child with rollup support |
| Currency | Monetary values |
| Formula | Calculated, read-only |
| Checkbox | Boolean |
| Date / DateTime | Dates and timestamps |
| Number | Integers or decimals |

---

## 2.2 Flows & Process Builder

### Questions to ask about the requirement:
- Does this need automation triggered by a record change?
- Does this need a user-facing guided process (screen flow)?
- Does this involve scheduled automation?
- Can this replace an existing Process Builder that should be migrated to Flow?

### Checklist:
- [ ] Flow type: Record-Triggered / Screen / Schedule-Triggered / Platform Event-Triggered / Autolaunched?
- [ ] Trigger object and conditions (which field change, which record type)?
- [ ] Run when: record is created / updated / created or updated / deleted?
- [ ] Before-save or after-save action (before-save for field updates, after-save for DML on other objects)?
- [ ] Decision logic documented (if/else branches)?
- [ ] Loops required (for collections)?
- [ ] Subflows called?
- [ ] External callouts via invocable actions?
- [ ] Email alerts or notifications triggered?
- [ ] Chatter posts or notifications?
- [ ] Bulk-safe? (avoid SOQL/DML inside loops)
- [ ] Existing flows to deactivate or version?

---

## 2.3 Apex Classes & Triggers

### Questions to ask about the requirement:
- Is the logic too complex for Flow (complex branching, cross-object aggregation)?
- Is there a need for callouts to external systems?
- Is there batch/scheduled processing?
- Is there a need for platform events or change data capture?

### Checklist:
- [ ] Trigger object and events (before/after insert/update/delete/undelete)?
- [ ] Handler class pattern used? (TriggerHandler base class, one handler per object)
- [ ] Bulk-safe implementation? (collections, maps, no SOQL in loops)
- [ ] New service/utility classes needed?
- [ ] Batch Apex needed? (>50k records, scheduled processing)
- [ ] Schedulable class needed?
- [ ] Queueable class needed? (async processing, chaining)
- [ ] Future methods needed? (callouts, mixed DML)
- [ ] Platform Events produced or consumed?
- [ ] Named Credentials updated?
- [ ] Custom Metadata Types or Custom Settings needed?
- [ ] Unit test classes: minimum 75% coverage required; target 90%+
- [ ] Existing classes to be modified — check for downstream impacts

### Class naming conventions to follow:
| Type | Pattern |
|---|---|
| Trigger | `<Object>Trigger` (e.g., `AccountTrigger`) |
| Handler | `<Object>TriggerHandler` |
| Service | `<Domain>Service` (e.g., `OpportunityService`) |
| Batch | `<Purpose>Batch` |
| Test | `<ClassName>Test` |

---

## 2.4 Profiles & Permissions

### Questions to ask about the requirement:
- Who should see this new object or field?
- Are there role-based access differences?
- Does this affect any external users (Communities / Experience Cloud)?

### Checklist:
- [ ] Which profiles need access to new objects? (Read / Create / Edit / Delete / View All / Modify All)
- [ ] Which permission sets need to be created or updated?
- [ ] Field-level security for new fields — which profiles/permission sets get read vs edit?
- [ ] Tab visibility for new objects?
- [ ] App access changes?
- [ ] Sharing rules needed? (criteria-based or owner-based)
- [ ] Role hierarchy impacts?
- [ ] OWD (org-wide defaults) change needed? (Public Read/Write, Public Read Only, Private)
- [ ] Manual sharing implications?
- [ ] Communities / Experience Cloud profile impacts?
- [ ] Connected app or OAuth scope changes?
- [ ] Named credentials or external credentials?

---

## Impact Scoring Guide

Use this to set estimated complexity in Section 3:

| Score | Criteria |
|---|---|
| **Low** | No new objects, ≤3 new fields, 1 simple flow or trigger handler, standard permission set updates |
| **Medium** | 1 new object OR 4–10 fields, 1–2 flows with moderate logic, 1–2 Apex classes, some permission set updates |
| **High** | 2+ new objects, 10+ fields, complex flows with subflows, multiple Apex classes/triggers, batch processing, integration callouts, significant permission restructuring |
