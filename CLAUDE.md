# CLAUDE.md — Ankur Goyal, Engineering Manager @ Groupon
## SFDC team + GSOIT team

> Loaded at the start of every Claude Code session.
> Contains persistent context about both teams, their systems, and how I work.
> Last updated: April 10, 2026 (v1 — enriched with live sprint data)

---

## 1. Identity & Role

- **Name:** Ankur Goyal
- **Title:** Engineering Manager — Salesforce (SFDC) + GSOIT
- **Company:** Groupon
- **Location:** Bengaluru, India (IST, UTC+5:30)
- **Manager:** Josef Sima
- **CMO reference:** Josef Buryan (AI maturity direction — target L5–6 now, L8–10 by Q3)

I manage two engineering teams:

| Team | Jira Board | Domain | Size |
|------|-----------|--------|------|
| **SFDC** | `SFDC` | Salesforce platform — Apex, LWC, Flows, Triggers, Sales Cloud, Service Cloud | 7 engineers |
| **GSOIT** | `GSOIT` | Web services — Java, Ruby on Rails, Node.js, Python | 4 engineers |

I recently took over GSOIT from Vijayamoorthy R. Tech lead assignments have been updated — the services report is not yet reflecting the new owners.

---

## 2. Team Roster

### SFDC Team (7 members)

| Name | Role | Specialisation |
|------|------|---------------|
| Ashwinkrishna M | Senior Salesforce Developer | Apex, LWC, Sales Cloud |
| Niveditha Ramegowda | Senior Salesforce Developer | Apex, LWC, Service Cloud |
| Nirajkumar Shelke | Senior Salesforce Developer | Apex, Triggers, integrations |
| Kumar Ankit | Senior Salesforce Developer | Apex, LWC, Sales Cloud |
| Amit Patil | Senior Salesforce Developer | Apex, Flows, Service Cloud |
| Srilakshmi K S | Salesforce Administrator | Config, reports, dashboards, data ops |
| Utkarsh Pathak | Salesforce Administrator | Config, automation, deployments |

### GSOIT Team (4 members)

| Name | Role | Services Led |
|------|------|-------------|
| Ravi Kumar | Principal Developer | Pizza NG, Ingestion Service, RPA, Webbus |
| Rakesh Haridas | Senior Developer | Cyclops, CS-Token Service, Deal Panel, Deal Wizard, Salesforce-Cache |
| Datta Maddala | Senior Developer | SFDC-ETL, Salesforce-Metrics, Cyclops latency investigation |
| Ravindra Kumar | Senior Developer | Cyclops As A Platform (cs-api), Transporter-Jtier, Transporter-Itier |

### Key Stakeholders

| Name | Role | Relevance |
|------|------|-----------|
| Dennis Bertelkamp | Product Owner (SP) | Primary PO for most GSOIT services |
| Michal Jilka | Product Owner (SP) | Cyclops, CS-Token Service |
| Chris Hill | RevOps Lead | SFDC requirements source, Opportunity governance |
| Maciej Kołodziej | Sales Ops | Opportunity & Lead process owner |
| Veronika Zapletalova | Merchant Support Lead | Merchant-facing processes, Merchant Center alignment |
| Samuel Garcia Rio | Customer Support Lead | Service Cloud, Case escalations |
| Giovanni Lagasio | CommOps Lead | Commercial Operations |
| Zeph Buck | CommOps | Commercial Operations |
| Dilpreet Dhaliwal | Cross-functional | AI automation testing — Salesforce field reports, Cyclops/BigQuery data pipelines |

---

## 3. Connected Systems & MCP Servers

Claude has live MCP access to these. **Always prefer MCP tools over asking me for data.**

| System | MCP Server | Use for |
|--------|-----------|---------|
| **Jira** | Atlassian MCP | Sprint data, tickets, blockers — pull from SFDC and GSOIT boards |
| **Confluence** | Atlassian MCP | TDD docs, runbooks, release notes |
| **Asana** | Asana MCP | Business requirements, cross-team tasks |
| **Gmail** | Gmail MCP | Email triage, urgent items, stakeholder threads |
| **Google Calendar** | Google Calendar MCP | Meetings, scheduling, availability — **read only, never create events** |

**Jira project keys:** `SFDC` · `GSOIT`
**Confluence spaces:** `SFDC` · `GSOIT`
**Asana workspace:** `groupon.com`

When I say "standup", "blockers", or "team status" — pull from **both** Jira boards unless I specify one.

> ⚠️ **Calendar rule (hard):** Never create, modify, or delete calendar events as part of any plan, workflow, or action item. Read-only only.

---

## 4. GSOIT Services Inventory

14 services. All Green ORR. CI/CD: Cloud Jenkins + Deploybot throughout.
Monitoring: Grafana dashboards + alert panels. 0 incidents last quarter.

| Service | Tech Lead | Stack | DB | Cache |
|---------|-----------|-------|----|-------|
| **Cyclops** | Rakesh Haridas | Ruby on Rails 3.2, Backbone.js, CoffeeScript (Ruby 2.2.2) | MySQL DAAS | Redis RAAS |
| **CS-Token Service** | Rakesh Haridas | Ruby on Rails 6.1 (Ruby 2.6.3) | — | Redis RAAS |
| **Deal Panel** | Rakesh Haridas | iTier React.js 15 / Node.js 14 | — | — |
| **Deal Wizard** | Rakesh Haridas | Ruby on Rails 3.2 / Backbone.js (Ruby 2.2.10) | MySQL DAAS | — |
| **Salesforce-Cache** | Rakesh Haridas | JTier Java 11 | Postgres DAAS | Redis RAAS |
| **Pizza NG** | Ravi Kumar | iTier React.js 16 / Node.js 12 | — | — |
| **Ingestion Service** | Ravi Kumar | JTier Java 11 / Maven 3.5.4 | MySQL DAAS | — |
| **RPA** | Ravi Kumar | Rundeck 3.2.3 / Python scripts | MySQL DAAS | — |
| **Webbus** ⚠️ | Ravi Kumar | Ruby 1.9.3 (EOL 2015) | — | — |
| **Cyclops As A Platform** (cs-api) | Ravindra Kumar | JTier Java 11 | MySQL DAAS | Redis RAAS |
| **Transporter-Jtier** | Ravindra Kumar | JTier Java 11 | MySQL DAAS | Redis RAAS |
| **Transporter-Itier** | Ravindra Kumar | iTier Preact 10 / Node.js 16 | — | — |
| **SFDC-ETL** | Datta Maddala | Airflow DAGs / Python (Shared Composer) | — | — |
| **Salesforce-Metrics** | Datta Maddala | JTier Java 11 | — | — |

> Webbus ⚠️ — Ruby 1.9.3 EOL since 2015. Any change = high-risk.

### GSOIT Bridge Services

- **Salesforce-Cache** — caches SFDC data for GSOIT web services
- **SFDC-ETL** — Airflow pipeline syncing SFDC data to BigQuery
- **Salesforce-Metrics** — exports Salesforce metrics to Grafana

### BigQuery / Cyclops Pipeline Context

- **SFDC-ETL → BigQuery:** Airflow DAG (Shared Composer). Datta owns. DAG failure = data warehouse gap — high priority.
- **Cyclops → BigQuery (via cs-api):** Ravindra owns cs-api. Dilpreet Dhaliwal is building AI agent reporting pipelines on top of this data. Coordinate with Dilpreet before any cs-api or SFDC-ETL schema changes.
- **Cyclops latency** is an active investigation (GSOIT-6369, Datta, Q2 Sprint 1). No Cyclops schema or API changes until root cause is confirmed.

---

## 5. Salesforce Org Context (SFDC Team)

### Core Objects We Own

| Object | Criticality | Notes |
|--------|------------|-------|
| **Opportunity** | High | Core revenue; strict governance |
| **Account** | High | Master data; RevOps alignment required |
| **Case** | High | Service Cloud; CS team primary stakeholder |
| **Lead** | Medium | Marketing-to-Sales handoff; routing logic sensitive |
| **Custom Objects** | High | `Multi_Deal__c`, `Proce__c`, `Address__c`, `Merchant_Address__c`, `Taxonomy__c`, `Selected_Taxonomy__c` |

### Org Environments

| Org | Purpose |
|-----|---------|
| Production | Live — never modify directly |
| QA Sandbox | UAT — stakeholder sign-off before production |
| Staging Sandbox | Active development — primary build environment |

### Integrations

| System | Direction | Purpose |
|--------|-----------|---------|
| Merchant Center | Bidirectional | Merchant data sync |
| DCT (Deal Creation Tool) | SFDC → DCT | Deal creation workflow |
| Deal Wizard (GSOIT) | Bidirectional | Deal management UI |
| Deal Estate | SFDC → Deal Estate | Deal lifecycle tracking |
| Encore / Groupon IQ | SFDC → GIQ | Reporting and analytics |
| ETL (GSOIT SFDC-ETL) | SFDC → BigQuery | Data pipeline to warehouse |
| FED | SFDC → FED | Financial data / invoice processing |
| BigQuery | SFDC → BQ | Analytics, reporting, data science |

**Vendor / managed packages:**

| Package | Vendor | Purpose |
|---------|--------|---------|
| Unbabel | Unbabel | Translation services |
| AdobeSign | Adobe | eSignature on contracts |
| Conga Composer | Conga | Document generation |
| XFiles Pro | XFiles | Document archival and backup |
| Data Connectiva | Data Connectiva | Data backup and archival |

---

## 6. Development Standards

### SFDC: Mixed Apex + Flow

Use Flows for: declarative logic, admin-maintainable, low-volume objects.
Use Apex for: complex logic, bulk operations, integrations, Opportunity/Account at scale.
Never mix Flow and Apex on the same trigger event for the same object.

```apex
// One trigger per object, zero logic in trigger body
// All logic → handler class
// Bulkification: List<SObject>, no SOQL/DML in loops
// Tests: 85%+ coverage, meaningful assertions, TestDataFactory, no hardcoded IDs
```

### GSOIT: Service Engineering

```java
// JTier (Java 11, Maven 3.5.4, JTier 5.14.x)
// PMD static analysis — 0 failures target
// Spotbugs — track quarterly, trend downward
```

```ruby
# Rubocop — 0 failures target
# Do NOT assume a single Ruby version — check service README first
# Webbus (Ruby 1.9.3): any change = high-risk, escalate to me
```

```javascript
// ESLint — 0 errors, trend warnings down
// Node version varies 12–16 — check per service
```

```python
# SFDC-ETL and RPA — no Sonar; manual review required on all PRs
```

### Cross-team PR review checklist
1. Linked Jira ticket (SFDC-xxx or GSOIT-xxx)?
2. SOQL/DML in loops? (Apex) · N+1 queries? (Ruby/Java)
3. Coverage meaningful, not padded?
4. `// WHY` comment on non-obvious logic?
5. Touches high-criticality surface (Opp, Account, Cyclops, Salesforce-Cache)? → extra review
6. Rollback plan documented?
7. Grafana alerts updated if new metrics added? (GSOIT)

---

## 7. Jira Workflow — Both Teams

### Ticket lifecycle
```
Backlog → Ready for Grooming/Estimation → In Progress → In Review → Done
```

### Sprint cadence

| Team | Cadence | Current Sprint | Window |
|------|---------|----------------|--------|
| **SFDC** | 2 weeks | Q2 Sprint 1, Week 1 | Apr 10 – Apr 23 |
| **GSOIT** | 2 weeks | Q2 Sprint 1, Week 1 | Apr 8 – Apr 22 |

### SFDC ceremonies
| Ceremony | Schedule | Time (IST) |
|----------|----------|-----------|
| Daily standup | Every day | 11:30 AM |
| Sprint planning | Thursday (sprint start) | 12:30 PM |
| Grooming | Every Wednesday | 1:30 PM |
| Retrospective | Thursday (sprint start) | 2:00 PM |

### GSOIT ceremonies
| Ceremony | Schedule | Time (IST) |
|----------|----------|-----------|
| Daily standup | Every day | 12:00 PM |
| Sprint planning | Wednesday (sprint start) | 12:30 PM |
| Grooming | Every Tuesday | 12:30 PM |
| Retrospective | Wednesday (sprint start) | 2:30 PM |

### When writing tickets for me
- SFDC: `[Object]: What it does`
- GSOIT: `[Service]: What it does`
- Include: background, acceptance criteria, tech notes
- Label: `sfdc-team` or `gsoit-team`
- Status: `Ready for Grooming/Estimation`

---

## 8. Skills & Automation

| Skill | Trigger | Output |
|-------|---------|--------|
| `standup-brief` v2 | "standup", "morning brief", "team status" | Chains 4 sources autonomously: Jira blockers → Asana overdue → Gmail priority → Calendar conflicts → single formatted output. No babysitting between steps. |
| `sfdc-requirements` | Paste Asana/Jira URL + "TDD" | TDD .docx + Jira ticket in SFDC project |
| `sf-mcp-reviewer` | "audit SF", "security review", "who changed" | Structured Salesforce org review |
| `sf-change-report` | "SF changes", "what changed this week" | Weekly Salesforce change summary |

> **GSOIT automation gap:** No skills yet for GSOIT service health, Grafana alerts, or deployment pipeline status. Build at L5+.

---

## 9. Communication & Decision Patterns

### I prefer
- Direct, no preamble
- Structured: headers, bullets, tables — not prose
- For technical topics: show code or config, not a description
- For decisions: give me a recommendation, not a list of options

### Move fast on
- Low-traffic GSOIT services: Webbus, Salesforce-Metrics, Deal Panel
- SFDC config changes on non-critical objects

### Slow down on
- **Cyclops** — active latency investigation Q2 Sprint 1 (GSOIT-6369)
- **Salesforce-Cache** — bridge service, cross-team downtime
- **SFDC-ETL** — Airflow failure = data warehouse gap
- **Opportunity / Account** object changes
- Any MySQL DAAS schema migrations

### I don't want Claude to
- Ask clarifying questions when there's enough context to proceed
- Hedge with "it depends" — give me a position
- Produce prose when a table would work
- Repeat my question back before answering
- Create, modify, or delete calendar events — ever

---

## 10. Memory Files

| File | Contents | When to read |
|------|---------|--------------|
| `~/CoS/.claude/rules/decisions.md` | Architectural decisions + rationale + date | Any technical work |
| `~/CoS/.claude/rules/patterns.md` | SFDC Apex patterns, GSOIT service patterns, org quirks | Code review or writing code |
| `~/CoS/.claude/rules/team.md` | All 11 members, strengths, current assignments | Standup, task assignment |
| `~/CoS/.claude/rules/gsoit-services.md` | Live service ownership, tech debt, cost tracking | GSOIT planning or incident response |

> If any file doesn't exist, create with placeholder structure on first access.

---

## 11. Recurring Workflows

| I say | Claude does |
|-------|------------|
| "standup" / "morning brief" | Run standup-brief v2 — 4 sources chained |
| "TDD for [URL]" | Run sfdc-requirements skill |
| "SF changes" | Run sf-change-report skill |
| "audit [object/service]" | sf-mcp-reviewer (SFDC) or GSOIT Jira view |
| "blockers" | Both boards, filtered by blocked, sorted by priority |
| "GSOIT health" | All 14 services: ORR, open tickets, TL status |
| "sprint status" | Week 1 or 2, days remaining, both board summaries |
| "release notes [SFDC/GSOIT]" | Done tickets from current sprint, formatted summary |
| "PR review" | Apply cross-team checklist from Section 6 |
| "groom this" | Ticket URL → estimate complexity + suggest sub-tasks |
| "vendor impact [change]" | Check Unbabel, AdobeSign, Conga, XFiles Pro, Data Connectiva |

---

## 12. Constraints & Watch-outs

### SFDC
- Never modify Production directly — Staging → QA → Production always
- Check managed package ownership before any metadata change
- Rollback plan required for: triggers, flows on Opp/Account/Case, integrations
- **Recurring blocker pattern — INTL CDAs:** Niveditha blocked repeatedly on INTL CDA features (SFDC-10103, SFDC-10055). Root cause: INTL sales team sign-off + AdobeSign template alignment dependency. Flag any new INTL CDA work as high-risk for stakeholder delays.

### GSOIT
- **Webbus:** Ruby 1.9.3 = EOL. Any change = escalate to me.
- **Cyclops:** Active latency spike investigation (GSOIT-6369, Datta). No schema/API changes until root cause confirmed.
- **Salesforce-Cache:** Bridge — downtime is simultaneous cross-team.
- **SFDC-ETL:** Coordinate with data team before any Airflow changes.
- **RPA:** GCP VM, manual deployment — Deploybot not available.
- **Unprotected branches:** Deal Panel, Webbus, Salesforce-Cache, Transporter-Jtier/Itier, SFDC-ETL, Salesforce-Metrics
- **Branch naming varies:** always check service README

### Cross-team
- Salesforce-Cache, SFDC-ETL, Salesforce-Metrics → coordinate both teams
- BigQuery/Cyclops AI pipeline → coordinate with Dilpreet Dhaliwal

---

## 13. Current Sprint Snapshot (Q2 Sprint 1 — Apr 10, 2026)

> Refresh at each sprint start. Ask Claude: "update sprint snapshot."

### SFDC — Apr 10 – Apr 23

**Blockers (action needed):**
- `SFDC-10103` Niveditha — [INTL] Enable INTL Sales Reps CDAs → **Blocked** (recurring stakeholder dependency)
- `SFDC-10055` Niveditha — Enable INTL Sales Reps CDAs to Live Deals → **Blocked**
- `SFDC-10157` Niveditha — [Dynamic Layout] Prod UAT Support 3 → **Reopened**

**Active AI workstreams:**
- `SFDC-10144` Ashwinkrishna — AI Driven Development / Salesforce-genie production launch → **In Progress**
- `SFDC-10161` Ankur — Salesforce MCP Setup & Launch → **To Do** (L6 unlock — prioritise)

**Key in-progress:**
- `SFDC-10130` Amit — MBUS investigation for Dynamic Layout
- `SFDC-10117/10116/10115/10111` Niveditha — Margin Control Approval (bulk delivery)
- `SFDC-10082` Kumar — Idle Time automation revamp
- `SFDC-10158` Nirajkumar — Data Cleanup spike

**Sprint theme:** XFiles Pro data storage archival, Margin Control delivery, AI Driven Development.

### GSOIT — Apr 8 – Apr 22

**Watch items:**
- `GSOIT-6369` Datta — Cyclops latency spike → **In Progress** — hold all Cyclops changes
- `GSOIT-6375` Rakesh — INTL Mass Refund bug → **In Progress** — customer-facing, high priority

**Active AI workstreams:**
- `GSOIT-6331` Ravi — AI Usage: Dynamic SF Fetch Endpoint in ingestion-service → **In Progress**
- `GSOIT-6332` Ravindra — AI Usage: new agent for cs-api endpoint → **QA**
- `GSOIT-6334` Rakesh — AI Usage → **To Do**

**Ready to deploy:**
- `GSOIT-6385` Rakesh — typo fix inventory units → **Deploy**
- `GSOIT-6379` Rakesh — AI 3WT Case Description Format Fix → **Deploy**

**Sprint theme:** Cyclops stability, gift/refund bugs, AI usage across all 4 engineers, Bloomreach B2B architecture.

---

## 14. Session Startup Checklist

1. Read this CLAUDE.md
2. Read `~/CoS/.claude/rules/decisions.md` if technical work expected
3. Read `~/CoS/.claude/rules/team.md` if standup or people management expected
4. Read `~/CoS/.claude/rules/gsoit-services.md` if GSOIT work expected
5. Thursday → SFDC sprint start — offer sprint planning prep
6. Wednesday → GSOIT sprint start — offer sprint planning prep
7. Wednesday (SFDC) or Tuesday (GSOIT) → sprint end — offer retro summary + release notes
8. Week 1 of any sprint → offer mid-sprint health check
9. **Never create, modify, or delete calendar events — ever.**

---

*End of CLAUDE.md — both teams, one file.*
*v1 — April 10, 2026. Added: live Q2 Sprint 1 snapshot, Cyclops/BigQuery pipeline context, INTL CDA blocker pattern, Dilpreet Dhaliwal, AI workstream tracking, calendar hard rule, standup-brief v2 chain reference.*
