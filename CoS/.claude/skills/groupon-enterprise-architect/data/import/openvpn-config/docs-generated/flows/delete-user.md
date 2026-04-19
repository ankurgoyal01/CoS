---
service: "openvpn-config"
title: "Delete User"
generated: "2026-03-03"
type: flow
flow_name: "delete-user"
flow_type: synchronous
trigger: "Manual operator invocation of delete_user.py with a user email address argument"
participants:
  - "openvpnDeleteUserJob"
  - "openvpnApiClientComponent"
architecture_ref: "components-openvpnConfigAutomation"
---

# Delete User

## Summary

The delete user flow permanently removes a specific user account from the OpenVPN Cloud Connexa tenant by email address. The operator provides the target email as a CLI argument; the script validates the email format, resolves the user ID from the live Cloud Connexa user list, and issues a DELETE request. This flow is used as part of offboarding and access revocation processes.

## Trigger

- **Type**: manual
- **Source**: InfoSec operator running `python3 delete_user.py user@groupon.com`
- **Frequency**: On-demand — invoked per user offboarding or access revocation event

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Delete User Job | Validates input, resolves user, issues delete | `openvpnDeleteUserJob` |
| OpenVPN API Client | Provides OAuth token acquisition, user listing, and DELETE request | `openvpnApiClientComponent` |
| OpenVPN Cloud Connexa API | User store — source for lookup and target for deletion | `unknown_openvpncloudconnexa_10bbc2fe` |

## Steps

1. **Validate CLI argument**: Script checks that exactly one argument is provided; if not, prints usage to stderr and exits with code 1.
   - From: `openvpnDeleteUserJob`
   - To: `sys.argv`
   - Protocol: direct

2. **Validate email format**: Applies the regex `[A-Za-z0-9._-]+@([A-Za-z0-9-]+\.)+[A-Za-z]{2,7}` via `re.fullmatch`. If invalid, prints error and exits with code 2.
   - From: `openvpnDeleteUserJob`
   - To: input string
   - Protocol: direct

3. **Acquire OAuth token**: Calls `get_oauth_token(*get_credentials(base_domain))`. See [OAuth Token Acquisition](oauth-token-acquisition.md).
   - From: `openvpnDeleteUserJob`
   - To: `openvpnApiClientComponent`
   - Protocol: Python function call

4. **List all users**: Calls `list_entities(base_domain, headers, 'users', 'email')` to retrieve a dict of all Cloud Connexa users keyed by email, paginated in pages of 1000.
   - From: `openvpnApiClientComponent`
   - To: Cloud Connexa `GET /api/beta/users/page?page={n}&size=1000`
   - Protocol: HTTPS/GET

5. **Resolve user by email**: Performs case-sensitive lookup first; if not found, falls back to case-insensitive comparison against all user emails.
   - From: `openvpnDeleteUserJob`
   - To: in-process dict
   - Protocol: direct

6. **Issue DELETE request**: Calls `make_api_call(requests.delete, base_domain + '/api/beta/users/{user_id}', headers=headers)` with the resolved user ID.
   - From: `openvpnApiClientComponent`
   - To: Cloud Connexa `DELETE /api/beta/users/{user_id}`
   - Protocol: HTTPS/DELETE

7. **Confirm deletion**: Prints `Deleted user '{user_id}' with email '{target_email}'.` to stderr.
   - From: `openvpnDeleteUserJob`
   - To: operator (stderr)
   - Protocol: CLI output

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing CLI argument | Print usage to stderr; `exit(1)` | Script terminates without API call |
| Invalid email format | Print format error to stderr; `exit(2)` | Script terminates without API call |
| User not found (case-insensitive search exhausted) | Print "Couldn't find an OpenVPN user with that email." to stderr; return without error | No deletion performed; script exits cleanly |
| HTTP 429 on user list or DELETE | `make_api_call` sleeps for `x-ratelimit-replenish-time` seconds and retries | Operation continues after backoff |
| HTTP 4xx/5xx on DELETE | `raise_for_status()` prints diagnostic context to stderr | Script terminates with exception |
| Missing environment variables | `KeyError` from `os.environ[...]` | Script terminates with unhandled exception |

## Sequence Diagram

```
Operator       -> delete_user.py:                    python3 delete_user.py user@groupon.com
delete_user    -> delete_user.is_valid_email:        Validate email regex
delete_user    -> openvpn_api.get_oauth_token:       Obtain Bearer token
delete_user    -> openvpn_api.list_entities:         GET /api/beta/users/page (paginated)
CloudConnexa   --> list_entities:                    All users dict keyed by email
list_entities  --> delete_user:                      Users dict
delete_user    -> delete_user:                       Resolve target_user by email (case-insensitive)
delete_user    -> openvpn_api.make_api_call:         DELETE /api/beta/users/{user_id}
CloudConnexa   --> make_api_call:                    204 No Content
delete_user    -> stderr:                            "Deleted user '{id}' with email '{email}'."
```

## Related

- Architecture dynamic view: `components-openvpnConfigAutomation`
- Related flows: [OAuth Token Acquisition](oauth-token-acquisition.md), [Export Backup](export-backup.md)
