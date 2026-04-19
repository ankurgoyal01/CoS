---
service: "ckod-ui"
title: "SLO Dashboard Data Fetch"
generated: "2026-03-03"
type: flow
flow_name: "slo-dashboard-fetch"
flow_type: synchronous
trigger: "User navigates to an SLO dashboard page or applies date/filter controls"
participants:
  - "ckodUi_webUi"
  - "ckodUi_apiRoutes"
  - "authz"
  - "ckodUi_dataAccess"
  - "continuumCkodPrimaryMysql"
  - "continuumCkodAirflowMysql"
architecture_ref: "components-continuumCkodUi"
---

# SLO Dashboard Data Fetch

## Summary

This flow covers how SLO/SLA compliance data is fetched and rendered for any of the DataOps SLO dashboards. When an engineer navigates to a dashboard (e.g., `/slo_dashboard`, `/slo_trends`, or a platform-specific SLA view), the React page makes RTK Query API calls to the corresponding Next.js API route, which queries the appropriate MySQL SLA job detail table via `prismaRO` and returns a filtered list of job run records. The UI renders compliance status indicators and delay metrics.

## Trigger

- **Type**: user-action / api-call
- **Source**: Page load, date filter change, or manual refresh on any SLO dashboard page
- **Frequency**: On demand; RTK Query caches results for 10 minutes by default

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Web UI | Renders SLO dashboard; fires RTK Query hooks on mount or filter change | `ckodUi_webUi` |
| API Routes | Receives SLA job detail GET requests and returns filtered results | `ckodUi_apiRoutes` |
| Authentication and Authorization | Validates `x-grpn-email` header | `authz` |
| Data Access Layer | Executes Prisma queries against SLA job detail tables via `prismaRO` | `ckodUi_dataAccess` |
| CKOD Primary MySQL | Stores all SLA job detail records (Keboola, EDW, SEM, RM, OP, CDP, MDS Feeds) | `continuumCkodPrimaryMysql` |
| CKOD Airflow MySQL | Stores Airflow SLA monitoring records | `continuumCkodAirflowMysql` |

## Steps

1. **Page mount or filter change**: User navigates to an SLO dashboard or changes date/status filters. The React component dispatches RTK Query hooks (e.g., `useGetKeboolaSlaJobDetailQuery`, `useGetEdwSlaDetailsQuery`).
   - From: `ckodUi_webUi`
   - To: `ckodUi_webUi` (RTK Query cache check)
   - Protocol: Client-side React

2. **Cache miss — dispatch API call**: If no cached data exists or cache is expired, RTK Query issues a `GET` request to the appropriate API route (e.g., `GET /api/keboola-slo-job-detail?etl_date=2026-03-03&sla_status=delayed,failed`).
   - From: `ckodUi_webUi`
   - To: `ckodUi_apiRoutes`
   - Protocol: REST (HTTPS, internal)

3. **Validate authentication**: API route checks `x-grpn-email` header.
   - From: `ckodUi_apiRoutes`
   - To: `authz`
   - Protocol: Direct TypeScript module call

4. **Query SLA job detail table**: Data access layer executes a Prisma query on the appropriate `*_SLA_JOB_DETAIL` table with provided filter parameters (ETL date, date range, SLA status, definition key, project name).
   - From: `ckodUi_dataAccess`
   - To: `continuumCkodPrimaryMysql` (or `continuumCkodAirflowMysql` for Airflow)
   - Protocol: Prisma / MySQL

5. **Return job detail records**: MySQL returns the filtered job run records. The API route serialises these to JSON.
   - From: `continuumCkodPrimaryMysql`
   - To: `ckodUi_apiRoutes`
   - Protocol: MySQL result set

6. **Deliver response to UI**: API route returns `{ data: [...] }` JSON. RTK Query stores the result in the Redux cache.
   - From: `ckodUi_apiRoutes`
   - To: `ckodUi_webUi`
   - Protocol: REST (JSON)

7. **Render dashboard**: React components consume the cached data to render SLA status badges (`on-time`, `delayed`, `failed`, `missing`, `in-progress`, etc.), delay metrics (`DELAYED_BY` in minutes), and trend charts.
   - From: `ckodUi_webUi`
   - To: browser DOM
   - Protocol: React render

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Authentication header missing | Returns HTTP 401 | UI shows "Access Denied" page or error toast |
| MySQL read-only connection failure | Prisma throws; API returns HTTP 500 | UI shows error message; dashboard empty |
| No records for selected date | Query returns empty array | UI renders "no data" empty state |
| RTK Query timeout | RTK Query retries once automatically | If still failing, UI shows error state |

## Sequence Diagram

```
Web UI -> API Routes: GET /api/keboola-slo-job-detail?etl_date=2026-03-03&sla_status=delayed,failed
API Routes -> authz: Validate x-grpn-email
authz --> API Routes: Authorised
API Routes -> ckodUi_dataAccess: prismaRO.kEBOOLA_SLA_JOB_DETAIL.findMany({ where: { ETL_DATE, SLA_STATUS } })
ckodUi_dataAccess -> continuumCkodPrimaryMysql: SELECT ... FROM KEBOOLA_SLA_JOB_DETAIL WHERE ETL_DATE=... AND SLA_STATUS IN (...)
continuumCkodPrimaryMysql --> ckodUi_dataAccess: Result rows
ckodUi_dataAccess --> API Routes: [SLAJobDetail, ...]
API Routes --> Web UI: { data: [SLAJobDetail, ...] }
Web UI -> Web UI: Render SLO status indicators and charts
```

## Related

- Related flows: [SLO Definition Management](slo-definition-management.md)
- See [Data Stores](../data-stores.md) for SLA job detail table schemas
- See [API Surface](../api-surface.md) for SLO endpoint filter parameters
