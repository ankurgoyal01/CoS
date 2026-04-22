# Jira REST API Integration Guide

## Authentication

All requests use **HTTP Basic Auth**:
- Username: `agoyal@groupon.com`
- Password: `<JIRA_API_KEY>` (provided by user at session start)

```javascript
const headers = {
  "Authorization": "Basic " + btoa("agoyal@groupon.com:" + JIRA_API_KEY),
  "Content-Type": "application/json",
  "Accept": "application/json"
};
const BASE_URL = "https://groupondev.atlassian.net";
```

---

## Reading a Jira Issue

```
GET /rest/api/3/issue/{issueKey}
```

**Example:**
```
GET https://groupondev.atlassian.net/rest/api/3/issue/SFDC-100
```

**Key fields to extract from response:**
- `fields.summary` — ticket title
- `fields.description` — ADF (Atlassian Document Format) content; parse `.content[].content[].text` recursively
- `fields.issuetype.name` — issue type
- `fields.priority.name` — priority
- `fields.status.name` — current status
- `fields.assignee.displayName`
- `fields.labels`

---

## Creating a Jira Task

```
POST /rest/api/3/issue
```

**Request body:**
```json
{
  "fields": {
    "project": { "key": "SFDC" },
    "summary": "<Clear action-oriented title>",
    "issuetype": { "name": "Task" },
    "description": {
      "type": "doc",
      "version": 1,
      "content": [
        {
          "type": "heading",
          "attrs": { "level": 3 },
          "content": [{ "type": "text", "text": "Background" }]
        },
        {
          "type": "paragraph",
          "content": [{ "type": "text", "text": "<background text>" }]
        },
        {
          "type": "heading",
          "attrs": { "level": 3 },
          "content": [{ "type": "text", "text": "Implementation Details" }]
        },
        {
          "type": "paragraph",
          "content": [{ "type": "text", "text": "<implementation details>" }]
        },
        {
          "type": "heading",
          "attrs": { "level": 3 },
          "content": [{ "type": "text", "text": "Acceptance Criteria" }]
        },
        {
          "type": "bulletList",
          "content": [
            {
              "type": "listItem",
              "content": [{
                "type": "paragraph",
                "content": [{ "type": "text", "text": "<criterion 1>" }]
              }]
            }
          ]
        }
      ]
    },
    "labels": ["sfdc-auto-generated"]
  }
}
```

**Response:** Extract `key` (e.g., `SFDC-123`) and `id` (numeric) from the response body.

---

## Finding the Sprint ID

To move a ticket to a sprint, you need the sprint's numeric ID first.

### Step 1: Get the Board ID for SFDC project
```
GET /rest/agile/1.0/board?projectKeyOrId=SFDC
```
Extract `values[0].id` as `BOARD_ID`.

### Step 2: Find the sprint named "Ready for Grooming/Estimation"
```
GET /rest/agile/1.0/board/{BOARD_ID}/sprint?state=active,future
```

Loop through `values[]` and find the sprint where `name == "Ready for Grooming/Estimation"`.
Extract its `id` as `SPRINT_ID`.

> **If not found in active/future sprints**, try:
> ```
> GET /rest/agile/1.0/board/{BOARD_ID}/sprint?state=future
> ```
> If still not found, list all sprint names to the user and ask them to confirm the correct one.

---

## Attaching a File to an Issue

After creating the Jira ticket and generating the `.docx` TDD file, attach the file using a multipart form upload.

```
POST /rest/api/3/issue/{issueKey}/attachments
```

**Headers** (note: different from other calls — no `Content-Type: application/json`):
```
Authorization: Basic <base64(email:api_key)>
X-Atlassian-Token: no-check
Content-Type: multipart/form-data
```

> ⚠️ **The `X-Atlassian-Token: no-check` header is required.** Without it, Jira rejects file uploads with a 403 XSRF error.

### In JavaScript (Node.js / browser fetch with FormData):
```javascript
const fs = require('fs');
const FormData = require('form-data');

const form = new FormData();
form.append('file', fs.createReadStream('/path/to/TDD_filename.docx'), {
  filename: 'TDD_filename.docx',
  contentType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
});

const response = await fetch(
  `https://groupondev.atlassian.net/rest/api/3/issue/${issueKey}/attachments`,
  {
    method: 'POST',
    headers: {
      'Authorization': 'Basic ' + Buffer.from(`agoyal@groupon.com:${JIRA_API_KEY}`).toString('base64'),
      'X-Atlassian-Token': 'no-check',
      ...form.getHeaders()
    },
    body: form
  }
);
```

### In bash (curl):
```bash
curl -X POST \
  "https://groupondev.atlassian.net/rest/api/3/issue/SFDC-123/attachments" \
  -H "Authorization: Basic $(echo -n 'agoyal@groupon.com:API_KEY' | base64)" \
  -H "X-Atlassian-Token: no-check" \
  -F "file=@/path/to/TDD_filename.docx"
```

**Success response:** HTTP 200 with an array of attachment metadata including `id`, `filename`, `size`, and `content` (download URL).

### Attaching to multiple tickets:
Loop through each created issue key and repeat the attachment call. The same file can be attached to multiple tickets — each gets its own copy in Jira.

```javascript
for (const issueKey of createdIssueKeys) {
  await attachFileToIssue(issueKey, tddFilePath);
}
```

### Error handling:
| Code | Cause | Fix |
|---|---|---|
| 403 | Missing `X-Atlassian-Token` header | Add `X-Atlassian-Token: no-check` |
| 404 | Issue not found | Confirm issue key is correct |
| 413 | File too large | Jira default max is 10MB; check instance settings |

---

## Moving Issues to a Sprint

Once you have `SPRINT_ID` and the issue key(s):

```
POST /rest/agile/1.0/sprint/{SPRINT_ID}/issue
```

**Request body:**
```json
{
  "issues": ["SFDC-123", "SFDC-124"]
}
```

**Success response:** HTTP 204 No Content

> **Note:** This requires the Jira Software (agile) API, not just the core REST API.
> If you get a 404, check that the board type is `scrum` (not `kanban`).

---

## Error Reference

| HTTP Code | Meaning | Action |
|---|---|---|
| 400 | Bad request / invalid field | Log the error body and check field names |
| 401 | Unauthorized | Ask user to re-confirm API key and email |
| 403 | Forbidden | User may lack create/edit permissions on SFDC project |
| 404 | Not found | Check project key, issue key, or sprint ID |
| 422 | Unprocessable entity | ADF format issue in description — simplify the doc structure |

---

## Jira Description: Plain Text Fallback

If ADF formatting causes errors, use this simpler plain paragraph structure:

```json
{
  "type": "doc",
  "version": 1,
  "content": [
    {
      "type": "paragraph",
      "content": [{ "type": "text", "text": "**Background**\n<text>\n\n**Implementation Details**\n<text>\n\n**Acceptance Criteria**\n- <criterion 1>\n- <criterion 2>" }]
    }
  ]
}
```
