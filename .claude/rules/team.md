# team.md — Ankur Goyal's Engineering Teams
> Read at session start when standup, task assignment, or people management is the topic.
> Last updated: April 24, 2026 — Q2 Sprint 2, Week 1

---

## My Role

- **Name:** Ankur Goyal
- **Title:** Engineering Manager — SFDC + GSOIT
- **Manager:** Josef Sima
- **Location:** Bengaluru, India (IST, UTC+5:30)
- **Jira:** agoyal@groupon.com
- **GitHub handle:** `agoyal`
- **Asana GID:** 1211542692184092
- **AI Maturity:** L8 confirmed Apr 22, 2026

---

## SFDC Team — 7 members

### Ashwinkrishna M
- **Role:** Senior Salesforce Developer · **AI Maturity:** L3
- **BET:** QR-1612 (SF Cleanup — XFiles Pro archival)
- **Q2 Sprint 2 focus:** SFDC-10243 Automated emails for MO contacts spike · SFDC-10221 sf-bot auto-invoke @jarvis→@sf-bot
- **Signal:** Set up Salesforce MCP server for Google Workspace — one-click installer, Claude Desktop + Groupon Google auth. Unblocks team-wide MCP adoption. Used Claude Code to prototype @jarvis→@sf-bot listener.
- **GitHub:** `akrishnam`
- **Watch:** SFDC-10136 XFiles Pro archival blocked on vendor connection error. Need date commitment from vendor by Apr 29. If none, escalate through procurement.
- **Path to L4:** Context engineering — memory files, deliberate prompt patterns. Discuss in 1:1.

### Niveditha Ramegowda
- **Role:** Senior Salesforce Developer · **AI Maturity:** L2
- **BET:** QR-1624 (Margin Control)
- **Q2 Sprint 2 focus:** Margin Control UAT · INTL CDA UK add-option amendment testing · Declarative Automations Migration
- **Signal:** Dynamic Layout UAT completed — all concerns resolved. Declarative Automations analysis done across 4 objects with Claude export. All tickets closed on time.
- **GitHub:** `niver`
- **Watch:** 5/15 AI Signal needs specificity — ticket + outcome + time saved, not just "using AI." SFDC-8143 catch-all needs individual Jira links per item.
- **Note:** INTL CDA (SFDC-10103/10055) resolved Q2 Sprint 1. Root cause: AdobeSign template + stakeholder sign-off dependency, not engineering.

### Nirajkumar Shelke
- **Role:** Senior Salesforce Developer · **AI Maturity:** L4 → L5
- **BET:** QR-1612 (SF Cleanup — data storage, automations), QR-1658 (PoF EMEA — Salesforce side)
- **Q2 Sprint 2 focus:** SFDC-10242 Automated memos creation spike · PoF EMEA QA + UAT handover · XFiles Pro archival connection resolution
- **Signal:** Best AI delivery on SFDC this week — 63 GB storage freed (25M records), pre-PR code review skill added as pre-flight before sf-pr-creation agent, ~50% spike time reduction with sf-project-planner. Led team meta-repo onboarding. PoF EMEA SF-side deployed to staging.
- **GitHub:** `nshelke`
- **Action:** 30-min sync with Amit this week — SFDC-10242 (automated memos) and SFDC-10243 (automated emails) are same pattern. Build one shared skill.
- **Path to L5:** Orchestration already demonstrated. Set specific L5 target in next 1:1.

### Kumar Ankit
- **Role:** Senior Salesforce Developer · **AI Maturity:** L2
- **BET:** QR-1612 (SF Cleanup — cross-reference validation)
- **Q2 Sprint 2 focus:** Post SFDC-9169 resolution work
- **Signal:** SFDC-9169 cross-reference validation Done this week after multiple sprint blockage.
- **GitHub:** `kankit`

### Amit Patil
- **Role:** Senior Salesforce Developer · **AI Maturity:** L2 → L3
- **BET:** QR-1624 (Margin Control), QR-1614 (Customer AI Agent — OCR/ContentOps)
- **Q2 Sprint 2 focus:** SFDC-10236 Margin Control pop-up notification (Apr 29) · SFDC-10241 Margin Control UAT + prod readiness · SFDC-9974 OCR ContentOps (carry-over) · SFDC-10170 (Apr 30)
- **Signal:** 2 prod deployments (SFDC-10200, SFDC-9568). Using Claude for end-to-end development on all tickets.
- **GitHub:** `amipatil`
- **Watch:** SFDC-9974 carry-over now 2 weeks — written deadline to ContentOps stakeholder Monday. Escalate to EM if no response Wednesday. 5/15 suggestions section must have one concrete item next week.
- **Action:** 30-min sync with Nirajkumar — automated emails (SFDC-10243) and automated memos (SFDC-10242) are same pattern, build shared skill.

### Srilakshmi K S
- **Role:** Salesforce Administrator · **AI Maturity:** L1
- **BET:** KTLO / Support
- **GitHub:** N/A (admin, non-coding)
- **Note:** 5/15 not submitted week of Apr 20–24. Follow up.

### Utkarsh Pathak
- **Role:** Salesforce Administrator · **AI Maturity:** L2 → L3
- **BET:** KTLO / Support
- **Q2 Sprint 2 focus:** SFDC-10218 Spam Button on CTSR cases · SFDC-10219 Call duration automation
- **Signal:** Built complete Apex solution end-to-end with Claude — triggers, handlers, email notifications, approval workflows, exception handling, test classes. Used SF chatbot for SOQL debugging and bulk ID lookups. L2→L3 progression in practice.
- **GitHub:** N/A (admin, non-coding)
- **Watch:** 5/15 priorities, top achievement, and suggestions all blank this week. Coached. Expect improvement.

---

## GSOIT Team — 4 members

Web services: Java, Ruby on Rails, Node.js, Python. 14 services.

### Ravi Kumar
- **Role:** Principal Developer · **AI Maturity:** L4 → L5
- **BET:** QR-1631 (Merchant Lifecycle — cs-api, Ingestion Service)
- **Services:** Pizza NG, Ingestion Service, RPA, Webbus
- **Q2 Sprint 2 focus:** GSOIT-6291 Lazlo retry (in review) · GSOIT-6382 Escalation Approver webhook (in review) · GSOIT-6455 cs-api 503 follow-ups · SFDC-9909 EchoSign (carry-over, new scope)
- **Signal:** Best 5/15 on the team. cs-api 503: root-caused → minReplicas 2→3 all regions → mls-rin timeout 15s→5s — all within the week. Opus caught 3 pre-PR bugs on Lazlo retry (jitter asymmetry, null-guard, missing terminal log). Recommending Opus as standard for retry/backoff code — added to patterns.md.
- **GitHub:** `kumarra`
- **Watch:** SFDC-9909 EchoSign new scope — pick up Q2 Sprint 2, not carry again.
- **Path to L6:** Headless scripts calling Claude Code. Discuss in next 1:1.

### Rakesh Haridas
- **Role:** Senior Developer · **AI Maturity:** L2
- **BET:** QR-1614 (Customer AI Agent — chatbot backend, Merchant Assistant APIs)
- **Services:** Cyclops, CS-Token Service, Deal Panel, Deal Wizard, Salesforce-Cache
- **Q2 Sprint 2 focus:** GSOIT-6398 MarketRate booking info · GSOIT-6457 Merchant Assistant Case Update · GSOIT-6399 Cancellation policy fields · GSOIT-6418/6423 Bucks defects · GSOIT-6417 Cyclops BQ pipeline spike
- **Signal:** GSOIT-6446 Merchant Assistant API enhancements (Case Retrieval, Case Update, Deal Pause) Done — unblocks Merchant Assistant downstream team.
- **GitHub:** `rharidas`
- **Watch:** 7 tickets listed for next sprint — stack-rank to top 3 before Monday. Top achievement and suggestions blank. AI Signal section needs personal AI usage, not just chatbot work.
- **Path to L3:** Build one custom skill or repeatable workflow this sprint. Discuss in 1:1.

### Datta Maddala
- **Role:** Senior Developer · **AI Maturity:** L3
- **BET:** QR-1631 (Merchant Lifecycle — BR↔SF sync, ETL), QR-1612 (SFDC-ETL)
- **Services:** SFDC-ETL, Salesforce-Metrics
- **Q2 Sprint 2 focus:** GSOIT-6427 Cyclops/cs-api latency fix deployment + staging verification · GSOIT-6429 BR→SF email deliverability webhook · GSOIT-6400 AI Usage/Playwright (must close — 2nd sprint carry-over)
- **Signal:** GSOIT-6358 giftee refund + GSOIT-6349 gift recipient deployed to production. Playwright automation for refund audit record gathering during Cyclops latency investigation — automated manual data collection.
- **GitHub:** `dmaddala`
- **Bloomreach context:** BR→SF email deliverability webhook POC done (GSOIT-6429). Full dev pending Kateryna Usova's CSV export spec from Bird↔BQ.
- **Action:** GSOIT-6400 — commit to Done date in next 5/15. Connect with Ashwinkrishna on Playwright Chrome session reuse for MCP without Okta (Datta's suggestion — prototype Q2 Sprint 2).
- **Watch:** GSOIT-6369 Cyclops latency — fix proposals in progress (GSOIT-6427). No schema/API changes until root cause confirmed resolved.

### Ravindra Kumar
- **Role:** Senior Developer · **AI Maturity:** L2
- **BET:** QR-1631 (Merchant Lifecycle — cs-api endpoints, post-refund recommendations)
- **Services:** Cyclops As A Platform (cs-api), Transporter-Jtier, Transporter-Itier
- **Q2 Sprint 2 focus:** GSOIT-6378 Post-Refund Recommendations CS-API (blocked — #1 priority) · GSOIT-6417 Cyclops BQ pipeline spike
- **Signal:** Resolved live promo code incident end-to-end on on-call. GSOIT-6389 Gift Voucher Dashboard deployed to production. Pre-purchase spike document completed.
- **GitHub:** `ravikumar`
- **Watch:** GSOIT-6378 blocked on RAPI team creating client ID for cs-api — escalating to Dennis Bertelkamp. Written dependency summary from Ravindra needed by Monday noon IST. This is priority #1 — everything else secondary until unblocked.

---

## Key Stakeholders

| Name | Role | Notes |
|------|------|-------|
| Josef Sima | EM Manager | 5/15 recipient · AI Showcase Apr 29 |
| Dennis Bertelkamp | Product Owner (SP) | GSOIT primary PO · Escalation: GSOIT-6378 RAPI unblock |
| Michal Jilka | Product Owner (SP) | Cyclops, CS-Token, Unified Customer Profile |
| Chris Hill | RevOps Lead | SFDC requirements, Opportunity governance |
| Maciej Kołodziej | Sales Ops | Opportunity & Lead process owner |
| Samuel Garcia Rio | Customer Support Lead | Service Cloud, Case escalations |
| Zeph Buck | CommOps | Commercial Operations |
| Dilpreet Dhaliwal | Cross-functional | AI automation testing — SF field reports, Cyclops/BigQuery |
| Kateryna Usova | Bloomreach PM | BR↔SF email deliverability CSV spec pending — blocks GSOIT-6429 |
| Keith Hayden | Data/Analytics | Core deal tables for BR business metrics feed |
| Tomas Zaruba | Bloomreach Eng | Out ~2 weeks from Apr 21. MC go-live covered Monday. |
| Lukas Benes | Merchant Lifecycle DRI | Out ~2 weeks from Apr 21. Checking in occasionally. |

---

## Active BETs

| BET | Jira | Status | Progress | Top risk |
|-----|------|--------|----------|----------|
| Margin Control | QR-1624 | 🟢 | 70% | SFDC-9974 OCR UAT carry-over |
| SF Cleanup & Optimization | QR-1612 | 🟡 | 40% | XFiles Pro vendor + Apex job limit at 96/100 |
| Customer AI Agent | QR-1614 | 🟢 | 55% | Sprint overload — Rakesh top-3 needed |
| Merchant Lifecycle Engine | QR-1631 | 🟡 | 30% | GSOIT-6378 blocked on RAPI team |
| PoF Ingresso INTL | QR-1658 | 🟢 | 45% | Finance/FinSys resourcing (not Eng) |

---

## Team AI Maturity Baseline — Q2 Sprint 2 (Apr 24, 2026)

| Engineer | Level | Key evidence |
|----------|-------|--------------|
| Nirajkumar | L4→L5 | Pre-PR skill chain + sf-pr-creation agent, ~50% spike time reduction |
| Ravi Kumar | L4→L5 | Opus multi-pass review, 5 AI task types, incident AI investigation |
| Ashwinkrishna | L3 | SF MCP setup, Claude Code prototyping |
| Datta | L3 | Playwright automation for incident investigation |
| Amit | L2→L3 | Claude end-to-end Apex development |
| Utkarsh | L2→L3 | Full Apex solution built with Claude |
| Niveditha | L2 | Claude for analysis + export |
| Rakesh | L2 | Chatbot backend work |
| Ravindra | L2 | Daily AI usage improving |

Target: nobody below L3 by end of Q2 2026.

---

## Team Process — Active from Q2 Sprint 2

- **Weekly AI usage log:** All engineers log one AI interaction per week in team meta-repo
- **Opus pre-PR review:** Mandatory for retry/backoff/circuit-breaker/timeout code
- **Quality Hour:** Wednesday 10:00–11:00 IST fixed — no feature work
- **5/15 standards:** Suggestions mandatory · AI Signal = ticket + outcome + time saved · Priorities = 3 ticket keys
- **Automated memos + emails:** Amit + Nirajkumar sharing pattern — one shared skill target

---

## Bloomreach Stream Notes (QR-1631)

- MC↔SF contacts sync: deploying to production Monday Apr 28 (Ankur driving)
- CDP email proxy: tested, working, placeholder for missing merchant UUIDs agreed
- SMS proxy: under development B2C side — last prereq before production data
- BR→SF email deliverability webhook: POC done (Datta/GSOIT-6429), pending Kateryna's CSV spec
- Contact router architecture: final round with Bloomreach team needed
- Business metrics feed: using Keith's existing core deal tables (not new pipelines)
- Lukas + Tomas out ~2 weeks from Apr 21
