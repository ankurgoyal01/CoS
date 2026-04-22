# Widget Patterns for Salesforce MCP Reviewer

These reusable HTML/CSS patterns should be adapted when rendering output from the sf-mcp-reviewer skill.
All patterns use CSS variables for dark-mode compatibility — never hardcode colors.

---

## Pattern 1 — Filterable Table with Developer Buttons

Use for: Automation changes, Apex class inventory.

Key elements:
- Filter buttons (pill shape) across the top — one per developer name + "All", "Valid", "Invalid"
- Table columns: Name + ID (stacked), Type badge, Modified By, Date, Valid badge
- Active filter = dark background on button
- Invalid rows highlighted in amber (using color-mix for subtle tint)
- Row hover state

```html
<style>
  .filter-btn { padding:4px 12px; border-radius:99px; font-size:12px; font-weight:500;
    border:1px solid var(--color-border-secondary); background:var(--color-background-primary);
    color:var(--color-text-secondary); cursor:pointer; transition:background .15s; }
  .filter-btn.active { background:var(--color-text-primary); color:var(--color-background-primary);
    border-color:var(--color-text-primary); }
  .tbl { width:100%; border-collapse:collapse; font-size:13px; }
  .tbl th { text-align:left; font-weight:500; font-size:11px; color:var(--color-text-secondary);
    padding:6px 10px; border-bottom:1px solid var(--color-border-tertiary);
    text-transform:uppercase; letter-spacing:.04em; }
  .tbl td { padding:9px 10px; border-bottom:1px solid var(--color-border-tertiary);
    color:var(--color-text-primary); vertical-align:middle; }
  .tbl tr:last-child td { border-bottom:none; }
  .tbl tr:hover td { background:var(--color-background-secondary); }
  .b-valid { background:var(--color-background-success); color:var(--color-text-success); }
  .b-invalid { background:var(--color-background-danger); color:var(--color-text-danger); }
  .b-warn { background:var(--color-background-warning); color:var(--color-text-warning); }
  .b-info { background:var(--color-background-info); color:var(--color-text-info); }
  .b-gray { background:var(--color-background-secondary); color:var(--color-text-secondary); }
  .highlight td { background:color-mix(in srgb, var(--color-background-warning) 30%, transparent); }
  .highlight:hover td { background:color-mix(in srgb, var(--color-background-warning) 50%, transparent) !important; }
  .cls-name { font-weight:500; font-size:13px; }
  .cls-id { font-size:11px; color:var(--color-text-tertiary); margin-top:1px; }
  .badge { display:inline-block; padding:2px 7px; border-radius:99px; font-size:11px; font-weight:500; }
</style>
```

---

## Pattern 2 — Two-Tab View (This Week / Full Inventory)

Use for: Object automation deep-dive, layout changes.

Key elements:
- Two pill-shaped tabs at top, toggling visibility of two `<div>` sections
- "This week" tab highlights changed rows in amber
- "Full inventory" tab has type + validity filters

```javascript
function switchTab(tab, btn) {
  document.querySelectorAll('.tab').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  document.getElementById('view-week').style.display = tab === 'week' ? '' : 'none';
  document.getElementById('view-all').style.display = tab === 'all' ? '' : 'none';
  if (tab === 'all') renderAll();
}
```

---

## Pattern 3 — Alert Banners

Use at the top of widgets to surface counts or warnings.

```html
<!-- Info (blue): record count, summary -->
<div style="background:var(--color-background-info);color:var(--color-text-info);
  border-radius:8px;padding:10px 14px;font-size:13px;margin-bottom:14px;">
  <strong>N changes found</strong> — brief summary here.
</div>

<!-- Warning (amber): permissions gap, invalid classes, risk -->
<div style="background:var(--color-background-warning);color:var(--color-text-warning);
  border-radius:8px;padding:10px 14px;font-size:13px;margin-top:16px;">
  <strong>Permissions note:</strong> The connected user may lack <code>View Setup and Configuration</code>.
  Data sourced from SetupAuditTrail via SOQL fallback.
</div>
```

---

## Pattern 4 — Section Headers (within a single widget)

Use when one widget has multiple logical sections (e.g. "Direct Opportunity Changes" + "Related").

```html
<div style="font-size:11px;font-weight:500;text-transform:uppercase;letter-spacing:.05em;
  color:var(--color-text-secondary);padding:8px 10px 4px;
  border-bottom:1px solid var(--color-border-tertiary);
  background:var(--color-background-secondary);">
  Section Title
</div>
```

---

## Pattern 5 — Record Table (Data Queries)

Use for: Accounts, Opportunities, Cases, Contacts output.

```html
<!-- Header row with count -->
<div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:12px;">
  <span style="font-size:15px;font-weight:500;color:var(--color-text-primary)">
    Object Name — Period
  </span>
  <span style="font-size:12px;color:var(--color-text-secondary)">N records</span>
</div>
```

Record name cell pattern (name bold + ID muted below):
```html
<td>
  <div style="font-weight:500;font-size:13px">Record Name</div>
  <div style="font-size:11px;color:var(--color-text-tertiary);margin-top:1px">001XX000000XXXXX</div>
</td>
```

---

## Correlation Callout

After rendering a widget, add a prose callout (outside the widget) if you detect a developer
making related changes across multiple tools on the same day:

> "Note: **Amit Patil** edited both `Opportunity MD_NA Layout` and `Opportunity Work Item Layout`
> within 4 minutes on Mar 7 — this appears to be a single coordinated deployment session."

This is the highest-value insight the skill can provide and should never be skipped when the
pattern is present.
