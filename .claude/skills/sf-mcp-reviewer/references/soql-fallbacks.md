# SOQL Fallback Library

Use these queries when the primary MCP tools return 400 errors.
All queries assume `THIS_WEEK` unless noted — substitute as needed.

---

## Security & Permissions

### Profile & Permission Set Changes
```sql
SELECT Action, Section, Display, CreatedDate, CreatedBy.Name, CreatedBy.Username
FROM SetupAuditTrail
WHERE CreatedDate = THIS_WEEK
AND (Section LIKE '%Profile%' OR Section LIKE '%Permission%'
     OR Section LIKE '%Role%' OR Section = 'Manage Users')
ORDER BY CreatedDate DESC LIMIT 500
```

### Failed Logins
```sql
SELECT UserId, Username, LoginTime, LoginType, Status, SourceIp, Browser, Platform
FROM LoginHistory
WHERE LoginTime = THIS_WEEK AND Status != 'Success'
ORDER BY LoginTime DESC LIMIT 200
```

### Sharing Rule & Security Config Changes
```sql
SELECT Action, Section, Display, CreatedDate, CreatedBy.Name
FROM SetupAuditTrail
WHERE CreatedDate = THIS_WEEK
AND (Section LIKE '%Sharing%' OR Section LIKE '%Security%' OR Section LIKE '%Certificate%')
ORDER BY CreatedDate DESC LIMIT 200
```

---

## Automation

### Apex Classes (this week)
```sql
SELECT Id, Name, Status, IsValid, LastModifiedDate, LastModifiedBy.Name, LastModifiedBy.Username
FROM ApexClass
WHERE LastModifiedDate = THIS_WEEK
ORDER BY LastModifiedDate DESC LIMIT 200
```

### Apex Classes (object-specific — replace [ObjectName])
```sql
SELECT Id, Name, Status, IsValid, LastModifiedDate, LastModifiedBy.Name
FROM ApexClass
WHERE Name LIKE '%[ObjectName]%'
ORDER BY LastModifiedDate DESC
```

### Apex Triggers (this week)
```sql
SELECT Id, Name, TableEnumOrId, Status, IsValid, LastModifiedDate, LastModifiedBy.Name
FROM ApexTrigger
WHERE LastModifiedDate = THIS_WEEK
ORDER BY LastModifiedDate DESC LIMIT 50
```

### Apex Triggers (object-specific — replace [ObjectApiName])
```sql
SELECT Id, Name, TableEnumOrId, Status, IsValid, LastModifiedDate, LastModifiedBy.Name
FROM ApexTrigger
WHERE TableEnumOrId = '[ObjectApiName]'
ORDER BY LastModifiedDate DESC
```

### SetupAuditTrail — Apex changes
```sql
SELECT Action, Section, Display, CreatedDate, CreatedBy.Name
FROM SetupAuditTrail
WHERE CreatedDate = THIS_WEEK
AND (Section = 'Apex Class' OR Section = 'Apex Trigger' OR Section LIKE '%Apex%')
ORDER BY CreatedDate DESC LIMIT 500
```

### Flows & Process Builder
```sql
SELECT Action, Section, Display, CreatedDate, CreatedBy.Name
FROM SetupAuditTrail
WHERE CreatedDate = THIS_WEEK
AND (Section LIKE '%Flow%' OR Section LIKE '%Process%')
ORDER BY CreatedDate DESC LIMIT 200
```

### Validation Rules
```sql
SELECT Action, Section, Display, CreatedDate, CreatedBy.Name
FROM SetupAuditTrail
WHERE CreatedDate = THIS_WEEK
AND Section LIKE '%Validation%'
ORDER BY CreatedDate DESC LIMIT 200
```

---

## Layout Changes

### All layout changes (any object)
```sql
SELECT Id, Action, CreatedDate, CreatedBy.Name, Display, Section
FROM SetupAuditTrail
WHERE Action LIKE '%layout%'
ORDER BY CreatedDate DESC LIMIT 100
```

### Filter by object (in-memory after fetching above)
- Opportunity: `Action = 'opplayout'` or `Display LIKE '%Opportunity%'`
- Account:      `Action = 'accountlayout'`
- Case:         `Action = 'caselayout'`
- Contact:      `Action = 'contactlayout'`
- Lead:         `Action = 'leadlayout'`
- Custom Object:`Action = 'custentlayout'`
- Custom MDT:   `Action = 'custmdtypelayout'`

> **Note**: `Section` cannot be used in WHERE for SetupAuditTrail. Always fetch all layout rows
> and filter client-side.

---

## Data Queries (by object + period)

### Accounts
```sql
SELECT Id, Name, Industry, Type, Owner.Name, Phone,
       BillingCity, BillingCountry, CreatedDate
FROM Account
WHERE CreatedDate = THIS_MONTH
ORDER BY CreatedDate DESC LIMIT 200
```

### Opportunities
```sql
SELECT Id, Name, StageName, Amount, CloseDate, Probability,
       Owner.Name, Account.Name, Type, CreatedDate
FROM Opportunity
WHERE CreatedDate = THIS_MONTH
ORDER BY CreatedDate DESC LIMIT 200
```

### Cases
```sql
SELECT Id, CaseNumber, Subject, Status, Priority, Type,
       Owner.Name, Account.Name, CreatedDate
FROM Case
WHERE CreatedDate = THIS_MONTH
ORDER BY CreatedDate DESC LIMIT 200
```

### Contacts
```sql
SELECT Id, Name, Title, Email, Phone, Account.Name,
       Department, LeadSource, CreatedDate
FROM Contact
WHERE CreatedDate = THIS_MONTH
ORDER BY CreatedDate DESC LIMIT 200
```

### Leads
```sql
SELECT Id, Name, Company, Title, Email, Phone,
       Status, LeadSource, Owner.Name, CreatedDate
FROM Lead
WHERE CreatedDate = THIS_MONTH
ORDER BY CreatedDate DESC LIMIT 200
```

---

## Period Token Reference

| User says | SOQL token |
|-----------|------------|
| this week | `THIS_WEEK` |
| this month | `THIS_MONTH` |
| today | `TODAY` |
| last week | `LAST_WEEK` |
| last month | `LAST_MONTH` |
| last 7 days | `LAST_N_DAYS:7` |
| last 30 days | `LAST_N_DAYS:30` |
| specific range | `>= 2026-03-01T00:00:00Z AND <= 2026-03-21T23:59:59Z` |
