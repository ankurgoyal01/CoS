# patterns.md — Code Patterns, Org Quirks & Recurring Issues
> Read when doing code review, writing code, or debugging recurring problems.
> Last updated: April 17, 2026

---

## SFDC — Apex Patterns

### Trigger handler pattern (mandatory)
```apex
// Trigger — zero logic, just routes to handler
trigger OpportunityTrigger on Opportunity (before insert, before update, after insert, after update) {
    OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
    if (Trigger.isBefore) {
        if (Trigger.isInsert) handler.onBeforeInsert(Trigger.new);
        if (Trigger.isUpdate) handler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) handler.onAfterInsert(Trigger.new);
        if (Trigger.isUpdate) handler.onAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}

// Handler class — all logic here
public class OpportunityTriggerHandler {
    public void onBeforeInsert(List<Opportunity> newList) {
        // bulk-safe logic only
    }
}
```

### Bulkification pattern (mandatory)
```apex
// WRONG — SOQL in loop
for (Account acc : accounts) {
    List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId = :acc.Id];
}

// CORRECT — bulk query, map lookup
Map<Id, List<Contact>> contactsByAccount = new Map<Id, List<Contact>>();
for (Contact c : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountIds]) {
    if (!contactsByAccount.containsKey(c.AccountId)) {
        contactsByAccount.put(c.AccountId, new List<Contact>());
    }
    contactsByAccount.get(c.AccountId).add(c);
}
```

### Named Credential callout pattern (mandatory for all integrations)
```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:DealEstateAPI/v1/cda-import');  // Named Credential
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');
req.setBody(JSON.serialize(payload));

Http http = new Http();
HttpResponse res = http.send(req);
if (res.getStatusCode() != 200) {
    throw new CalloutException('Deal Estate API error: ' + res.getBody());
}
```

### Async callout pattern (use for Deal Estate, Merchant Center integrations)
```apex
// Queueable for async REST callouts
public class CDADealEstateQueueable implements Queueable, Database.AllowsCallouts {
    private List<CDA__c> cdaList;

    public CDADealEstateQueueable(List<CDA__c> cdas) {
        this.cdaList = cdas;
    }

    public void execute(QueueableContext ctx) {
        CDADealEstateService.importToDealer(cdaList);
    }
}
// Enqueue from trigger handler:
System.enqueueJob(new CDADealEstateQueueable(cdaList));
```

### Test class pattern (85%+ coverage, meaningful assertions)
```apex
@isTest
private class OpportunityTriggerHandlerTest {
    @TestSetup
    static void setup() {
        Account acc = TestDataFactory.createAccount('Test Account');
        insert acc;
    }

    @isTest
    static void testOnBeforeInsert_setsDefaultValues() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        Opportunity opp = TestDataFactory.createOpportunity(acc.Id, 'Test Opp');
        insert opp;
        Test.stopTest();

        Opportunity result = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Prospecting', result.StageName, 'Stage should default to Prospecting');
    }
}
// Rules: TestDataFactory always, no hardcoded IDs, Test.startTest/stopTest wraps DML, meaningful assertEquals
```

---

## SFDC — Recurring Issues & Quirks

### INTL CDA blocker pattern
- **Issue:** INTL Sales Reps cannot add CDAs to live Opportunities. Recurs because of three separate dependencies: (1) Region/Deal_Type__c picklist values not extended for INTL, (2) AdobeSign template not uploaded for INTL regions, (3) Deal Estate API availability for INTL not confirmed.
- **Resolution path:** Confirm AdobeSign template with Carmen Meyer/Richard Jenner → extend picklist values in Staging → test Deal Estate callout with INTL endpoint → UAT in QA sandbox with INTL Sales Rep profile.
- **Tickets:** SFDC-10055, SFDC-10103 (now in QA Apr 16)
- **Owner:** Niveditha

### Dynamic Layout UAT — reopening pattern
- **Issue:** Dynamic Layout features pass initial QA but get reopened during production UAT due to profile/record type visibility edge cases.
- **Pattern:** Always test against INTL Sales Rep profile + all record types in QA, not just the primary profile.
- **Ticket:** SFDC-10157

### Managed package field conflicts
- **Issue:** Attempting to modify Unbabel translation fields, AdobeSign signature fields, or Conga template fields causes deployment errors. These are managed package components.
- **Check:** Before any metadata deployment, verify the component is not owned by Unbabel, AdobeSign, Conga, XFiles Pro, or Data Connectiva.
- **How to check:** In Salesforce Setup → Package Manager → view installed packages → compare namespace prefixes.

### Flow + Apex on same object — governor limit double-counting
- **Issue:** When both a Flow and an Apex trigger fire on the same event for Opportunity, SOQL/DML limits are consumed twice — often hits limits in bulk operations.
- **Resolution:** Always check if a Flow already handles the same event before adding Apex logic. Pick one, not both.

### Account cross-reference validation errors (SFDC-9169 pattern)
- **Issue:** Moving accounts or reassigning ownership fails with cross-reference validation errors when sharing rules reference the old owner's role/territory.
- **Resolution path:** Identify sharing rules referencing old owner → update or deactivate before reassignment → use Account Skew cleanup ticket to prevent recurrence.
- **Current ticket:** SFDC-9169 (blocked, Kumar Ankit)

---

## GSOIT — Service Patterns

### JTier service pattern (Java 11, Maven 3.5.4)
```java
// Standard JTier controller pattern
@RestController
@RequestMapping("/api/v1")
public class CsApiController {

    @Autowired
    private CsApiService csApiService;

    @GetMapping("/recommendations/{orderId}")
    public ResponseEntity<RecommendationResponse> getRecommendations(
            @PathVariable String orderId) {
        try {
            RecommendationResponse response = csApiService.getRecommendations(orderId);
            return ResponseEntity.ok(response);
        } catch (NotFoundException e) {
            return ResponseEntity.notFound().build();
        }
    }
}
// PMD static analysis: 0 failures target
// Spotbugs: track quarterly, trend downward
```

### Ruby on Rails pattern (Cyclops/CS-Token — multi-version aware)
```ruby
# Check Ruby version first: cat .ruby-version or check Gemfile
# Rubocop: 0 failures target
# Cyclops: Ruby 2.2.2 — avoid modern Ruby syntax (safe navigation &., pattern matching)
# CS-Token: Ruby 2.6.3 — safe navigation OK

# Standard Cyclops controller pattern
class Cyclops::RefundController < ApplicationController
  before_action :authenticate_user!

  def process
    result = RefundService.new(params[:order_id]).call
    render json: result, status: :ok
  rescue RefundService::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
```

### Airflow DAG pattern (SFDC-ETL — Shared Composer)
```python
# SFDC-ETL uses Shared Composer — coordinate with data team before changes
# No Sonar — manual review required on ALL PRs

from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'sfdc-team',
    'depends_on_past': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
    'email_on_failure': True,
    'email': ['agoyal@groupon.com']
}

dag = DAG(
    'sfdc_to_bigquery_sync',
    default_args=default_args,
    schedule_interval='0 2 * * *',  # 2 AM UTC daily
    catchup=False,
)
# ALWAYS add email_on_failure — ETL failure = data warehouse gap (P1)
```

### Cross-team PR review checklist
Before approving any PR that touches shared infrastructure:
1. Linked Jira ticket (SFDC-xxx or GSOIT-xxx)?
2. SOQL/DML in loops? (Apex) · N+1 queries? (Ruby/Java)?
3. Coverage meaningful, not padded?
4. `// WHY` comment on non-obvious logic?
5. Touches Opportunity, Account, Cyclops, or Salesforce-Cache? → extra review cycle
6. Rollback plan documented?
7. Grafana alerts updated if new metrics added? (GSOIT)
8. Managed package component? → reject if so

---

## GSOIT — Recurring Issues & Quirks

### Cyclops latency investigation (active Q2 Sprint 1)
- **Issue:** Cyclops experiencing intermittent latency spikes. Root cause under investigation by Datta (GSOIT-6369).
- **Pattern:** Likely related to MySQL DAAS query performance or Redis RAAS cache miss patterns. Not confirmed yet.
- **Rule:** No Cyclops schema or API changes until GSOIT-6369 is resolved. Any Cyclops-related PR must be reviewed by Datta.
- **Check before merging any Cyclops PR:** Is GSOIT-6369 still open? If yes, defer schema/API changes.

### E-Gift Card redemption inconsistency pattern
- **Issue:** E-Gift card redemption shows inconsistent details to recipients (GSOIT-6223). Recurring across multiple sprints.
- **Root cause:** Race condition between gift card service state update and Cyclops data cache refresh.
- **Mitigation:** Always test gift flow end-to-end in staging with a cold cache before merging Cyclops gift-related changes.

### SSR (Self-Service Refund) mass refund automation
- **Pattern:** INTL mass refund automation failures occur when the auto-refund trigger doesn't fire after 14 days due to missing SSR eligibility fields in custom-data.
- **Required fields:** `ssr_enabled`, `refund_destination` must be present in inventory unit custom-data.
- **Ticket:** GSOIT-6356 (Rakesh, In Progress), GSOIT-6388 (monitoring + alerts)

### GSOIT-ETL BigQuery sync gap detection
- **Pattern:** SFDC-ETL Airflow DAG failures don't always surface in alerting immediately. Check BigQuery table freshness if Salesforce reporting looks stale.
- **Check:** `SELECT MAX(updated_at) FROM sfdc_opportunities` in BigQuery — if >24h stale, check Airflow DAG status.
- **Owner:** Datta Maddala

### Branch name lookup before checkout
- **Pattern:** GSOIT services don't use a consistent default branch name. Always check the service README before `git checkout`.
  - Most services: `main`
  - Some legacy: `master`
  - SFDC-ETL, some others: `develop`
- **Risk services with unprotected branches:** Deal Panel, Webbus, Salesforce-Cache, Transporter-Jtier, Transporter-Itier, SFDC-ETL, Salesforce-Metrics

---

## AI tooling patterns (personal workflow)

### standup.sh invocation pattern
```bash
# Headless standup brief — runs Jira + Gmail + GCal via Claude Code MCP
# Asana fetched via direct REST (PAT), not MCP
# Cron: 0 4 * * 1-5 (9:30 AM IST)
~/standup.sh
```

### weekly-report.sh invocation pattern
```bash
# 8-week GitHub performance PDF — runs every Monday 12:00 noon IST
# GitHub API: github.groupondev.com/api/v3 (Enterprise)
# Orgs: sox-inscope, salesforce
# Token: from github.groupondev.com/settings/tokens (NOT github.com)
# Cron: 30 6 * * 1 (6:30 AM UTC = 12:00 noon IST)
~/weekly-report.sh
```

### Claude Code MCP config location
```bash
~/.claude/settings.json   # MCP servers: atlassian, gcal, gmail, asana
~/.claude/CLAUDE.md       # Session context — team, sprint, decisions
~/standup.sh              # Daily headless standup
~/weekly-report.sh        # Weekly GitHub PDF report
~/standup-logs/           # All output logs and PDFs
```

### Asana task creation pattern (from scripts)
```python
# Always use multipart/form-data for PDF attachments
# Always use os.environ.get() for tokens — never bash heredoc interpolation
# Workspace GID: 8437193015852
# Assignee GID: 1211542692184092
```
