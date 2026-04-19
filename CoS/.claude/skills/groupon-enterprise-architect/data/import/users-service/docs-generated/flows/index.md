---
service: "users-service"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 8
---

# Flows

Process and flow documentation for Users Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Account Creation](account-creation.md) | synchronous | `POST /v1/accounts` | New user registration with optional Identity Service delegation and event publishing |
| [Authentication](authentication.md) | synchronous | `POST /v1/authentication` | Credential or social OAuth login; issues session token and publishes auth event |
| [Password Reset](password-reset.md) | synchronous | `POST /v1/password_resets` | Self-service password reset initiation and completion via email token |
| [Forced Password Reset](forced-password-reset.md) | event-driven | `bemod.suspiciousBehavior` event | Security-triggered batch credential invalidation and user notification |
| [Email Verification](email-verification.md) | synchronous | `POST /v1/email_verifications` | Nonce-based email address verification flow |
| [Third-Party Linking](third-party-linking.md) | synchronous | `POST /v1/third_party_links` | Link or unlink a Google / Facebook / Apple identity to an existing account |
| [Account Deactivation and Erasure](account-deactivation-erasure.md) | synchronous | `DELETE /v1/accounts/:id` or `POST /erasure` | Account deactivation and GDPR erasure with event publishing |
| [Device Notification Batch](device-notification-batch.md) | batch | Resque schedule | Detects new device authentications and sends notification emails |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- **Authentication Flow** spans `continuumUsersService`, `googleOAuth`, `continuumUsersFacebookGraphApi`, `continuumUsersAppleIdentityApi`, `continuumUsersDb`, `continuumUsersRedis`, `continuumUsersResqueWorkers`, and `continuumUsersMessageBusBroker`. Architecture dynamic view: `dynamic-users-continuumUsersServiceApi_tokenService-authentication-flow`.
- **Forced Password Reset Flow** spans `continuumUsersMessageBusConsumer`, `continuumUsersDb`, and `continuumUsersMailService` in response to events from the central `bemod.suspiciousBehavior` topic.
- **Event Publishing** for all account lifecycle events involves a cross-service path: `continuumUsersService` -> `continuumUsersResqueWorkers` -> `continuumUsersMessageBusBroker`.
