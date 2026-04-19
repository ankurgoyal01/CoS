---
service: "jira"
title: "SSO Authentication and User Provisioning"
generated: "2026-03-03"
type: flow
flow_name: "sso-authentication-user-provisioning"
flow_type: synchronous
trigger: "Inbound HTTPS request forwarded by apiProxy containing X-GRPN-SamAccountName and X-OpenID-Extras headers"
participants:
  - "apiProxy"
  - "continuumJiraService"
  - "gwallAuthenticator"
  - "jiraUserProvisioning"
  - "continuumJiraDatabase"
architecture_ref: "components-continuum-jira-service"
---

# SSO Authentication and User Provisioning

## Summary

Every HTTP request to Jira passes through the API proxy, which injects Groupon SSO identity headers before forwarding the request to the Jira Server. The custom `GwallAuthenticator` (a Seraph authenticator) intercepts each request, reads the identity headers, and establishes the authenticated session. If the user does not yet exist in Jira's database, the authenticator auto-provisions the account using profile data from the `X-OpenID-Extras` header. Legacy username mappings are resolved from a flat file on disk.

## Trigger

- **Type**: api-call (per-request)
- **Source**: End user browser or API client request forwarded by `apiProxy`
- **Frequency**: Per every HTTP request to Jira (session-cached after first authentication)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `apiProxy` | Injects SSO identity headers into every inbound request | `apiProxy` (stub) |
| `continuumJiraService` | Hosts the Seraph security filter that invokes `GwallAuthenticator` | `continuumJiraService` |
| `gwallAuthenticator` | Reads headers, checks session, delegates to provisioning | `gwallAuthenticator` |
| `jiraUserProvisioning` | Looks up user by username; creates user if absent; resolves legacy usernames | `jiraUserProvisioning` |
| `continuumJiraDatabase` | Stores and retrieves `cwd_user` records | `continuumJiraDatabase` |

## Steps

1. **Receives request with SSO headers**: The `apiProxy` forwards the inbound HTTPS request to `continuumJiraService` with `X-GRPN-SamAccountName` (the user's Active Directory username) and `X-OpenID-Extras` (URL-encoded email, firstname, lastname) headers attached.
   - From: `apiProxy`
   - To: `continuumJiraService`
   - Protocol: HTTPS

2. **Checks existing session**: `GwallAuthenticator.getUser()` is invoked by the Seraph filter. It first checks if an active session already exists (`DefaultAuthenticator.LOGGED_IN_KEY` in the HTTP session). If a session exists, returns the cached `Principal` immediately and skips remaining steps.
   - From: `gwallAuthenticator`
   - To: HTTP session (in-process)
   - Protocol: In-process method call

3. **Validates SSO headers are present**: Checks that both `X-GRPN-SamAccountName` and `X-OpenID-Extras` headers are non-null. If either is missing, falls back to the standard `JiraSeraphAuthenticator.getUser()` (redirects to `/login.jsp`).
   - From: `gwallAuthenticator`
   - To: `gwallAuthenticator` (self)
   - Protocol: In-process

4. **Extracts username from header**: Reads the `X-GRPN-SamAccountName` header value as the candidate Jira username.
   - From: `gwallAuthenticator`
   - To: `gwallAuthenticator` (self)
   - Protocol: In-process

5. **Checks if user exists in database**: Calls `UserUtil.userExists(username)`, which queries `continuumJiraDatabase` for a matching `cwd_user` record.
   - From: `jiraUserProvisioning`
   - To: `continuumJiraDatabase`
   - Protocol: JDBC/MySQL

6. **Resolves legacy username (if needed)**: If the current SSO username is not found in the database, searches `/var/groupon/jira/legacy_usernames.txt` line by line for a `current,legacy` mapping. If a match is found, substitutes the legacy username and retries user lookup.
   - From: `jiraUserProvisioning`
   - To: Filesystem (`/var/groupon/jira/legacy_usernames.txt`)
   - Protocol: File I/O

7. **Provisions new user (if needed)**: If neither the current nor any legacy username exists, calls `UserUtil.createUserNoNotification(username, "groupon", emailAddress, displayName, 1L)` to create the user in `continuumJiraDatabase` under Crowd directory ID 1. Email and display name are extracted from `X-OpenID-Extras`.
   - From: `jiraUserProvisioning`
   - To: `continuumJiraDatabase`
   - Protocol: JDBC/MySQL

8. **Establishes session**: Sets `DefaultAuthenticator.LOGGED_IN_KEY` in the HTTP session with the resolved `Principal`. Clears `LOGGED_OUT_KEY`. Returns the `Principal` to the Seraph filter, which grants access to the requested resource.
   - From: `gwallAuthenticator`
   - To: HTTP session (in-process)
   - Protocol: In-process

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| SSO headers absent | Falls back to `super.getUser()` (standard Jira login) | User redirected to `/login.jsp` |
| `UserUtil.userExists()` throws exception | `catch (Exception e)` block returns `null` principal | Seraph redirects to `login.url` configured in `seraph-config.xml` |
| `createUserNoNotification()` throws exception | Same `catch (Exception e)` block; logged at WARN in `gwall-authenticator.log` | User cannot access Jira; redirected to login page |
| Legacy username not found in flat file | Returns `null` from `getLegacyUsername()`; proceeds to user creation path | New user is created with SSO username |
| Simultaneous first-login race (duplicate user) | Exception caught and logged; returns `null` | User redirected to login; succeeds on retry |

## Sequence Diagram

```
apiProxy -> continuumJiraService: HTTPS request + X-GRPN-SamAccountName + X-OpenID-Extras
continuumJiraService -> gwallAuthenticator: getUser(request, response)
gwallAuthenticator -> gwallAuthenticator: Check session (LOGGED_IN_KEY)
alt Session exists
  gwallAuthenticator --> continuumJiraService: return cached Principal
else No session
  gwallAuthenticator -> gwallAuthenticator: Read X-GRPN-SamAccountName header
  gwallAuthenticator -> jiraUserProvisioning: userExists(username)
  jiraUserProvisioning -> continuumJiraDatabase: SELECT from cwd_user WHERE username=?
  continuumJiraDatabase --> jiraUserProvisioning: found/not found
  alt User not found
    jiraUserProvisioning -> filesystem: read legacy_usernames.txt
    alt Legacy mapping exists
      jiraUserProvisioning --> gwallAuthenticator: legacyUsername
    else No mapping
      jiraUserProvisioning -> continuumJiraDatabase: INSERT into cwd_user (createUserNoNotification)
    end
  end
  gwallAuthenticator -> gwallAuthenticator: Set LOGGED_IN_KEY in session
  gwallAuthenticator --> continuumJiraService: return Principal
end
continuumJiraService --> apiProxy: HTTP 200 (or redirect)
```

## Related

- Architecture component view: `components-continuum-jira-service`
- Related flows: [Issue Lifecycle](issue-lifecycle.md), [JQL Search](jql-search.md)
