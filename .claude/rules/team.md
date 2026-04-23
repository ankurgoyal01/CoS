# team.md — Ankur Goyal's Engineering Teams
> Read at session start when standup, task assignment, or people management is the topic.
> Last updated: April 23, 2026 — Q2 Sprint 2 start. Live Jira data stale (MCP OAuth expired).

---

## My Role

- **Name:** Ankur Goyal
- **Title:** Engineering Manager — SFDC + GSOIT
- **Manager:** Josef Sima
- **Location:** Bengaluru, India (IST, UTC+5:30)
- **Jira GID:** agoyal@groupon.com
- **Asana GID:** 1211542692184092

---

## SFDC Team — 7 members

Salesforce platform: Apex, LWC, Flows, Triggers, Sales Cloud, Service Cloud, integrations.

### Ashwinkrishna M
- **Role:** Senior Salesforce Developer
- **Strengths:** Apex, LWC, Sales Cloud, AI integrations
- **Current focus:** SFDC-10144 AI Driven Dev / Salesforce-genie production launch · SFDC-10137/10136 XFiles Pro archival jobs
- **GitHub:** `akrishnam`
- **Signal:** Strong Apex engineer, taking ownership of AI-in-SF workstream. Growing into AI-first development pattern.
- **Watch:** XFiles archival work spans multiple tickets — track for scope creep.

### Niveditha Ramegowda
- **Role:** Senior Salesforce Developer
- **Strengths:** Apex, LWC, Service Cloud, complex multi-object flows
- **Current focus:** SFDC-10103 + SFDC-10055 INTL CDA (now in QA — unblocked!) · SFDC-10157 Dynamic Layout UAT · SFDC-10185 Declarative Automations Migration spike
- **GitHub:** `niver`
- **Signal:** INTL CDA recurring blocker pattern finally moving to QA. High-quality delivery when unblocked. Depth in Service Cloud.
- **Watch:** Multiple concurrent tickets — prioritise Dynamic Layout UAT completion before new scope.
- **Note:** INTL CDA blockers (SFDC-10103, SFDC-10055) were a recurring pattern across Q1 — root cause was stakeholder sign-off dependency on AdobeSign templates, not engineering.

### Nirajkumar Shelke
- **Role:** Senior Salesforce Developer
- **Strengths:** Apex, Triggers, integrations, data cleanup
- **Current focus:** SFDC-10201 AI-driven Claude + CI/CD automation (Review) · SFDC-10173 Hierarchy Cleanup spike (Review) · SFDC-10158 Data Cleanup spike · SFDC-10138 Translation Request cleanup (QA)
- **GitHub:** `nshelke`
- **Signal:** SFDC-10201 is notable — building Claude + CI/CD automation end-to-end. Strongest signal of AI-first development on the SFDC team alongside Ashwinkrishna.
- **Watch:** SFDC-10201 should be showcased — it's exactly what Dusan's Foundry scanner values.

### Kumar Ankit
- **Role:** Senior Salesforce Developer
- **Strengths:** Apex, LWC, Sales Cloud, Account Skew
- **Current focus:** SFDC-10082 Idle Time automation revamp (QA) · SFDC-10077 Account Skew sharing rules cleanup · SFDC-9169 Cross-reference validation (Blocked)
- **GitHub:** `kankit`
- **Signal:** Solid delivery. SFDC-9169 is blocked — needs investigation on cross-reference validation root cause.
- **Watch:** Account Skew work (SFDC-10077/9) is low-profile but high business value — flag for sprint review visibility.

### Amit Patil
- **Role:** Senior Salesforce Developer
- **Strengths:** Apex, Flows, Service Cloud, escalation logic, OCR
- **Current focus:** SFDC-10186 Escalation Visibility Logic · SFDC-10089 AI Content Generation in Vetted stage (Deploy — ready!) · SFDC-9973 OCR for ContentOps UAT support
- **GitHub:** `amipatil`
- **Signal:** SFDC-10089 is ready to deploy. OCR work (SFDC-9973) has cross-team dependency on ContentOps.
- **Watch:** SFDC-10089 deploy needs sign-off today — it's been sitting at Deploy status.

### Srilakshmi K S
- **Role:** Salesforce Administrator
- **Strengths:** Config, reports, dashboards, data ops, support case management
- **Current focus:** SFDC-10156/10155 Support cases management (In Progress + QA)
- **GitHub:** N/A (admin, non-coding)
- **Signal:** Steady admin delivery. Support case management is a sprint constant.

### Utkarsh Pathak
- **Role:** Salesforce Administrator
- **Strengths:** Config, automation, deployments, AdobeSign template management
- **Current focus:** SFDC-10169/10168/10167/10166/10165 Support cases management (multiple In Progress + QA)
- **GitHub:** N/A (admin, non-coding)
- **Signal:** High volume of support case tickets — consistently delivering. NA contract template work (SFDC-10178) completed last week.

---

## GSOIT Team — 4 members

Web services: Java, Ruby on Rails, Node.js, Python. 14 services total.

> I took over GSOIT from Vijayamoorthy R. Tech lead assignments updated — services report not yet reflecting new owners.

### Ravi Kumar
- **Role:** Principal Developer
- **Strengths:** Full-stack, Pizza NG, Ingestion Service, RPA, Webbus, AI integrations
- **Services:** Pizza NG, Ingestion Service, RPA, Webbus
- **Current focus:** GSOIT-6331 AI Usage / Dynamic SF Fetch Endpoint in ingestion-service (In Progress)
- **GitHub:** `kumarra`
- **Performance trend:** Strong Q1 2026 surge — 53 PRs, growing repo footprint. AI-first work on SF fetch endpoint is high-value.
- **Signal:** Most versatile engineer in GSOIT. Candidate for tech lead pathway Q2. AI usage ticket is a high-visibility deliverable.
- **Watch:** Webbus (Ruby 1.9.3 EOL) — any change here is high-risk. Escalate immediately.

### Rakesh Haridas
- **Role:** Senior Developer
- **Strengths:** Backend API (cs-api), Cyclops, SSR, refund flows, chatbot integrations
- **Services:** Cyclops, CS-Token Service, Deal Panel, Deal Wizard, Salesforce-Cache
- **Current focus:** GSOIT-6404 Delayed Refund prod verification (QA) · GSOIT-6391 Merchant case creation endpoint (Reopened) · GSOIT-6388 SSR Mass Refund monitoring · GSOIT-6372 Merchant bot stop/pause deal (QA) · GSOIT-6356 SSR fields in custom-data · GSOIT-6223 E-Gift card redemption
- **GitHub:** `rharidas`
- **Performance trend:** Highest Q3 PR count (54). Q1 dip — monitor Q2 velocity. Review activity strong.
- **Signal:** High breadth across customer-facing services. GSOIT-6391 Reopened needs attention.
- **Watch:** GSOIT-6391 reopened — understand root cause before it gets reopened again.

### Datta Maddala
- **Role:** Senior Developer
- **Strengths:** Full-stack, Salesforce ETL, Airflow, Bloomreach B2B, metrics
- **Services:** SFDC-ETL, Salesforce-Metrics
- **Current focus:** GSOIT-6407 BR to Salesforce Email Notification Logging spike · GSOIT-6369 Cyclops Latency spike investigation · GSOIT-6358 Giftee refund via Cyclops bot · GSOIT-6349 Gift Recipient Cyclops Issue (QA) · GSOIT-6121 Merchant email alerts investigation
- **GitHub:** `dmaddala`
- **Performance trend:** Highest total reviews (165 across 3 quarters). Consistent quality. Q1 push on Bloomreach B2B integration.
- **Signal:** Cyclops latency investigation (GSOIT-6369) ongoing — do not clear until root cause confirmed. High review engagement = knowledge hub.
- **Watch:** GSOIT-6369 Cyclops latency — no schema/API changes until resolved.

### Ravindra Kumar
- **Role:** Senior Developer
- **Strengths:** Full-stack + Infrastructure, Help Center rollout, routing, cs-api
- **Services:** Cyclops As A Platform (cs-api), Transporter-Jtier, Transporter-Itier
- **Current focus:** GSOIT-6378 Post-Refund Deal Recommendations cs-api endpoint (Review) · GSOIT-6362 Email Dashboard tab Reopened · GSOIT-6305 Pre-purchase data pipeline spike
- **GitHub:** `ravikumar`
- **Performance trend:** Standout growth — 42 → 48 → 55 PRs Q3→Q4→Q1. Widest repo footprint (18+). Strong Q2 candidate for platform ownership.
- **Signal:** GSOIT-6378 in Review — high-value endpoint for post-refund recommendations. GSOIT-6362 Reopened.
- **Note:** Building AI agent for cs-api (GSOIT-6332 completed QA last week). Active on Unified Customer Profile hackathon (GSOIT-6395).

---

## Key Stakeholders

| Name | Role | Primary interaction |
|------|------|-------------------|
| Dennis Bertelkamp | Product Owner (SP) | GSOIT services — primary PO |
| Michal Jilka | Product Owner (SP) | Cyclops, CS-Token, Unified Customer Profile |
| Chris Hill | RevOps Lead | SFDC requirements, Opportunity governance |
| Maciej Kołodziej | Sales Ops | Opportunity & Lead process owner |
| Veronika Zapletalova | Merchant Support Lead | Merchant-facing processes |
| Samuel Garcia Rio | Customer Support Lead | Service Cloud, Case escalations |
| Zeph Buck | CommOps | Commercial Operations |
| Dilpreet Dhaliwal | Cross-functional | AI automation testing — SF field reports, Cyclops/BigQuery |

---

## Current Sprint Snapshot (Q2 Sprint 2)

**SFDC:** Apr 23 – May 6 · **GSOIT:** Apr 23 – May 6
> Last updated: Apr 23, 2026. Live Jira data not pulled (Atlassian MCP OAuth needs refresh — run `/mcp` to reconnect, then ask "update sprint snapshot").

### Carry-over watch items (from Q2 Sprint 1 — confirm status in new sprint)
- `SFDC-9169` Kumar — cross-reference validation — was Blocked, confirm if resolved or carried over
- `GSOIT-6369` Datta — Cyclops latency spike — was In Progress, **do not clear until root cause confirmed**
- `GSOIT-6391` Rakesh — merchant case creation endpoint — was Reopened
- `GSOIT-6362` Ravindra — Email Dashboard tab — was Reopened

### Q2 Sprint 1 notable completions (verify Done status)
- `SFDC-10103 + 10055` Niveditha — INTL CDAs reached QA
- `SFDC-10201` Nirajkumar — Claude + CI/CD automation was In Review
- `SFDC-10161` Ankur — Salesforce MCP Setup was In Review
- `GSOIT-6332` Ravindra — AI agent for cs-api was in QA
- `GSOIT-6385 + 6379` Rakesh — typo fix + AI Case Format Fix were Deploy-ready

### AI workstreams — carry into Sprint 2
- `SFDC-10144` Ashwinkrishna — Salesforce-genie (was In Progress)
- `SFDC-10161` Ankur — SF MCP Setup (was In Review — highest priority for L6 unlock)
- `SFDC-10201` Nirajkumar — Claude + CI/CD automation (was In Review)
- `GSOIT-6331` Ravi — Dynamic SF Fetch endpoint (was In Progress)
- `GSOIT-6395` Michal/team — Unified Customer Profile hackathon (was In Progress)

---

## Assignment patterns

- **High-complexity Apex + integrations:** Niveditha, Ashwinkrishna, Nirajkumar
- **Sales Cloud / Account objects:** Kumar Ankit, Amit Patil
- **Service Cloud / Cases:** Niveditha, Srilakshmi
- **Admin + deployments:** Utkarsh, Srilakshmi
- **GSOIT backend (cs-api, refunds, chatbot):** Rakesh, Ravindra
- **GSOIT data pipelines + ETL:** Datta
- **GSOIT frontend + mobile:** Ravi Kumar
- **AI workstreams:** Ashwinkrishna, Nirajkumar, Ravi Kumar, Ravindra
