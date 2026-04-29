---
name: sf-config-monitor
version: 1.0
description: >
  Automated Salesforce configuration change risk report.
  Runs Monday, Wednesday, Friday. Queries SetupAuditTrail for the
  period since the last run (2 days), scores each change Critical /
  High / Medium / Low / Noise, groups by actor, and saves a structured
  markdown report + creates an Asana task.

  Trigger phrases:
  - "sf config report", "salesforce config changes", "what changed in SF"
  - "sf audit report", "config risk report", "sf monitoring report"
  - Or invoked headlessly by sf-config-monitor.sh
---

# SF Config Monitor Skill — v1.0

## What this skill does

Queries Salesforce SetupAuditTrail for the reporting period, applies
a risk scoring model, and produces a structured report covering:
- Total events by risk tier
- Critical events (action required)
- High events grouped by actor + section
- Medium events grouped by section
- Top actors by change volume and risk
- Executive summary with flags

---

## Step 1 — Determine reporting period

Default: last 2 days (Mon = Sat–Mon, Wed = Mon–Wed, Fri = Wed–Fri).
If invoked manually with a date range, use that instead.

```
Period start: YYYY-MM-DDT00:00:00Z
Period end:   YYYY-MM-DDT23:59:59Z
```

---

## Step 2 — Run SOQL queries via Salesforce MCP (sf_query)

Run all queries before building the report.

### Q1 — Full SetupAuditTrail for period
```sql
SELECT Action, Section, Display, CreatedDate,
       CreatedBy.Name, CreatedBy.Username
FROM SetupAuditTrail
WHERE CreatedDate >= [START] AND CreatedDate <= [END]
AND Section NOT IN ('Login', 'Logout', 'Password', 'Session', 'API Usage')
ORDER BY CreatedDate DESC
LIMIT 2000
```

### Q2 — High-volume data changes (Account)
```sql
SELECT LastModifiedBy.Name, COUNT(Id) recordCount
FROM Account
WHERE LastModifiedDate >= [START] AND LastModifiedDate <= [END]
GROUP BY LastModifiedBy.Name
HAVING COUNT(Id) > 200
ORDER BY COUNT(Id) DESC
```

### Q3 — High-volume data changes (Opportunity)
```sql
SELECT LastModifiedBy.Name, COUNT(Id) recordCount
FROM Opportunity
WHERE LastModifiedDate >= [START] AND LastModifiedDate <= [END]
GROUP BY LastModifiedBy.Name
HAVING COUNT(Id) > 200
ORDER BY COUNT(Id) DESC
```

---

## Step 3 — Risk scoring model

Apply this scoring to every SetupAuditTrail row:

### CRITICAL — Action required, review immediately
- Section contains: `Manage Users` AND action is profile/role/permission change
- Action = `deleted` + Section contains `Permission`
- Action = `created` + Section contains `Permission Set` with no license
- Flow deactivated AND no paired re-activation by same actor within 10 min
- Section contains `Role` AND action changes a user's role

### HIGH — Review this week
- Section contains `Flow` + action in (created, activated, deactivated, deleted)
  — UNLESS paired activate/deactivate by same actor within 10 min → demote to Medium
- Section contains `Apex Class` OR `Apex Trigger`
- Section contains `Approval Process`
- Section contains `Validation Rule`
- Section contains `Customize Accounts` OR `Customize Opportunities` (layout changes)
- Section contains `Inbound Change Set` (deployments)
- Section contains `Workflow Rule`

### MEDIUM — Informational, low urgency
- Section contains `Manage Users` (bulk user property changes)
- Section contains `Lightning Page` OR `FlexiPage`
- Section contains `Custom Object` OR `Custom Field`
- Section contains `External Client Application`
- Section contains `OAuth`
- Section contains `Application` OR `Custom App`

### LOW — Normal operation
- Section contains `Customize` (general layout tweaks not in High)
- Section contains `Report` OR `Dashboard`
- Section contains `Email Template`

### NOISE — Suppress from detail view
- CreatedBy.Username contains `@salesforce.com` OR = `Automated Process`
- Action = `activated` immediately followed by `deactivated` (same actor, same flow, < 10 min)
- System-generated: Section contains `Apex Class` AND CreatedBy = `system`

---

## Step 4 — Build the report

Output exactly this structure:

```markdown
# Salesforce Config Risk Report
**Period:** [START_DATE] to [END_DATE] · **Total events:** [N]
**Risk:** Critical [N] · High [N] · Medium [N] · Low [N] · Noise [N]
[Note any demotions: e.g. "9 flow deactivations demoted Critical→High (paired re-activation by same actor within 10 min)"]

---

## Executive Summary
[2-4 sentences: total critical count, key actors to review, any patterns
 or flags that warrant immediate attention. If 0 critical — say so clearly.]

---

## 🔴 Critical ([N])
[For each critical event:]
[DATE, TIME IST] · [Actor Name] · [Section]
    ↳ [Display text — what exactly changed]

[If none: "No critical events this period."]

---

## 🟠 High ([N])
Grouped by actor + section + first verb to suppress churn.

[Actor Name] · [verb] in [Section] · [N]x ([comma list of items changed])
...

[If none: "No high-risk events this period."]

---

## 🟡 Medium ([N])
[Section] · [N] changes by [Actor1], [Actor2], ...
...

---

## 📊 Top Actors This Period
[Actor Name] · [total] changes · Critical [N] · High [N]
...
(top 8 by total, excluding system/automated)

---

## ⚠️ Flags
[Any patterns that could explain production issues:
- Flow edited just before a reported issue
- Permission stripped from profile
- Validation rule added on Friday
- Deployment to Production (not sandbox)
If none: "No flags this period."]
```

---

## Step 5 — Save and notify

1. Save report to: `~/CoS/logs/sf-config-monitor/sf-config-[YYYY-MM-DD].md`
2. Create Asana task:
   - Name: `SF Config Report — [Day, Date]`
   - Assignee: me (GID: 1211542692184092)
   - Workspace: groupon.com (GID: 8437193015852)
   - Due: today
   - Notes: full report content
   - No project — My Tasks only

---

## Risk score constants (for reference)

```
CRITICAL = flows deactivated (unpaired) · profile/role/perm changes · perm set create/delete
HIGH     = flows (paired churn) · Apex · approvals · validation rules · layouts · deployments
MEDIUM   = bulk user changes · Lightning pages · custom objects/fields · OAuth · apps
LOW      = reports · dashboards · email templates · general customise
NOISE    = system actor · paired activate/deactivate < 10min · automated process
```
