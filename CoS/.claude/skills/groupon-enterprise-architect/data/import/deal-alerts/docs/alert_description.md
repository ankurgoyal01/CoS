# Alerts

Describes each alert type's trigger, the conditions that filter alerts before processing, and the actions executed based on severity.

---

## Global Conditions for Actions (Applied to All Alerts)

All alerts pass through the following filtering stages before actions are executed:

### Stage 1: Deal Filter
- **Shopping Channel**: Deals on shopping channel are filtered out
- **3pip**: Deals in 3pip subchannel without Salesforce ID are filtered out
- **Not in Salesforce**: Deals without a Salesforce Opportunity ID are filtered out
- **Notification Invalidated**: Alerts with invalidated notifications are filtered out
- **Merchant replied to SMS**: SoldOut alerts where merchant replied to the SMS notification are filtered out

### Stage 2: GP30 Filter
- **No GP30**: Alerts for deals with no GP (Gross Profit) in last 30 days are filtered out

### Stage 3: Salesforce Filter
- **Live Account**: Alerts for accounts with Type = "Live" are filtered out

### Stage 4: Severity Mapping
- **Severity not mapped**: Alerts that don't map to a severity level (based on GP30 thresholds) are filtered out
- Severity levels: `low`, `medium`, `high` (determined by GP30 thresholds per alert type)

### Stage 5: Muted Alerts Filter
- Alerts muted at account or opportunity level are filtered out

---

## MDS Alerts

### DealEnding
- **Trigger**: day to end date crosses over 7 or 30 days

#### Actions
| Severity | Actions |
|----------|---------|
| medium, high | SalesforceTask, Chat |
| high | ManagerChat |

---

### DealEnded
- **Trigger**: current time passes end date and deal still has remaining inventory

#### Actions
| Severity | Actions |
|----------|---------|
| medium, high | SalesforceTask, Chat |
| high | ManagerChat |

---

### DealEndedBeforeScheduled
- **Trigger**: deal becomes inactive, end date changes to the past and deal still has remaining inventory

#### Actions
| Severity | Actions |
|----------|---------|
| medium, high | SalesforceTask, Chat |
| high | ManagerChat |

---

### DealSoldOut
- **Trigger**: deal (all options) sell out, with an additional check of history to prevent a few refunds being restocked -> sold out a few hours later on the options that were just sold out

#### Alert-Specific Conditions
- **Not restocked yet from previous sellout**: Filtered if `has_replenishment_bellow_threshold` is true
- **Will replenish**: Filtered if all options have replenishment scheduled for today

#### SMS Notification Conditions (before action execution)

**Country Filter:**
- Only US deals receive SMS notifications (non-US deals are skipped)

**Account Scope Check** (ScopeLimited if any fail):
- Account Category must be one of: Beauty/Wellness/Healthcare, Leisure Offers/Activities, Food & Drink, Services, Shopping
- Account Type must be "Local"
- Account must not have a DNR (Do Not Reach) reason
- Account Feature Country must be "US"

**Contact Validation:**
- `ContactNotFound`: No contacts on account or no contact matches opportunity's Email_List_To__c
- `MobilePhoneNotFound`: Contact found but has no mobile phone
- `InvalidNumber`: Phone doesn't match US format (+1 followed by valid NANP number)

**Message & Replenishment:**
- `MessageTooLong`: Message exceeds 306 characters
- `WillReplenish`: Replenishment scheduled for today/tomorrow
- `OptionDeleted`: Option no longer exists in deal snapshot

**Timing:**
- Waits 1 hour after SMS sent before executing actions (to allow merchant reply)

#### Actions
| Severity | Actions |
|----------|---------|
| medium, high | SalesforceTask, Chat |
| high | ManagerChat |

---

### OptionSoldOut
- **Trigger**: an option sold out, with an additional check of history to prevent a few refunds being restocked -> sold out a few hours later

#### Alert-Specific Conditions
- **Superseded**: Filtered if all remaining options on the deal are also sold out (becomes a DealSoldOut)
- **Not restocked yet from previous sellout**: Filtered if `has_replenishment_bellow_threshold` is true
- **Will replenish**: Filtered if option has replenishment scheduled for today

#### SMS Notification Conditions (before action execution)

**Country Filter:**
- Only US deals receive SMS notifications (non-US deals are skipped)

**Account Scope Check** (ScopeLimited if any fail):
- Account Category must be one of: Beauty/Wellness/Healthcare, Leisure Offers/Activities, Food & Drink, Services, Shopping
- Account Type must be "Local"
- Account must not have a DNR (Do Not Reach) reason
- Account Feature Country must be "US"

**Contact Validation:**
- `ContactNotFound`: No contacts on account or no contact matches opportunity's Email_List_To__c
- `MobilePhoneNotFound`: Contact found but has no mobile phone
- `InvalidNumber`: Phone doesn't match US format (+1 followed by valid NANP number)

**Message & Replenishment:**
- `MessageTooLong`: Message exceeds 306 characters
- `WillReplenish`: Replenishment scheduled for today/tomorrow
- `OptionDeleted`: Option no longer exists in deal snapshot

**Timing:**
- Waits 1 hour after SMS sent before executing actions (to allow merchant reply)

#### Actions
| Severity | Actions |
|----------|---------|
| medium, high | SalesforceTask, Chat |
| high | ManagerChat |

---

## External Alerts

### ConversionDropped
- **Trigger**: BigQuery (drop in CVR in the last week compared to 12 week avg)

#### Actions
| Severity | Actions |
|----------|---------|
| medium, high | Chat |
| high | SalesforceTask, ManagerChat |

---

### PerformanceDropped
- **Trigger**: BigQuery (drop in NOR in the last week compared to 12 week avg)

#### Actions
| Severity | Actions |
|----------|---------|
| medium, high | Chat |
| high | SalesforceTask, ManagerChat |

---

### OptionSelloutPredicted
- **Trigger**: BigQuery (detected high likelihood that an option will sellout in the next 7 days)

#### Alert-Specific Conditions
- **Restocked**: Filtered if `option_remaining_quantity > (prediction_units + 2)` (2 unit buffer for refunds)
- **Sold Out**: Filtered if `option_remaining_quantity === 0`

#### Actions
| Severity | Actions |
|----------|---------|
| medium, high | SalesforceTask, Chat |
| high | ManagerChat |

---

### PerformanceIncident
- **Trigger**: BigQuery

#### Actions
*No actions currently mapped*

---

### ConversionIncident
- **Trigger**: BigQuery

#### Actions
| Severity | Actions |
|----------|---------|
| low, medium, high | ReviewChanges |

---

## Action Types Reference

| Action | Description |
|--------|-------------|
| **SalesforceTask** | Creates a task in Salesforce assigned to the account owner |
| **Chat** | Sends a Google Chat message to the account owner |
| **ManagerChat** | Sends a Google Chat message to the account owner's manager |
| **ReviewChanges** | Triggers a review changes workflow |
