---
service: "openvpn-config"
title: "OAuth Token Acquisition"
generated: "2026-03-03"
type: flow
flow_name: "oauth-token-acquisition"
flow_type: synchronous
trigger: "Any automation script invocation (export, restore, or delete user)"
participants:
  - "openvpnApiClientComponent"
  - "OpenVPN Cloud Connexa OAuth endpoint"
architecture_ref: "components-openvpnConfigAutomation"
---

# OAuth Token Acquisition

## Summary

Every automation script (export, restore, delete user) begins by acquiring a short-lived Bearer token from the OpenVPN Cloud Connexa OAuth endpoint using OAuth 2.0 client credentials grant. The token is obtained once per script invocation and reused for all subsequent API calls within that session. This flow is implemented in `openvpn_api.py` and called as the first step in all three entry-point scripts.

## Trigger

- **Type**: api-call
- **Source**: Operator invoking any of the three CLI scripts (`export_backup.py`, `restore_backup.py`, `delete_user.py`)
- **Frequency**: Once per script invocation (on-demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| OpenVPN API Client | Constructs token request and parses the response | `openvpnApiClientComponent` |
| OpenVPN Cloud Connexa OAuth | Issues Bearer access tokens for valid client credentials | `unknown_openvpncloudconnexa_10bbc2fe` |

## Steps

1. **Read credentials from environment**: The calling script invokes `get_credentials(base_domain)`, which reads `OPENVPN_API`, `OPENVPN_CLIENT_ID`, and `OPENVPN_CLIENT_SECRET` from environment variables and constructs the token endpoint URL: `<OPENVPN_API>/api/beta/oauth/token`.
   - From: `openvpnApiClientComponent` (get_credentials)
   - To: OS environment
   - Protocol: direct

2. **POST token request**: `get_oauth_token()` calls `make_api_call(requests.post, auth_server_url, auth=(client_id, client_secret), data={'grant_type': 'client_credentials'})`. The request uses HTTP Basic authentication with `client_id` and `client_secret`.
   - From: `openvpnApiClientComponent`
   - To: Cloud Connexa `/api/beta/oauth/token`
   - Protocol: HTTPS/POST (application/x-www-form-urlencoded)

3. **Handle rate limit (if applicable)**: If the response is HTTP 429, `make_api_call` sleeps for `x-ratelimit-replenish-time` seconds and retries the POST.
   - From: `openvpnApiClientComponent`
   - To: `openvpnApiClientComponent` (retry loop)
   - Protocol: internal

4. **Parse token response**: On HTTP 200, the JSON response is deserialised and `tokens['access_token']` is extracted and returned to the calling script.
   - From: Cloud Connexa OAuth endpoint
   - To: `openvpnApiClientComponent`
   - Protocol: HTTPS/JSON response

5. **Construct Authorization header**: The calling script wraps the token in `{'authorization': 'Bearer ' + token}` and passes this headers dict to all subsequent API calls.
   - From: calling script
   - To: subsequent `make_api_call` invocations
   - Protocol: Python dict (in-process)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| HTTP 429 Too Many Requests | Sleep for `x-ratelimit-replenish-time` seconds, then retry | Retries until non-429 response received |
| HTTP 401 Unauthorized | `raise_for_status()` prints request args, response headers, and body to stderr | Script terminates with exception |
| HTTP 4xx / 5xx | `raise_for_status()` prints diagnostic context to stderr | Script terminates with exception |
| Invalid JSON response | `json.loads` exception propagates; empty dict returned by `make_api_call` try/except | Downstream code receives empty dict; may cause KeyError on `access_token` |
| Missing environment variable | `os.environ[...]` raises `KeyError` | Script terminates with unhandled exception |

## Sequence Diagram

```
Operator         -> Script:                     Invoke script with env vars set
Script           -> openvpn_api.get_credentials: Read OPENVPN_API, OPENVPN_CLIENT_ID, OPENVPN_CLIENT_SECRET
Script           -> openvpn_api.get_oauth_token: Call with auth_server_url, client_id, client_secret
get_oauth_token  -> CloudConnexa /api/beta/oauth/token: POST grant_type=client_credentials (HTTP Basic auth)
CloudConnexa     --> get_oauth_token:           200 OK {"access_token": "...", ...}
get_oauth_token  --> Script:                    Return access_token string
Script           -> Script:                     Build headers = {"authorization": "Bearer <token>"}
```

## Related

- Architecture dynamic view: `dynamic-openvpnBackupRestoreFlow`
- Related flows: [Export Backup](export-backup.md), [Restore Backup](restore-backup.md), [Delete User](delete-user.md)
