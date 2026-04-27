# decisions.md — Architectural Decisions
> Read when doing technical work, code review, or architecture sessions.
> Last updated: April 24, 2026

---

## SFDC Decisions

### D-001 — One trigger per object, handler class mandatory
- **Date:** Pre-2026 (standing rule)
- **Decision:** Single trigger per Salesforce object. All logic in handler class. Zero logic in trigger body.
- **Rationale:** Governor limit management, testability, maintainability.
- **Status:** Active — enforced in all PR reviews.

### D-002 — Bulkification required on all Apex
- **Date:** Pre-2026 (standing rule)
- **Decision:** No SOQL or DML inside loops. Collections only. All Apex must handle 200-record batches.
- **Rationale:** Governor limits — single-record code fails in bulk triggers.
- **Status:** Active — PR checklist item.

### D-003 — Flow vs Apex selection criteria
- **Date:** Pre-2026
- **Decision:** Use Flows for declarative logic, admin-maintainable rules, low-volume objects. Use Apex for: complex logic, bulk operations, integrations, Opportunity/Account at scale. Never mix Flow and Apex on the same trigger event for the same object.
- **Rationale:** Conflicting automations on the same object cause production errors (baseline: 150+ error cases Q4 2025).
- **Status:** Active.

### D-004 — Staging → QA Sandbox → Production always
- **Date:** Pre-2026
- **Decision:** Never modify Production directly. Every change: Staging → QA Sandbox UAT → Production.
- **Rationale:** Live org — any error = customer/revenue impact.
- **Status:** Hard rule — no exceptions.

### D-005 — Named Credentials for all external callouts
- **Date:** Pre-2026
- **Decision:** All external system callouts (Merchant Center, DCT, GIQ, ETL, etc.) must use Named Credentials. No hardcoded credentials in Apex.
- **Rationale:** Security, rotation management, sandbox portability.
- **Status:** Active.

### D-006 — Test coverage 85%+ with meaningful assertions
- **Date:** Pre-2026
- **Decision:** 85% minimum coverage. Tests must use TestDataFactory. No hardcoded IDs. Assertions must verify business logic, not just coverage.
- **Rationale:** Padded tests that hit coverage but don't assert logic provide false confidence.
- **Status:** Active — PR checklist item.

### D-007 — Rollback plan required for high-risk changes
- **Date:** Pre-2026
- **Decision:** Any trigger, flow, or integration change touching Opportunity, Account, Case, or Salesforce-Cache requires a documented rollback plan before deployment.
- **Rationale:** Production failures on these objects = immediate revenue/customer impact.
- **Status:** Active.

### D-008 — Declarative Automations Migration: Flows + Apex only
- **Date:** Q2 2026
- **Decision:** Migrate all Workflow Rules and Process Builders to Flows or Apex triggers. Target: 0 active WF Rules/Process Builders by Dec 2026. (BET QR-1612)
- **Rationale:** ~750 WF Rules/Process Builders active — overlapping logic causing 150+ production errors per quarter. Flows are the Salesforce strategic path.
- **Current state:** Impact analysis completed for Accounts, Opportunities, Multideals, Cases (Niveditha, Apr 2026). Jira tickets created for each migration stream.
- **Risk:** Scope is large — phased delivery. Do not attempt bulk migration without per-object UAT.
- **Status:** Active — in delivery Q2 2026.

### D-009 — Scheduled Apex job limit — hard cap at 75
- **Date:** Apr 2026
- **Decision:** No new Scheduled Apex jobs until total count is below 75. Current state: 96/100 (critical). Hard limit is 100 — four new jobs away from blocking all future development.
- **Rationale:** 100 is a hard governor limit — cannot be increased. Cleanup (BET QR-1612) must reduce this.
- **Status:** Active blocker — engineering team aware.

### D-010 — XFiles Pro archival: coordinate before any Case file operations
- **Date:** Q1 2026
- **Decision:** All file archival jobs on Case object must be coordinated with XFiles Pro vendor and scheduled through the archival pipeline. No ad-hoc file deletions.
- **Rationale:** File storage at 89% (17.9 TB / 20 TB) — $112/mo current overage, trending to multiple TB without archival.
- **Current state:** XFiles Pro vendor connection error under resolution (Apr 2026). Archival jobs to be scheduled once vendor confirms fix. No manual deletions in the interim.
- **Status:** Active.

### D-011 — Managed package changes require owner check first
- **Date:** Pre-2026
- **Decision:** Before modifying any metadata that a managed package owns or references (Unbabel, AdobeSign, Conga Composer, XFiles Pro, Data Connectiva), check package ownership. Never override managed package logic without vendor sign-off.
- **Rationale:** Managed package upgrades can overwrite changes; conflicts cause deployment failures.
- **Status:** Active.

### D-012 — INTL CDA pattern — always flag as high-risk for stakeholder delays
- **Date:** Q1 2026
- **Decision:** Any new INTL CDA feature (International CDA agreements) must be flagged as high-risk for stakeholder delays from sprint planning. Recurring blocker pattern.
- **Rationale:** SFDC-10103 and SFDC-10055 were blocked for multiple sprints due to INTL sales team sign-off + AdobeSign template alignment. Root cause is stakeholder dependency, not engineering.
- **Status:** Active pattern recognition.

---

## GSOIT Decisions

### D-013 — Webbus: any change = escalate to EM
- **Date:** Pre-2026
- **Decision:** Webbus (Ruby 1.9.3, EOL since 2015) — any code change, however small, must be escalated to Ankur before starting.
- **Rationale:** EOL runtime. No security patches. Breaking change risk is extremely high.
- **Status:** Hard rule.

### D-014 — Cyclops: no schema/API changes until latency root cause resolved
- **Date:** Q2 2026
- **Decision:** No Cyclops schema changes, no cs-api endpoint modifications until GSOIT-6369 Cyclops latency spike is resolved and root cause confirmed.
- **Rationale:** Active latency investigation — schema changes would confound root cause analysis and potentially worsen production performance.
- **Current state:** GSOIT-6427 (Cyclops/cs-api latency fix proposals) in progress. Datta and Ravindra. Fix to be staging-verified before production.
- **Status:** Active hold — do not clear until GSOIT-6427 resolved.

### D-015 — Salesforce-Cache: downtime = simultaneous cross-team impact
- **Date:** Pre-2026
- **Decision:** Any Salesforce-Cache deployment or maintenance must be coordinated with both SFDC and GSOIT teams simultaneously. No unilateral changes.
- **Rationale:** Bridge service — caches SFDC data for GSOIT web services. Downtime = both teams affected at once.
- **Status:** Active.

### D-016 — SFDC-ETL: coordinate with data team before Airflow changes
- **Date:** Pre-2026
- **Decision:** Any change to SFDC-ETL Airflow DAGs must be coordinated with Dilpreet Dhaliwal's team before starting. Schema changes require explicit sign-off.
- **Rationale:** DAG failure = data warehouse gap. Dilpreet's AI reporting pipelines depend on cs-api and SFDC-ETL schema stability.
- **Status:** Active.

### D-017 — cs-api minReplicas floor = 3
- **Date:** Apr 22, 2026 (post-incident)
- **Decision:** cs-api minimum replica count = 3 across all regions. Previously 2, which amplified a cluster-wide node event to customer-visible 503.
- **Rationale:** GSOIT-6455 incident: single node event briefly took all pods offline with 2-pod floor. 3-pod floor prevents this.
- **Engineer:** Ravi Kumar — deployed Apr 22, staging-verified, post-deploy Kibana clean.
- **Status:** Live in production.

### D-018 — ingestion-service mls-rin client timeout = 5s
- **Date:** Apr 22, 2026
- **Decision:** ingestion-service mls-rin client timeout reduced from 15s to 5s. Fail-fast on unhealthy calls.
- **Rationale:** Long timeout amplified degraded upstream into cascading delays. 5s fail-fast limits blast radius.
- **Engineer:** Ravi Kumar — deployed Apr 22, prod-verified.
- **Status:** Live in production.

### D-019 — Bloomreach contact router: priority logic stays on Groupon side
- **Date:** Apr 2026
- **Decision:** Contact selection priority logic (which merchants to contact) stays on Groupon side via the contact router being built in Encore. Bloomreach receives a priority flag (1/2/3) on the contact profile via daily import job — marketing can then filter/segment on it directly.
- **Rationale:** Keeps business logic centralised and auditable. Avoids Bloomreach-native logic that would be harder to change and test.
- **Current state:** Final architecture needs one more round with Bloomreach team.
- **Status:** Agreed in principle — finalisation pending.

### D-020 — Bloomreach business metrics feed: use Keith's core deal tables
- **Date:** Apr 2026
- **Decision:** Business metrics going into Bloomreach will use Keith Hayden's existing core deal tables (same ones used for Salesforce). No new pipelines will be built.
- **Rationale:** Avoids duplicating data infrastructure. Core deal tables already validated and production-grade.
- **Status:** Agreed — Kateryna to build requirements from this foundation.

### D-021 — Missing merchant UUIDs in Bloomreach: use placeholder, not failure
- **Date:** Apr 2026
- **Decision:** When a Bloomreach contact has no merchant assigned, use a placeholder UUID (agreed "Fake value") so workflows don't fail. Push marketing teams notified that empty merchant IDs are expected.
- **Rationale:** Blocking sends on missing IDs would break the entire pipeline during rollout.
- **Status:** Active — Kateryna to notify push marketing teams.

### D-022 — RPA: manual deployment — Deploybot not available
- **Date:** Pre-2026
- **Decision:** RPA service (GCP VM, Python scripts) requires manual deployment. Deploybot is not configured for this service.
- **Rationale:** Non-standard runtime — GCP VM, not standard JTier/iTier.
- **Status:** Active — note in any RPA deployment planning.

### D-023 — Unprotected branches: extra caution required
- **Date:** Pre-2026
- **Decision:** Services with unprotected branches (Deal Panel, Webbus, Salesforce-Cache, Transporter-Jtier/Itier, SFDC-ETL, Salesforce-Metrics) require extra PR review discipline. No direct pushes to main.
- **Status:** Active — always check service README for branch naming conventions.

---

## AI Infrastructure Decisions

### D-024 — TDD agent: event-driven polling every 4 hours
- **Date:** Apr 2026
- **Decision:** TDD watcher polls Jira every 4 hours (not 5 minutes) for new tickets in "Ready for Grooming/Estimation" sprint with status "To Do". Fires specialist agents per ticket in parallel.
- **Rationale:** 4-hour max latency acceptable for grooming tickets that typically sit for days. Reduces noise vs. 5-minute polling.
- **State file:** `~/CoS/logs/tdd/.tdd-state.json` — prevents double-processing.
- **Status:** Live. Cron: `0 */4 * * 1-5`

### D-025 — Jira API: POST to /rest/api/3/search/jql, use curl not urllib
- **Date:** Apr 2026
- **Decision:** Always use curl (via subprocess or shell) for Jira API calls, not Python urllib. Use POST to `/rest/api/3/search/jql`, not GET to `/rest/api/3/search`. Sprint field is `customfield_10105` (not `sprint` or `cf[10020]`).
- **Rationale:** Python 3.14 urllib sends different headers that Atlassian Cloud rejects with HTTP 410. Curl works correctly. Old `/rest/api/3/search` GET endpoint returns 410 Gone.
- **Auth:** `curl -u "$ATLASSIAN_EMAIL:$ATLASSIAN_TOKEN"` (Basic auth, not Bearer)
- **Status:** Active — all scripts use this pattern.

### D-026 — CoS repo structure
- **Date:** Apr 2026
- **Decision:** All automation lives under `~/CoS/projects/SFDC/scripts/`. Skills under `~/CoS/.claude/skills/`. Memory files under `~/CoS/.claude/rules/`. Logs in `~/CoS/logs/`. Knowledge base in `~/CoS/projects/SFDC/scripts/agents/knowledge/` (gitignored).
- **GitHub:** `github.com/ankurgoyal01/CoS` (private). ai-chatbot linked as git submodule.
- **Status:** Active.
