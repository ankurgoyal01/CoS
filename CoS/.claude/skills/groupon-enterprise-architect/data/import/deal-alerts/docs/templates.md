# Template Variables Quick Reference

---

## Common Variables (All Alert Types)

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `{{deal_title}}` | String | Deal name/title | 50% Off Spa Package |
| `{{severity}}` | Enum | Alert severity | low, medium, high, critical |
| `{{gp_l30d}}` | Currency | Last 30 days GP | $12,345.67 |
| `{{deal_url}}` | URL | Public deal URL | https://www.groupon.com/... |
| `{{opportunity_url}}` | URL | Salesforce opportunity link | https://groupon-dev... |
| `{{task_url}}` | URL | Salesforce task link (conditional) | https://groupon-dev... |
| `{{sold_out_option_count}}` | Number | Number of sold out options | 3 |
| `{{option_title}}` | String | Option name (if option level alert) | Entry for 3 people |
| `{{remaining_options_count}}` | Number | Number of options with remaining quantity | 1 |
| `{{sms_sent_to_merchant}}` | Boolean | Whether SMS notification about the alert was delivered to the merchant | false |

---

## Alert Types & Their Variables

### 1. OptionSelloutPredicted

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `{{option_title}}` | String | Option name | Entry for 3 people |
| `{{probability}}` | Number | Sellout confidence % (95-100) | 98 |
| `{{days}}` | Number | Days until predicted sellout | 5 |
| `{{replenishment_date}}` | Date | Date of next replenishment | Dec 3, 2025 |

### 2. DealEnding

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `{{end_date}}` | Date | Scheduled end date | Dec 31, 2024, 9:54 PM |
| `{{days}}` | Number | Days remaining (7 or 30) | 7 |

### 3. DealEnded

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `{{end_date}}` | Date | End date | Dec 31, 2024, 9:54 PM |

### 4. DealEndedBeforeScheduled

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `{{planned_end_date}}` | Date | Original end date | Jan 15, 2025, 11:59 PM |
| `{{actual_end_date}}` | Date | Actual end date | Jan 10, 2025, 3:45 PM |
| `{{days}}` | Number | Days ended early | 5 |

### 5. ConversionDropped

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `{{percent}}` | Number | % drop in CVR | 25 |
| `{{current}}` | Number | Current CVR % | 3.5 |
| `{{baseline}}` | Number | Previous CVR % | 4.67 |

### 6. PerformanceDropped

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `{{percent}}` | Number | % drop in performance | 15 |
| `{{current}}` | Number | Current NOR/week | 850 |
| `{{baseline}}` | Number | Previous NOR/week | 1000 |

### 7. DealSoldOut

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| *No additional variables* | - | Uses common variables only | - |

### 8. OptionSoldOut

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| *No additional variables* | - | Uses common variables only | - |

### 9. SummaryEmail

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `{{date}}` | String | Date represented by the summary | 2025 Oct 17 |
| `{{name}}` | String | Recipient name | John Smith |
| `{{tasks}}` | Array | Tasks included in the summary, used with foreach | task list |

### 10. SummaryEmailManager

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `{{date}}` | String | Date represented by the summary | 2025 Oct 17 |
| `{{name}}` | String | Manager name | Jane Manager |
| `{{users}}` | Array | Users and their tasks, used with nested foreach | user list |

---

## Template Syntax Cheat Sheet

| Syntax Type | Template | Description |
|-------------|----------|-------------|
| Simple Variable | `{{variable_name}}` | Insert variable value |
| Truthy Conditional | `{#variable\|if_true_text\|else\|if_false_text\|#}` | Show different text based on truthy/falsy |
| Value Matching | `{#variable:value1\|text1\|value2\|text2\|else\|default\|#}` | Match specific values and show corresponding text. |
| Foreach Loop | `{@array:item@}{{item.property}}{@end@}` | Loop over array with explicit variable scoping |

NOTE: You can nest `{{variable}}` placeholders inside `{#conditional#}` or `{@foreach@}` blocks. Foreach loops can be nested inside each other and can contain conditionals.

---

## Foreach Loops

### Basic Syntax

```
{@arrayName:itemVariable@}
  ... content with {{itemVariable.property}} ...
{@end@}
```

### Features

- **Explicit Variable Scoping**: Access item properties via the named variable (e.g., `{{task.id}}`, `{{task.name}}`)
- **Loop Index**: Access the current iteration index via `{{$index}}` (0-indexed)
- **Nested Loops**: Foreach blocks can be nested inside each other
- **Conditionals Inside Loops**: Use conditionals to show/hide content per item
- **Outer Scope Access**: Variables from parent scopes remain accessible
- **Empty Arrays**: Renders empty string if array is empty, null, or undefined

### Examples

#### Basic Loop

```
{@tasks:task@}
- {{task.name}}
{@end@}
```

#### Loop with Index

```
{@users:user@}
{{$index}}. {{user.name}} ({{user.email}})
{@end@}
```

#### Nested Loops

```
{@teams:team@}
Team: {{team.name}}
  Members: {@team.members:member@}{{member.name}}, {@end@}
{@end@}
```

#### Loop with Conditionals

```
{@items:item@}
{#item.inStock|✓ {{item.name}} - In Stock|else|✗ {{item.name}} - Sold Out|#}
{@end@}
```

#### HTML List Example

```html
<ul>
{@tasks:task@}
<li>
  <a href="https://example.com/{{task.id}}">{{task.title}}</a>
  - Status: {{task.status}}
</li>
{@end@}
</ul>
```

---

## Common Patterns

| Pattern | Template | Use Case |
|---------|----------|----------|
| Severity Prefix | `{#severity:high\|HIGH-IMPACT: \|low\|Low Priority: \|else\|\|#}` | Add severity-based prefix to message |
| URL with Fallback | `{#task_url\|SF Task: {{task_url}}\|else\|SF Opp Link: {{opportunity_url}}\|#}` | Show task URL if available, otherwise opportunity URL |
| Empty Else | `{#severity:high\|URGENT\|else\|\|#}` | Show text only for specific value, nothing otherwise |

---

## Variable Formatting

| Type | Format/Details | Example |
|------|----------------|---------|
| Currency | Pre-formatted with $ and commas | $12,345.67 |
| Dates | Human-readable format | Dec 31, 2024, 9:54 PM |
| Percentages | Pre-converted (0.85 → 85) | 85 |

---
