# Org Context Resources

These two documents capture Groupon's Salesforce automation standards and architecture. **Always attempt to fetch both before generating any TDD** — they tell you what already exists in the org so the design you produce slots in cleanly rather than duplicating or conflicting with live automations.

---

## Resource 1 — Salesforce Sales Cloud Automations Document

| Field | Value |
|---|---|
| Title | Copy of Salesforce - Sales Cloud Automations [WIP] |
| Owner | Ankur Goyal (agoyal@groupon.com) |
| Google Drive ID | `1c0kFAkDpF_csE5VTe7nnnIr7EevHJ3Xe` |
| Direct URL | https://docs.google.com/document/d/1c0kFAkDpF_csE5VTe7nnnIr7EevHJ3Xe/edit |

### What it contains
A living catalogue of all active Flows, Process Builders, Apex Triggers, and automation rules in the Groupon Sales Cloud org. Use it to:
- Identify **existing automations** that already touch the same objects/fields as the new requirement
- Detect **conflicts or overlaps** (e.g., two record-triggered Flows on the same object with identical trigger criteria)
- Adopt **naming conventions** already established in the org
- Understand **governor limit exposure** from existing bulk automations before adding more

### How to fetch it
The file is stored as a `.docx` in Google Drive (not a native Google Doc), so `google_drive_fetch` cannot read it. Use **Claude in Chrome**:

```
1. Call navigate: https://docs.google.com/document/d/1c0kFAkDpF_csE5VTe7nnnIr7EevHJ3Xe/edit
2. Call get_page_text to extract the full document text
3. If Google prompts for sign-in, note the failure and proceed (see Fallback below)
```

### How to use it in the TDD
- **Section 2.2 (Flows & Process Builder)**: Cross-reference every proposed Flow against the catalogue. If an existing Flow already handles related logic, call it out — the implementation should extend or update that Flow rather than create a parallel one.
- **Section 2.3 (Apex)**: Check whether existing trigger handlers already fire on the same object/events. Note any handler classes the new Apex must integrate with.
- **Section 2.5 (Alignment with Org Automation Standards)**: Summarise what you found — list any overlapping automations and whether the proposed design is additive, a replacement, or an extension.
- **Section 3 (Implementation Approach)**: If existing automations must be deactivated or updated first, sequence that explicitly.

---

## Resource 2 — Salesforce Architecture Diagram

| Field | Value |
|---|---|
| Type | diagrams.net (draw.io) stored in Google Drive |
| Google Drive File ID | `16cDS_UksFWjQfZdXOjLy53tydRgHBROv` |
| Page ID | `M8cTidWuDQ0Hs0VfByAr` |
| Direct URL | https://app.diagrams.net/#G16cDS_UksFWjQfZdXOjLy53tydRgHBROv#%7B%22pageId%22%3A%22M8cTidWuDQ0Hs0VfByAr%22%7D |

### What it contains
A visual architecture diagram of the Groupon Salesforce org — object relationships, integration touchpoints, data flows, and system boundaries. Use it to:
- Verify new objects/fields are consistent with the existing data model
- Identify **integration points** (external systems, APIs, platform events) that the proposed change may touch or break
- Ensure new components follow established **architectural patterns**
- Spot **upstream/downstream dependencies** not obvious from the requirement text alone

### How to fetch it
diagrams.net renders as a web application and requires a browser. Use **Claude in Chrome**:

```
1. Call navigate: https://app.diagrams.net/#G16cDS_UksFWjQfZdXOjLy53tydRgHBROv#%7B%22pageId%22%3A%22M8cTidWuDQ0Hs0VfByAr%22%7D
2. Wait a few seconds for the diagram to fully render (it loads from Google Drive)
3. Use read_page or get_page_text to capture visible labels, object names, arrows, and annotations
4. If the diagram is behind a Google sign-in wall, note the failure and proceed (see Fallback below)
```

### How to use it in the TDD
- **Section 2.1 (Custom Objects & Fields)**: Confirm new objects/fields don't duplicate anything visible in the diagram's data model.
- **Section 2.3 (Apex)**: Flag integration touchpoints in the diagram that new Apex callouts or platform event listeners must not break.
- **Section 2.5 (Alignment with Org Automation Standards)**: Note how the proposed design fits into (or extends) the architecture — reference specific diagram elements by name where possible.
- **Section 3 (Implementation Approach)**: If the diagram shows an integration boundary the new work crosses, address deployment and testing strategy for that boundary.

---

## Fallback Behaviour

If either resource cannot be retrieved (Chrome unavailable, permissions error, Google sign-in wall):

1. Add a visible **⚠️ Warning block** near the top of the TDD:
   > *"The [document name] could not be retrieved automatically. The impact analysis below was completed without cross-referencing this resource. Please review manually before implementation begins."*

2. Add an **Open Question** in Section 6:
   > *"Please review [resource name] ([URL]) and confirm the proposed design does not conflict with existing automations / the current architecture."*

3. Continue generating all other TDD sections as normal — the warning makes the gap visible without blocking delivery.
