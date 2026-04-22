---
name: sf-change-report
description: >
  Generate a Salesforce weekly change summary report for the current week (Sunday–Saturday).
  Use this skill whenever the user asks for a Salesforce change report, change summary, weekly
  audit, org changes this week, or wants to understand what changed in their Salesforce org.
  Trigger phrases include: "generate a report for this week on the salesforce changes",
  "salesforce change report", "what changed in salesforce this week", "sf weekly audit",
  "salesforce org changes", "sf change summary", "who changed what in salesforce".
  Always use this skill when the user wants to audit or review recent Salesforce activity —
  even if they don't use the word "report".
---

# Salesforce Weekly Change Report Skill

This skill queries Salesforce for all meaningful changes made during the **current week (Sunday–Saturday)** and produces a structured report to help the team understand what changed and whether recent issues could be related to those changes.

---

## What the Report Covers

1. **High-Volume Data Changes** — Accounts or Opportunities updated by a single user with more than 200 records changed
2. **Security & Access Changes** — Profile or Permission Set updates (what changed, who changed it)
3. **Code Changes** — Apex classes or triggers modified, and by whom
4. **Metadata Changes** — Custom fields, validation rules, approval processes, flows, process builder, and Lightning components
5. **UI Changes** — Page layout modifications
6. **Lightning Record Page Updates** — FlexiPage / Lightning App Builder changes

---

## Step 1 — Determine Date Range

The report always covers **Sunday through Saturday of the current week**. Use `THIS_WEEK` in SOQL (Salesforce's `THIS_WEEK` filter aligns with Sunday–Saturday).

If the user specifies a different week (e.g., "last week" or a specific date), substitute `LAST_WEEK` or a custom date range: `WHERE CreatedDate >= YYYY-MM-DDT00:00:00Z AND CreatedDate <= YYYY-MM-DDT23:59:59Z`.

---

## Step 2 — Run SOQL Queries

Use the `sf_query` tool (Salesforce MCP) to execute each query below. Run them **all before starting the report** so you have complete data.

If any query returns an error, note the error in the report section and continue with remaining queries.

> **Important**: `SetupAuditTrail` is the primary source for configuration, metadata, and security changes. It tracks up to 6 months of org history. The `Section` field categorizes the type of change; `Display` has a human-readable description of exactly what changed.

### Query 1 — High-Volume Account Changes (>200 per user)
```sql
SELECT LastModifiedBy.Name, LastModifiedBy.Username, LastModifiedById, COUNT(Id) recordCount
FROM Account
WHERE LastModifiedDate = THIS_WEEK
GROUP BY LastModifiedBy.Name, LastModifiedBy.Username, LastModifiedById
HAVING COUNT(Id) > 200
ORDER BY COUNT(Id) DESC
```

### Query 2 — High-Volume Opportunity Changes (>200 per user)
```sql
SELECT LastModifiedBy.Name, LastModifiedBy.Username, LastModifiedById, COUNT(Id) recordCount
FROM Opportunity
WHERE LastModifiedDate = THIS_WEEK
GROUP BY LastModifiedBy.Name, LastModifiedBy.Username, LastModifiedById
HAVING COUNT(Id) > 200
ORDER BY COUNT(Id) DESC
```

### Query 3 — Profile & Permission Set Changes
```sql
SELECT Action, Section, Display, CreatedDate, CreatedBy.Name, CreatedBy.Username
FROM SetupAuditTrail
WHERE CreatedDate = THIS_WEEK
AND (Section LIKE '%Profile%' OR Section LIKE '%Permission%' OR Section LIKE '%Role%' OR Section = 'Manage Users')
ORDER BY CreatedDate DESC
LIMIT 500
```

### Query 4 — Apex Class & Trigger Changes
```sql
SELECT Action, Section, Display, CreatedDate, CreatedBy.Name, CreatedBy.Username
FROM SetupAuditTrail
WHERE CreatedDate = THIS_WEEK
AND (Section = 'Apex Class' OR Section = 'Apex Trigger' OR Section LIKE '%Apex%')
ORDER BY CreatedDate DESC
LIMIT 500
```

Also run this to get the actual class metadata:
```sql
SELECT Name, LastModifiedBy.Name, LastModifiedBy.Username, LastModifiedDate, ApiVersion
FROM ApexClass
WHERE LastModifiedDate = THIS_WEEK
ORDER BY LastModifiedDate DESC
LIMIT 200
```

```sql
SELECT Name, LastModifiedBy.Name, LastModifiedBy.Username, LastModifiedDate, TableEnumOrId
FROM ApexTrigger
WHERE LastModifiedDate = THIS_WEEK
ORDER BY LastModifiedDate DESC
LIMIT 200
```

### Query 5 — Metadata Changes (Fields, Validation Rules, Approval Processes, Flows, Process Builder, Lightning Components)
```sql
SELECT Action, Section, Display, CreatedDate, CreatedBy.Name, CreatedBy.Username
FROM SetupAuditTrail
WHERE CreatedDate = THIS_WEEK
AND (
  Section LIKE '%Field%'
  OR Section LIKE '%Validation%'
  OR Section LIKE '%Approval%'
  OR Section LIKE '%Flow%'
  OR Section LIKE '%Process%'
  OR Section LIKE '%Lightning Component%'
  OR Section LIKE '%Aura%'
  OR Section LIKE '%LWC%'
  OR Section LIKE '%Custom Object%'
)
ORDER BY CreatedDate DESC
LIMIT 500
```

### Query 6 — Page Layout Changes
```sql
SELECT Action, Section, Display, CreatedDate, CreatedBy.Name, CreatedBy.Username
FROM SetupAuditTrail
WHERE CreatedDate = THIS_WEEK
AND (Section LIKE '%Page Layout%' OR Section LIKE '%Layout%')
ORDER BY CreatedDate DESC
LIMIT 200
```

### Query 7 — Lightning Record Page (FlexiPage) Changes
```sql
SELECT Action, Section, Display, CreatedDate, CreatedBy.Name, CreatedBy.Username
FROM SetupAuditTrail
WHERE CreatedDate = THIS_WEEK
AND (Section LIKE '%Lightning Page%' OR Section LIKE '%FlexiPage%' OR Section LIKE '%App Builder%')
ORDER BY CreatedDate DESC
LIMIT 200
```

### Query 8 — Broad Audit Catch-All (anything missed above)
This query captures any other significant changes not covered by the specific sections above:
```sql
SELECT Action, Section, Display, CreatedDate, CreatedBy.Name, CreatedBy.Username
FROM SetupAuditTrail
WHERE CreatedDate = THIS_WEEK
AND Section NOT IN ('Login', 'Logout', 'API Usage', 'Password', 'Session')
ORDER BY CreatedDate DESC
LIMIT 1000
```

Use this catch-all to identify any notable changes not already captured in Queries 3–7. Deduplicate against existing results.

---

## Step 3 — Build the Report

Read the `references/report-template.md` file for the exact output structure.

Generate the report as a **`.docx` file** using the `docx` skill.

**Filename is required** — always save with this exact naming pattern:
```
SF_Change_Report_Week_of_YYYY-MM-DD.docx
```
where `YYYY-MM-DD` is the **Sunday** of the current week (the week's start date). For example, if today is March 21, 2026 (a Saturday), the Sunday of that week is March 15, so the filename is `SF_Change_Report_Week_of_2026-03-15.docx`.

Save the file to `/sessions/.../mnt/outputs/` and provide a download link.

### Report Design Principles

- **Actionability over completeness**: Group related changes together. Don't just dump raw SOQL results — synthesize. For each section, lead with a one-sentence summary ("3 users made high-volume changes to Accounts this week") then show the details.
- **Flag potential issues**: If you see patterns that could explain user-reported problems (e.g., a validation rule added on Friday before the weekend, or a permission set stripped from a profile, or a flow edited that runs on Account save), call this out prominently with a ⚠️ flag.
- **Empty sections matter**: If a section has no changes, write "No changes this week." — never skip the section entirely, so the reader knows it was checked.
- **Sort by recency**: Within each section, show the most recent changes first.

---

## Step 4 — Deliver

1. Save the `.docx` to `/sessions/.../mnt/outputs/`
2. Present the file link to the user
3. Give a brief inline summary highlighting the **most notable changes** (3–5 bullet points max), especially anything that could explain business-reported issues

---

## Reference Files

| File | When to Read |
|---|---|
| `references/report-template.md` | Before generating the report (Step 3) |

---

## Error Handling

- **SetupAuditTrail returns no results**: The org may have enhanced audit trail disabled, or the user may not have "Manage Users" or "View Setup and Configuration" permission. Note this in the report and suggest the admin check Setup > Audit Trail directly.
- **HAVING clause unsupported**: Some Salesforce editions don't support HAVING in certain contexts. Fall back to fetching all records and filtering in-memory.
- **Query timeout**: Break large queries into smaller date ranges (e.g., query day by day for the week).
- **sf_query tool unavailable**: Inform the user the Salesforce connection is not available and ask them to check their MCP configuration.
