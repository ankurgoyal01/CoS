# decisions.md — Architectural & Technical Decisions Log
> Read when doing any technical work, code review, or design discussion.
> Last updated: April 17, 2026

---

## How to use this file

Each decision has:
- **Date** — when the decision was made
- **Decision** — what was decided
- **Rationale** — why
- **Status** — Active / Superseded / Under review
- **Do not re-open** — flag if this was a hard-fought decision

---

## SFDC Architecture Decisions

### APEX-001 — One trigger per object, handler pattern
- **Date:** Pre-Q2 2026 (standing convention)
- **Decision:** One trigger per object, zero logic in the trigger body. All logic lives in a handler class (e.g. `OpportunityTriggerHandler`).
- **Rationale:** Prevents trigger order conflicts, makes testing deterministic, avoids governor limit issues from stacked triggers.
- **Status:** Active
- **Do not re-open:** Yes — this is non-negotiable on Opportunity and Account.

### APEX-002 — Never mix Flow and Apex on same trigger event
- **Date:** Pre-Q2 2026 (standing convention)
- **Decision:** If Apex handles a trigger event (BeforeInsert, AfterUpdate etc.) on an object, no Flow should fire on the same event for the same object.
- **Rationale:** Unpredictable execution order, governor limit double-counting, debugging complexity.
- **Status:** Active

### APEX-003 — Bulkification always
- **Date:** Standing convention
- **Decision:** No SOQL or DML inside loops. Always use `List<SObject>` collections and bulk DML.
- **Rationale:** Salesforce governor limits. Single-record patterns fail in batch context.
- **Status:** Active

### SFDC-ENV-001 — Staging → QA → Production only
- **Date:** Standing convention
- **Decision:** All changes go Staging Sandbox → QA Sandbox → Production. Never modify Production directly.
- **Rationale:** Irreversible data loss risk. Stakeholder sign-off (UAT) required in QA before production push.
- **Status:** Active — enforced strictly

### SFDC-ENV-002 — Managed package components are read-only
- **Date:** Standing convention
- **Decision:** Components owned by Unbabel, AdobeSign, Conga Composer, XFiles Pro, or Data Connectiva cannot be modified. Work around them, never inside them.
- **Rationale:** Managed package upgrades will overwrite any changes. Support contracts require original configurations.
- **Status:** Active

### SFDC-INT-001 — Named Credentials for all callouts
- **Date:** Pre-Q2 2026
- **Decision:** All REST/SOAP callouts use Named Credentials, not hardcoded endpoints or custom settings.
- **Rationale:** Security (no credentials in code), flexibility (endpoint changes don't require deployment), consistent auth management.
- **Status:** Active

### SFDC-INT-002 — Deal Estate API not available for INTL (CDA flows)
- **Date:** Q1 2026 — discovered during SFDC-10055 investigation
- **Decision:** INTL CDA Deal Estate import cannot use the same API path as NAM. INTL region requires separate validation before triggering Deal Estate import.
- **Rationale:** API availability for INTL was the root cause of the recurring INTL CDA blocker (SFDC-10055, SFDC-10103). AdobeSign template for UK confirmed working in staging as of Apr 8.
- **Status:** Active — INTL CDAs now in QA (Apr 16)
- **Owner:** Niveditha

### SFDC-AI-001 — Salesforce-genie deployed via Google Workspace channel
- **Date:** April 2026
- **Decision:** Salesforce-genie AI assistant embedded in Salesforce-Engineering Google Chat channel, not as a Salesforce Lightning component.
- **Rationale:** Lower deployment complexity, no SF org metadata dependency, faster iteration. Chat channel reaches all users instantly.
- **Owner:** Ashwinkrishna
- **Status:** In Progress (SFDC-10144)

### SFDC-AI-002 — Salesforce MCP server hosted centrally on GCP, read-only
- **Date:** April 2026
- **Decision:** Salesforce MCP server deployed on GCP Cloud Run via Google Workspace SSO. Read-only mode enforced — no data writes. PII fields (email, phone, bank info) excluded from MCP tool responses.
- **Rationale:** Removes local setup burden for 100+ users. SSO eliminates individual API key management. Read-only prevents accidental data modification.
- **Owner:** Ankur
- **Status:** In Review (SFDC-10161)
- **Scale requirement:** Must support 500 concurrent users.

---

## GSOIT Architecture Decisions

### GSOIT-STACK-001 — Check service README before assuming Ruby/Node version
- **Date:** Standing convention
- **Decision:** Never assume a single Ruby or Node.js version across GSOIT services. Always check the service README first.
- **Rationale:** Versions range from Ruby 1.9.3 (Webbus, EOL) to Ruby 2.6.3 (CS-Token) to Node 12–16 across services.
- **Status:** Active

### GSOIT-STACK-002 — Webbus is high-risk, any change requires escalation
- **Date:** Standing convention
- **Decision:** Any change to Webbus requires explicit escalation to Ankur before proceeding. Do not merge without review.
- **Rationale:** Ruby 1.9.3 is EOL since 2015. No Rubocop coverage. Deployment is semi-manual. Failure impact unknown.
- **Status:** Active

### GSOIT-STACK-003 — RPA deployment is manual (not Deploybot)
- **Date:** Standing convention
- **Decision:** RPA service runs on a GCP VM, not in Conveyor Cloud. Deploybot is not available. Deployments require manual SSH + script execution.
- **Rationale:** RPA uses Rundeck 3.2.3 + Python scripts — not containerised.
- **Status:** Active — flag in any deployment planning involving RPA.

### GSOIT-BRANCH-001 — Unprotected branches list
- **Date:** Standing convention
- **Decision:** The following service repos have unprotected branches — extra caution required on merges: Deal Panel, Webbus, Salesforce-Cache, Transporter-Jtier, Transporter-Itier, SFDC-ETL, Salesforce-Metrics.
- **Status:** Active — do not auto-merge PRs in these repos without review.

### GSOIT-DB-001 — MySQL DAAS schema migrations require data team coordination
- **Date:** Standing convention
- **Decision:** Any MySQL DAAS schema migration across any GSOIT service must be coordinated with the data team before execution.
- **Rationale:** Shared DAAS environment — schema changes can affect other consumers. Rollback is complex.
- **Status:** Active

### GSOIT-ETL-001 — SFDC-ETL failures = data warehouse gap
- **Date:** Standing convention
- **Decision:** Any SFDC-ETL (Airflow) failure is treated as a P1 data issue. Coordinate with data team immediately.
- **Rationale:** SFDC-ETL is the only pipeline syncing Salesforce data to BigQuery. A gap in the pipeline = reporting failures, analytics blackout.
- **Status:** Active
- **Owner:** Datta Maddala

### GSOIT-CYCLOPS-001 — Cyclops latency spike: no schema/API changes until resolved
- **Date:** April 2026
- **Decision:** During the active Cyclops latency investigation (GSOIT-6369), no schema changes or API endpoint changes to Cyclops or cs-api are permitted without explicit sign-off from Datta + Ankur.
- **Rationale:** Latency root cause not yet confirmed as of Apr 16. Changes during investigation will corrupt the signal.
- **Owner:** Datta Maddala
- **Status:** Active — do not clear until GSOIT-6369 is resolved.

### GSOIT-BRIDGE-001 — Salesforce-Cache, SFDC-ETL, Salesforce-Metrics changes require cross-team coordination
- **Date:** Q1 2026
- **Decision:** Any change to the three bridge services (Salesforce-Cache, SFDC-ETL, Salesforce-Metrics) must be coordinated between SFDC and GSOIT teams. Ankur owns both sides.
- **Rationale:** These services are the interface between the two teams. Downtime in Salesforce-Cache = simultaneous outage for both SFDC and GSOIT workstreams.
- **Status:** Active

### GSOIT-AI-001 — BigQuery/Cyclops AI pipeline: coordinate with Dilpreet
- **Date:** April 2026
- **Decision:** Before any cs-api or SFDC-ETL schema change, coordinate with Dilpreet Dhaliwal. He is building AI agent reporting pipelines on top of BigQuery data sourced from Cyclops.
- **Rationale:** Schema change without coordination will break his data pipeline silently.
- **Status:** Active

---

## AI Setup Decisions (Personal / EM tooling)

### AI-001 — standup.sh uses Anthropic API key route, not Claude Code MCP OAuth
- **Date:** April 13, 2026
- **Decision:** `standup.sh` calls Claude Code via `claude -p` with MCP servers configured in `~/.claude/settings.json`. Asana is queried via REST API directly (PAT in header), not via MCP, due to Asana MCP OAuth limitations in headless mode.
- **Rationale:** GitHub Enterprise at `github.groupondev.com` uses Enterprise tokens, not github.com tokens. Asana MCP OAuth callback fails in headless/cron context.
- **Status:** Active

### AI-002 — GitHub stats use Enterprise API endpoint
- **Date:** April 14, 2026
- **Decision:** All GitHub API calls use `https://github.groupondev.com/api/v3`, not `https://api.github.com`. Tokens must be generated from `github.groupondev.com/settings/tokens`.
- **Rationale:** `groupondev` is a GitHub Enterprise Server instance, not a github.com org. Tokens are not interchangeable.
- **Status:** Active

### AI-003 — Claude Code MCP servers use OAuth for Atlassian/Gmail/GCal, PAT for Asana
- **Date:** April 2026
- **Decision:** `~/.claude/settings.json` configures Atlassian, Gmail, GCal via OAuth (no auth header) and Asana via PAT Bearer token in header.
- **Status:** Active

### AI-004 — Never create calendar events as part of any workflow
- **Date:** April 10, 2026
- **Decision:** Claude must never create, modify, or delete calendar events as part of any plan, script, skill, or workflow.
- **Rationale:** Explicit instruction. Calendar is read-only in all workflows.
- **Status:** Active — hard rule.
