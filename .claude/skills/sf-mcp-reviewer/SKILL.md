---
name: sf-mcp-reviewer
description: >
  Perform structured Salesforce org reviews using MCP tools: security & permissions audits,
  automation change reviews, layout change reviews, object-level automation inventories,
  and SOQL-based data queries. Always use this skill when the user asks for any of the
  following — even partially or informally:
    - "security_permissions_review" or "show me permissions changes"
    - "sf_automation_changes" (org-wide or for a specific object like Opportunity, Case, Account)
    - "sf_opportunity_automation" or "[object] automation"
    - "sf_layout_changes" (org-wide or object-specific)
    - "show accounts/opportunities/leads created this [period]"
    - "who changed what in salesforce", "salesforce audit", "what happened this week in SF"
    - Any Salesforce review, audit, or inspection task mentioning MCP tool names
  Also trigger for phrases like "run the SF security review", "check automation on [object]",
  "list layout changes", "pull SF data for [object]".
compatibility:
  mcp_servers:
    - name: Salesforce
      tools:
        - sf_query
        - sf_automation_changes
        - sf_permission_profile_changes
        - sf_layout_changes
        - sf_suspicious_activity
        - sf_object_automation_detail
---

# Salesforce MCP Reviewer Skill

This skill maps user requests to the correct Salesforce MCP tool, handles fallbacks when tools
return 400 errors, and renders results as interactive, filterable widgets.

---

## Scenario Routing

Read the user's request and route to the correct section below.

| User says…                                          | Route to                        |
|-----------------------------------------------------|---------------------------------|
| `security_permissions_review` / permissions audit   | § Security & Permissions Review |
| `sf_automation_changes` / automation this week      | § Automation Changes            |
| `sf_[object]_automation` / automation on [object]   | § Object Automation Deep-Dive   |
| `sf_layout_changes` / layout changes                | § Layout Changes                |
| Show [object] records / SOQL data query             | § Data Queries                  |
| Full org audit / everything this week               | § Full Org Audit (combined)     |

---

## § Security & Permissions Review

### Primary: MCP tools (run in parallel)
```
sf_permission_profile_changes(include_assignments=true)
sf_suspicious_activity(include_api_anomalies=true)
```

### Fallback if tools return 400
```sql
-- Profile & permission changes
SELECT Action, Section, Display, CreatedDate, CreatedBy.Name
FROM SetupAuditTrail
WHERE CreatedDate = THIS_WEEK
AND (Section LIKE '%Profile%' OR Section LIKE '%Permission%'
     OR Section LIKE '%Role%' OR Section = 'Manage Users')
ORDER BY CreatedDate DESC LIMIT 500

-- Failed logins
SELECT UserId, Username, LoginTime, LoginType, Status, SourceIp, Browser
FROM LoginHistory
WHERE LoginTime = THIS_WEEK AND Status != 'Success'
ORDER BY LoginTime DESC LIMIT 200
```

### Output
Render an interactive widget with two tabs:
- **Permissions tab**: table of `Display`, `Section`, `Changed By`, `Date`
- **Suspicious Activity tab**: failed logins grouped by user + IP, bulk exports, API anomalies

Flag (⚠️) any: permission set removals, profile changes affecting many users, logins from new
countries, or bulk data exports.

---

## § Automation Changes

### Primary: MCP tool
```
sf_automation_changes(object_api_name?)   # omit for all objects
```

### Fallback if tool returns 400
```sql
-- Apex Classes modified this week
SELECT Name, Status, IsValid, LastModifiedDate, LastModifiedBy.Name
FROM ApexClass
WHERE LastModifiedDate = THIS_WEEK
ORDER BY LastModifiedDate DESC LIMIT 200

-- Apex Triggers modified this week
SELECT Name, TableEnumOrId, Status, IsValid, LastModifiedDate, LastModifiedBy.Name
FROM ApexTrigger
WHERE LastModifiedDate = THIS_WEEK
ORDER BY LastModifiedDate DESC LIMIT 50
```

If Flows / Validation Rules / Approval Processes also return 400, note the gap and explain that
`View Setup and Configuration` permission is required for those metadata types.

### Output
Interactive filterable table with columns: **Class name**, **Type** (Workflow / Trigger / Batch /
Service / Test), **Modified by**, **Last modified**, **Valid** (badge: green = valid, red =
invalid). Include filter buttons by developer name and validity. Highlight `Invalid` classes in
amber — they may indicate work-in-progress or broken deployments.

---

## § Object Automation Deep-Dive

Triggered by `sf_[object]_automation`, e.g. `sf_opportunity_automation`.

### Step 1 — Try the dedicated tool
```
sf_object_automation_detail(object_api_name="Opportunity", include_inactive=false)
```

### Step 2 — If tool returns 400, fall back to targeted SOQL
```sql
-- All Apex classes with the object name in their name
SELECT Id, Name, Status, IsValid, LastModifiedDate, LastModifiedBy.Name
FROM ApexClass
WHERE Name LIKE '%[ObjectName]%'
ORDER BY LastModifiedDate DESC

-- Apex triggers on the object
SELECT Id, Name, TableEnumOrId, Status, IsValid, LastModifiedDate, LastModifiedBy.Name
FROM ApexTrigger
WHERE TableEnumOrId = '[ObjectApiName]'
ORDER BY LastModifiedDate DESC
```

### Output
Two-tab widget:
- **This week** tab: classes/triggers modified in the current week, highlighted in amber
- **Full inventory** tab: all Apex automation for that object, filterable by type (Workflow /
  Trigger / Service / Queueable / Test) and validity

Summarize notable patterns in prose below the widget (e.g. AI/Gemini integration work,
invalid test classes needing attention, core trigger health).

---

## § Layout Changes

### Primary: MCP tool
```
sf_layout_changes(object_api_name?)   # omit for all objects
```

### Fallback if tool returns 400
```sql
-- All layout-related SetupAuditTrail entries
SELECT Id, Action, CreatedDate, CreatedBy.Name, Display, Section
FROM SetupAuditTrail
WHERE Action LIKE '%layout%'
ORDER BY CreatedDate DESC LIMIT 100
```

Then filter in-memory by object:
- Opportunity layouts → `Action = 'opplayout'` or `Display LIKE '%Opportunity%'`
- Account layouts   → `Action = 'accountlayout'`
- Case layouts      → `Action = 'caselayout'`
- Custom object     → `Action = 'custentlayout'`
- Custom MDT        → `Action = 'custmdtypelayout'`

### Output
Widget with two sections:
1. **[Object] layouts** — direct matches (badge: object name in teal)
2. **Related layout changes** — adjacent objects changed in the same session (badge: object type
   in gray), useful for identifying coordinated deployments

Note prominently if FlexiPage / Lightning Record Page changes could not be retrieved (400 error).

---

## § Data Queries

Triggered by: "show me [object] created this [period]", "list accounts/opps/leads/cases".

### Determine the right SOQL
- **Accounts**: `SELECT Id, Name, Industry, Type, Owner.Name, Phone, BillingCity, BillingCountry, CreatedDate FROM Account WHERE CreatedDate = [PERIOD] ORDER BY CreatedDate DESC`
- **Opportunities**: `SELECT Id, Name, StageName, Amount, CloseDate, Owner.Name, Account.Name, CreatedDate FROM Opportunity WHERE CreatedDate = [PERIOD] ORDER BY CreatedDate DESC`
- **Cases**: `SELECT Id, CaseNumber, Subject, Status, Priority, Owner.Name, Account.Name, CreatedDate FROM Case WHERE CreatedDate = [PERIOD] ORDER BY CreatedDate DESC`
- **Contacts**: `SELECT Id, Name, Title, Email, Phone, Account.Name, CreatedDate FROM Contact WHERE CreatedDate = [PERIOD] ORDER BY CreatedDate DESC`

Period tokens: `THIS_MONTH`, `THIS_WEEK`, `TODAY`, `LAST_MONTH`, `LAST_WEEK`, or custom
`>= YYYY-MM-DDT00:00:00Z AND <= YYYY-MM-DDT23:59:59Z`.

### Output
Clean table widget with:
- Record name (bold) + Salesforce ID (small, muted) in the first column
- Key fields as subsequent columns
- Record count badge in the header
- Note any missing fields (null Industry, no Phone etc.) that indicate data quality gaps

---

## § Full Org Audit (combined)

Run all MCP tools in parallel, then present a unified tabbed report:
```
sf_permission_profile_changes(include_assignments=true)
sf_suspicious_activity(include_api_anomalies=true)
sf_automation_changes()
sf_layout_changes()
```

Collect errors — for any tool returning 400, execute the corresponding SOQL fallback from the
relevant section above.

Render as a multi-tab widget: **Security** | **Automation** | **Layouts** | **Summary**

The Summary tab should surface the top 3–5 findings most likely to explain any user-reported
issues, flagged with ⚠️.

---

## Error Handling

| Error | Meaning | Action |
|-------|---------|--------|
| 400 from any MCP tool | Connected user lacks `View Setup and Configuration` | Execute SOQL fallback for that section. Note the gap in the widget. |
| SOQL `INVALID_TYPE` on `Layout` or `Metadata` | These objects aren't queryable via SOQL | Switch to `SetupAuditTrail` with `Action LIKE '%layout%'` |
| `Section` field can't be filtered | SetupAuditTrail `Section` is not filterable in WHERE | Remove Section from WHERE; filter in-memory after fetching |
| Query timeout | Dataset too large | Break into daily date ranges; use `LIMIT` + `OFFSET` pagination |
| All tools 400 + no SetupAuditTrail | User lacks all audit permissions | Inform user: a Salesforce Admin must grant `View Setup and Configuration` and re-authenticate the MCP connector |

---

## Output Design Principles

- **Always render as an interactive widget** — not raw text. Use filterable tables with
  developer-name filter buttons and validity/status badges.
- **Highlight this-week changes** in amber rows when showing full inventory views.
- **Surface invalid classes prominently** — they indicate incomplete deployments or broken tests.
- **Correlate across tools** — e.g. if Amit Patil edits both a layout and a workflow on the same
  day, call out this was likely a single coordinated deployment session.
- **Note permissions gaps** — whenever a tool returns 400, include a plain-language note in the
  widget footer explaining what's missing and what permission is needed to fix it.
- **Empty results aren't failures** — if a section has no changes, state "No changes this week"
  explicitly so the reader knows it was checked.

---

## Reference Files

| File | When to Read |
|---|---|
| `references/soql-fallbacks.md` | When MCP tools return 400 — contains full fallback query library |
| `references/widget-patterns.md` | Before building output widgets — contains reusable HTML/CSS patterns |
