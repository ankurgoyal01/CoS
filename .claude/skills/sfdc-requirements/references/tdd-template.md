# Technical Design Document — Template

Use this structure when generating the TDD `.docx` file. All sections are required unless marked optional.

---

## Document Header (Cover Page Style)

| Field | Value |
|---|---|
| Document Title | Technical Design Document — [Requirement Title] |
| Project | Salesforce / SFDC |
| Source | Asana: [task URL] OR Jira: [ticket URL] |
| Prepared By | Claude (Auto-generated) |
| Date | [Today's date] |
| Version | 1.0 |
| Status | Draft |

---

## Section 1 — Business Requirements Summary

**Purpose**: Clearly state what the business is asking for in plain language.

Include:
- Background / Context: Why is this change being requested?
- Business Objective: What outcome does the business want?
- Scope: What is in scope? What is explicitly out of scope?
- Stakeholders: Who requested this? Who is affected?
- Priority / Urgency: Any stated deadline or business impact?

---

## Section 2 — Salesforce Impact Analysis

This is the core technical section. Cover all five areas below.

### 2.1 Custom Objects & Fields

- List any **new objects** that need to be created
- List any **new fields** needed on existing objects (field name, type, picklist values if applicable)
- List any **existing fields** that need to be modified or deprecated
- Note any **field-level security** considerations
- Note any **validation rules** that need to be created or updated

Format as a table where possible:

| Object | Field Name | Type | Action | Notes |
|---|---|---|---|---|
| ... | ... | ... | Create/Modify/Delete | ... |

### 2.2 Flows & Process Builder

- List any **new Flows** to be created (type: Screen Flow, Record-Triggered, Schedule-Triggered, etc.)
- List any **existing Flows** to be updated or deactivated
- Describe the **trigger conditions** (record type, field change, schedule)
- Describe **key logic steps** at a high level (decision nodes, actions, subflows)
- Note **governor limit considerations** for bulk operations

### 2.3 Apex Classes & Triggers

- List any **new Apex Triggers** required (object, trigger events: before/after insert/update/delete)
- List any **new Apex Classes** (handler classes, service classes, batch classes, schedulable classes)
- List any **existing classes** that need modification
- Note any **test class** requirements
- Flag any **integration points** (callouts, platform events, change data capture)
- Note **bulk-safe patterns** to follow

### 2.4 Profiles & Permissions

- List **profiles or permission sets** that need to be updated
- Specify **object-level permissions** changes (CRUD)
- Specify **field-level security** changes
- Specify any **tab visibility** or **app access** changes
- Note any **sharing rules** or **role hierarchy** impacts
- Note if any **connected apps** or **named credentials** are involved

### 2.5 Alignment with Org Automation Standards

This section documents how the proposed design relates to Groupon's existing Salesforce automation landscape and architecture. It is populated from the two org context resources fetched in Step 1.5 of the skill.

**Existing Automations Review** (from the Sales Cloud Automations doc):

| Existing Automation | Type | Object(s) | Relationship to This Work | Action Required |
|---|---|---|---|---|
| [Name from doc] | Flow / Apex / PB | [Object] | Overlaps / Extends / Unrelated | Update / Deactivate / None |

If the automation doc was unavailable, insert the warning block here and leave the table empty.

**Architecture Alignment** (from the architecture diagram):

- Note which part of the architecture diagram this work touches (e.g., "Adds a new node on the Account → Opportunity data flow")
- Identify any integration boundaries crossed (e.g., external CRM sync, platform event bus)
- Confirm the proposed design is consistent with the patterns shown — or explicitly call out where it intentionally deviates and why

If the diagram was unavailable, insert the warning block here and note the gap.

**Naming Conventions**: Document the naming pattern observed in the org for Flows, Apex classes, and custom fields, and confirm the names chosen in sections 2.1–2.4 follow that pattern.

---

## Section 3 — Implementation Approach

**Purpose**: How will this be built? What is the recommended sequence?

Include:
- Recommended technical approach and rationale
- Implementation sequence / phases (if multi-step)
- Dependencies between components (e.g., create object before building flow)
- Environment strategy (sandbox → staging → production)
- Estimated complexity: Low / Medium / High with brief justification
- Any third-party packages or managed package impacts

---

## Section 4 — Risks & Assumptions

### Assumptions
List any assumptions made during analysis (e.g., "Assumed the existing Account object will be used rather than a new object").

### Risks
List potential risks and mitigation strategies:

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| ... | Low/Med/High | Low/Med/High | ... |

---

## Section 5 — Acceptance Criteria

List the specific, testable criteria that must be met for this work to be considered complete. Format as a checklist:

- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

These should be derived from the original requirement and the Salesforce impact analysis.

---

## Section 6 — Open Questions (Optional)

If there are unresolved questions that need business or technical clarification before implementation begins, list them here:

| # | Question | Owner | Status |
|---|---|---|---|
| 1 | ... | Business / Tech | Open |

---

## Docx Formatting Notes

When generating the .docx file:
- Use **Heading 1** for section numbers (e.g., "1. Business Requirements Summary")
- Use **Heading 2** for sub-sections (e.g., "2.1 Custom Objects & Fields")
- Use **bold** for table headers
- Use light blue shading (`D5E8F0`) for table header rows
- Page size: US Letter (12240 x 15840 DXA), 1-inch margins
- Font: Arial 12pt body, 16pt H1, 14pt H2
- Include a page break before Section 2
- Footer: Document title on left, page number on right
