---
service: "coffee-to-go"
title: "User Authentication Flow"
generated: "2026-03-03"
type: flow
flow_name: "user-authentication"
flow_type: synchronous
trigger: "User clicks sign-in button"
participants:
  - "salesRep"
  - "coffeeWeb"
  - "coffeeApi"
  - "googleOAuth"
  - "coffeeDb"
---

# User Authentication Flow

## Summary

A Groupon employee authenticates with the application using their Google Workspace account. The frontend initiates an OAuth 2.0 flow via Better Auth. The backend validates the user's email domain (must be `groupon.com`), creates or updates the user record, establishes a session, and sets a secure cookie. OAuth tokens (accessToken, idToken, refreshToken) are stripped before being stored in the database for security.

## Trigger

- **Type**: user-action
- **Source**: User clicks the Google sign-in button on the login page
- **Frequency**: On demand; once per session (sessions persist until expiry)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Sales Representative / Administrator | Initiates sign-in | `salesRep` / `administrator` |
| React Web Application | Presents login page and manages auth client state | `coffeeWeb` |
| Express API | Handles Better Auth endpoints, validates email domain | `coffeeApi` |
| Google OAuth 2.0 | Provides OpenID Connect authentication | `googleOAuth` |
| Coffee DB | Stores user, session, and account records | `coffeeDb` |

## Steps

1. **User clicks sign-in**: The user navigates to the login page and clicks the Google sign-in button.
   - From: `salesRep`
   - To: `coffeeWeb` (Auth Components)
   - Protocol: User interaction

2. **Frontend initiates OAuth flow**: The Better Auth client redirects the browser to Google's OAuth consent screen with `prompt: select_account`.
   - From: `coffeeWeb` (Auth Client)
   - To: `googleOAuth`
   - Protocol: OAuth 2.0 (HTTPS redirect)

3. **User authenticates with Google**: The user selects their Groupon Google account and grants consent.
   - From: `googleOAuth`
   - To: `coffeeWeb` (redirect back with authorization code)
   - Protocol: OAuth 2.0 (HTTPS redirect)

4. **Backend exchanges code for tokens**: Better Auth on the API server exchanges the authorization code with Google for user profile information.
   - From: `coffeeApi` (Better Auth / Auth handler at `/api/auth/*`)
   - To: `googleOAuth`
   - Protocol: HTTPS

5. **Email domain validation**: The `databaseHooks.user.create.before` hook validates that the user's email domain is in the `ALLOWED_EMAIL_DOMAINS` list. If the domain is not allowed, a `ForbiddenError` is thrown.
   - From: `coffeeApi` (Better Auth hooks)
   - To: `coffeeApi` (validators)
   - Protocol: Direct

6. **User and session creation**: Better Auth creates or updates the user record and account record in the database. OAuth tokens (accessToken, idToken, refreshToken) are removed from the account record before storage. A session is created.
   - From: `coffeeApi` (Better Auth)
   - To: `coffeeDb` (auth_user, auth_session, auth_account tables)
   - Protocol: PostgreSQL

7. **Session cookie set**: A secure session cookie (`__Secure-coffee.session_token`) is set on the response. In production, cross-subdomain cookies are enabled for `groupondev.com`.
   - From: `coffeeApi`
   - To: `coffeeWeb` (browser)
   - Protocol: HTTPS (Set-Cookie header)

8. **Frontend updates auth state**: The Auth Client detects the session and updates the application state. The user is redirected to the deals page.
   - From: `coffeeWeb` (Auth Client)
   - To: `coffeeWeb` (Router)
   - Protocol: React state

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Non-Groupon email domain | `ForbiddenError` thrown in database hook with code `DOMAIN_NOT_ALLOWED` | User sees "Only Groupon employees can access this application" |
| Google OAuth failure | Better Auth returns error | User remains on login page with error |
| Session validation failure | Auth middleware returns 401 (`SESSION_NOT_FOUND`) | User is redirected to login |

## Sequence Diagram

```
User -> CoffeeWeb: Click "Sign in with Google"
CoffeeWeb -> GoogleOAuth: Redirect to consent screen
User -> GoogleOAuth: Select account, grant consent
GoogleOAuth -> CoffeeWeb: Redirect with auth code
CoffeeWeb -> CoffeeApi: POST /api/auth/callback/google
CoffeeApi -> GoogleOAuth: Exchange code for tokens
GoogleOAuth --> CoffeeApi: User profile + tokens
CoffeeApi -> CoffeeApi: Validate email domain
CoffeeApi -> CoffeeDb: Create/update user, session (tokens stripped)
CoffeeDb --> CoffeeApi: OK
CoffeeApi --> CoffeeWeb: Set-Cookie (session token)
CoffeeWeb --> User: Redirect to deals page
```

## Related

- Related flows: [Deal Search](deal-search.md)
