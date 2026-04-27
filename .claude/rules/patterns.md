# patterns.md — Code & Engineering Patterns
> Read when doing code review, writing code, or advising on implementation.
> Last updated: April 24, 2026

---

## SFDC Apex Patterns

### Apex trigger pattern (mandatory)
```apex
// One trigger per object — zero logic in trigger body
trigger OpportunityTrigger on Opportunity (before insert, before update, after insert, after update) {
    OpportunityTriggerHandler.handleTrigger(Trigger.new, Trigger.old, Trigger.operationType);
}

// All logic in handler class
public class OpportunityTriggerHandler {
    public static void handleTrigger(List<Opportunity> newRecords, List<Opportunity> oldRecords, TriggerOperation operation) {
        // Business logic here
    }
}
```

### Bulkification (mandatory)
```apex
// NEVER do this — SOQL in loop = governor limit failure
for (Opportunity opp : opportunities) {
    Account acc = [SELECT Id FROM Account WHERE Id = :opp.AccountId]; // WRONG
}

// ALWAYS do this — collect IDs, query once
Set<Id> accountIds = new Set<Id>();
for (Opportunity opp : opportunities) {
    accountIds.add(opp.AccountId);
}
Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE Id IN :accountIds]);
```

### TestDataFactory pattern
```apex
// Always use TestDataFactory — no hardcoded IDs, no hardcoded names
@isTest
public class OpportunityTriggerHandlerTest {
    @TestSetup
    static void setup() {
        Account acc = TestDataFactory.createAccount('Test Account');
        insert acc;
        Opportunity opp = TestDataFactory.createOpportunity(acc.Id, 'Test Opp', 'Prospecting');
        insert opp;
    }

    @isTest
    static void testHandleTrigger() {
        Opportunity opp = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        // Test meaningful business logic, not just coverage
        System.assertEquals('Prospecting', opp.StageName, 'Stage should be Prospecting');
    }
}
// Target: 85%+ coverage with meaningful assertions
```

### Named Credential for callouts
```apex
// ALWAYS use Named Credentials — never hardcode endpoints or credentials
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:MerchantCenter_API/v1/merchants');
req.setMethod('GET');
Http http = new Http();
HttpResponse res = http.send(req);
```

---

## GSOIT Service Patterns

### JTier (Java 11, Maven 3.5.4)
```java
// PMD static analysis — 0 failures target
// Spotbugs — track quarterly, trend downward
// Standard JTier 5.14.x patterns apply

// No N+1 queries — batch all DB calls
// Spring dependency injection — no static singletons
// All external calls: circuit breaker + timeout configured
```

### Ruby services
```ruby
# Rubocop — 0 failures target
# Do NOT assume a single Ruby version across services — check service README first
# Webbus: Ruby 1.9.3 (EOL) — ANY change = escalate to EM before touching
# Cyclops: Ruby on Rails 3.2, Ruby 2.2.2 — no schema changes during latency investigation

# Standard pattern: rescue specific exceptions, not bare rescue
begin
  result = service_call
rescue ServiceError => e
  logger.error("Service call failed: #{e.message}")
  raise
end
```

### iTier (Node.js)
```javascript
// ESLint — 0 errors target, trend warnings down
// Node version varies 12–16 — always check service README before assuming
// Pizza NG: Node 12, Deal Panel: Node 14, Transporter-Itier: Node 16

// Standard error handling
async function callService(params) {
  try {
    const result = await serviceClient.call(params);
    return result;
  } catch (error) {
    logger.error({ error, params }, 'Service call failed');
    throw error;
  }
}
```

### Python (SFDC-ETL, RPA)
```python
# No Sonar — manual review required on all PRs
# SFDC-ETL: Airflow DAGs on Shared Composer — coordinate with Dilpreet before changes
# RPA: GCP VM, manual deployment — Deploybot not available

# Standard Airflow DAG pattern
from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta

default_args = {
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
    'on_failure_callback': alert_on_failure
}
```

---

## High-Risk Code Patterns Requiring AI Pre-Review

### ⚠️ Retry / Backoff / Circuit Breaker — Opus multi-pass mandatory
**Added:** April 24, 2026 — Ravi Kumar finding on Lazlo retry (GSOIT-6291)

Any code touching retry logic, backoff algorithms, circuit breakers, or timeout configuration **must** go through Opus multi-pass review before PR creation. Run Claude Opus on the diff specifically asking it to look for:
- Jitter asymmetry (one-sided jitter that doesn't actually randomise)
- Null-guards on config parameters (missing null-guard on delay arrays = NPE at runtime)
- Missing terminal log on exhaustion (no log when all retries fail = silent failure, undiagnosable in production)
- Off-by-one in retry count
- Exception handling that swallows errors silently

**Evidence:** Opus caught 3 pre-PR bugs on the Lazlo retry implementation (GSOIT-6291) that human review missed — jitter asymmetry, null-guard on `delays`, no terminal log on exhaustion. These are the failure modes that cause production incidents at 3 AM.

```javascript
// Example: what Opus caught on Lazlo retry
// BUG 1 — jitter asymmetry: should be ±20%, was +20% only
const jitter = Math.random() * 0.2; // WRONG — always adds, never subtracts
const jitter = (Math.random() - 0.5) * 0.4; // CORRECT — ±20%

// BUG 2 — null-guard missing
const delay = delays[attempt]; // WRONG — crashes if delays is null/undefined
const delay = (delays ?? [500, 1000, 2000])[attempt]; // CORRECT

// BUG 3 — no terminal log
if (attempt === maxRetries) {
    throw error; // WRONG — silent failure in logs
}
if (attempt === maxRetries) {
    logger.error({ error, attempt }, 'All retries exhausted'); // CORRECT
    throw error;
}
```

### ⚠️ Cyclops / cs-api changes — extra review
- No schema changes during active latency investigation (GSOIT-6369/6427 — see D-014)
- Any endpoint modification: check Dilpreet's AI reporting pipeline dependencies first
- minReplicas floor is now 3 — do not reduce without EM approval

### ⚠️ Salesforce Opportunity / Account at scale
- Always check: is there a Flow already running on this object + event? Check for conflicts before adding Apex.
- Bulk operations: test with 200-record DataFactory, not single records
- Page load: any field add to Account/Opportunity layout must be justified — page load baseline is 5.8s (target ≤2.5s)

---

## Cross-Team PR Review Checklist

Before approving any PR:
1. **Jira linked?** — SFDC-xxx or GSOIT-xxx in PR description. (Jira Linkage target: 90%+)
2. **SOQL/DML in loops?** (Apex) · **N+1 queries?** (Ruby/Java)
3. **Coverage meaningful, not padded?** — assertions verify logic, not just line hits
4. **`// WHY` comment on non-obvious logic?**
5. **High-criticality surface?** — Opportunity, Account, Cyclops, Salesforce-Cache → extra review required
6. **Rollback plan documented?** (required for Opp/Account/Case triggers, integrations)
7. **Grafana alerts updated?** — if new metrics added (GSOIT services)
8. **Retry/backoff/circuit-breaker code?** → Opus multi-pass before PR (see above)
9. **New Scheduled Apex job?** → Check current count (96/100 limit) — do not add without cleanup first

---

## AI-Assisted Development Patterns

### Spec quality before delegation
- Vague spec → poor-quality AI output → rework. Write spec first, delegate second.
- CLAUDE.md / AGENTS.md must reflect current system state before any agentic run.
- For Salesforce: include object names, field names, expected behaviour, edge cases in spec.

### Claude orchestration pattern (Nirajkumar's setup)
- **sf-project-planner skill** → complex analysis spikes: ~50% time reduction documented
- **Pre-PR code review skill** → pre-flight before sf-pr-creation agent fires
- **Pattern:** Spike with planner → TDD review → pre-PR review → sf-pr-creation agent → human review
- **Result:** Catches issues before PR creation, not during review

### Playwright for data collection during incidents
- **Pattern (Datta, Apr 2026):** Use Playwright to automate gathering audit records / log data from internal tools during active incident investigation
- **Benefit:** Reduces investigation time from hours to minutes for structured data extraction
- **Explore:** Playwright Chrome session reuse for MCP without separate Okta authentication (Datta + Ashwinkrishna prototyping Q2 Sprint 2)

### TDD agent pattern
- **Watcher:** polls every 4 hours, state file deduplication, parallel specialist spawning
- **Specialist:** reads desc + last 5 comments, Claude generates TDD JSON, validates 8 quality checks, retries up to 3× with failure reason fed back into next prompt, attaches .docx to Jira, sets estimate, saves to KB
- **Knowledge base:** past successful TDDs used as few-shot context — improves estimates over time
- **Failure handling:** posts Jira comment with actual reason + action required if all retries fail

### Weekly AI usage tracking (from Q2 Sprint 2)
- All engineers log one AI interaction per week in team meta-repository
- Format: what was delegated, what was fixed, what worked
- Purpose: maturity tracking + YEPR evidence + team knowledge base

---

## Org Quirks & Watch-outs

### SFDC
- **Apex job limit:** 96/100 (critical). No new jobs until cleanup reduces below 75 (BET QR-1612).
- **Field limits:** Account 728, Opportunity 729 (hard limit 800). Any new field = justify and check limits first.
- **XFiles Pro:** Vendor connection error Apr 2026. Archival jobs blocked until vendor fixes. Do not attempt manual file deletion.
- **AdobeSign templates:** INTL CDA changes always require AdobeSign template alignment — high-risk for stakeholder delays.
- **ContentOps dependency:** OCR for ContentOps (SFDC-9974) has recurring UAT delay pattern — always set written deadline with stakeholder.

### GSOIT
- **Webbus:** Ruby 1.9.3 = EOL 2015. ANY change = escalate to EM. Non-negotiable.
- **cs-api:** minReplicas = 3 (post Apr 22 incident). Latency investigation ongoing (GSOIT-6427).
- **Salesforce-Cache:** Bridge service — downtime affects both teams simultaneously. Coordinate always.
- **SFDC-ETL:** Airflow DAG failure = data warehouse gap + Dilpreet's AI pipelines break. Coordinate before any changes.
- **RPA:** GCP VM, Python, manual deployment — Deploybot not available.
- **Unprotected branches:** Deal Panel, Webbus, Salesforce-Cache, Transporter-Jtier/Itier, SFDC-ETL, Salesforce-Metrics — always check README for branch naming.

### Bloomreach (QR-1631)
- Contact router: priority logic on Groupon side, exposed to BR as priority flag 1/2/3 via daily import
- Missing merchant UUID: use placeholder, do not fail the send
- Business metrics: Keith's core deal tables, not new pipelines
- Email deliverability webhook: BR→SF — pending Kateryna's CSV spec before Datta can build (GSOIT-6429)
