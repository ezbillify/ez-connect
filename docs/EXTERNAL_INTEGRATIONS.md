# External Integration Guide

This document describes how to enable token-based integrations so that approved third-party systems can create and manage support tickets through secured Supabase APIs.

## Overview

The external integration layer introduces:

1. **Database infrastructure** for storing and auditing integration tokens
2. **Security-definer SQL functions** and **Supabase Edge Functions** that act on behalf of external systems while respecting Row Level Security (RLS)
3. **RESTful endpoints** that allow external systems to create tickets, fetch ticket status, and append comments
4. **Rate limiting and auditing** so that abusive clients can be throttled or suspended
5. **Flutter admin tooling** to issue, revoke, regenerate, and monitor integration tokens
6. **Reference clients and documentation** to simplify onboarding for partners

## Database Setup

Execute [`supabase/sql/integration_tokens.sql`](../supabase/sql/integration_tokens.sql) against your Supabase Postgres database. The script creates:

- `integration_tokens` – Stores salted API tokens (hashed) and metadata
- `integration_token_usage` – Stores every inbound request for auditing and rate limiting
- `tickets` and `ticket_comments` (if they do not exist) – Enhanced with `integration_source` columns to track API-originated records
- Security-definer helper functions:
  - `validate_integration_token`
  - `log_integration_token_usage`
  - `create_ticket_via_integration`
  - `add_ticket_comment_via_integration`
  - `update_ticket_status_via_integration`
- RLS policies that:
  - Restrict token visibility to the owning user (typically an administrator)
  - Ensure token usage logs are only visible to token owners
  - Maintain consistency with ticketing rules (only creators/assignees or owning integrations may access records)
- Helper views: `integration_token_stats` & `recent_token_usage` for dashboard data

### Applying the Migration

```bash
supabase db push --file supabase/sql/integration_tokens.sql
```

> **Note:** The script uses `gen_random_uuid()` and the `digest` function. Ensure the `pgcrypto` extension is enabled: `create extension if not exists pgcrypto;`

## Edge Function Deployment

The Edge Function lives at `supabase/functions/integration-tickets/index.ts` and exposes REST endpoints. Deploy it using the Supabase CLI:

```bash
supabase functions deploy integration-tickets \
  --env-file supabase/functions/.env
```

Required environment variables:

- `SUPABASE_URL` – Project URL
- `SUPABASE_SERVICE_ROLE_KEY` – Service role key with RPC execution rights on the security-definer functions

### Endpoint Summary

| Method | Path | Description |
| ------ | ---- | ----------- |
| GET | `/` | Health check + discovery |
| POST | `/tickets` | Creates a ticket via `create_ticket_via_integration` |
| GET | `/tickets/:id` | Retrieves a ticket (scoped to token owner) |
| POST | `/tickets/:id/comments` | Adds a comment to the ticket |
| PATCH | `/tickets/:id/status` | Updates ticket `status` |

### Request Authentication

All endpoints require a `Bearer` token with an integration token value issued from the Flutter admin UI. Tokens are hashed server-side; the full token value is shown only once at creation.

### Rate Limiting

Each token has a `rate_limit_per_hour`. During validation, the Edge Function invokes `validate_integration_token` which rejects requests once the hourly allowance is exceeded, returning HTTP `429` (Too Many Requests).

### Token Revocation

Tokens can be disabled or revoked from the admin UI. `validate_integration_token` returns HTTP `401` for disabled tokens and `401` with `Token has expired` when past `expires_at`.

## Flutter Admin Interface

Navigate to **Settings → Integration Tokens** (visible to users with the `admin` role).

Capabilities:

- **Create tokens** (assign name, description, rate limits, optional expiry)
- **Regenerate tokens** (produces a new secret and invalidates the prior one)
- **Enable/disable tokens** (soft revocation)
- **Delete tokens** (permanent removal)
- **View usage logs** (last 100 requests + aggregated stats)

Implementation details:

- `lib/domain/models/integration_token.dart`
- `lib/domain/repositories/integration_token_repository.dart`
- `lib/data/datasources/supabase_integration_token_datasource.dart`
- `lib/data/repositories/integration_token_repository_impl.dart`
- `lib/presentation/providers/integration_token_provider.dart`
- `lib/presentation/screens/integration_tokens/`

## Example Clients

Sample integrations are provided under [`examples/`](../examples):

- `integration_examples.sh` – `curl` scripts
- `integration_client.js` – Node.js client
- `integration_client.py` – Python client

Set the following environment variables:

```bash
export INTEGRATION_TOKEN="<token-from-admin-ui>"
export INTEGRATION_URL="https://<project>.supabase.co/functions/v1/integration-tickets"
```

## Security Considerations

- **Never store tokens in plaintext**: The database retains SHA-256 hashes only.
- **Display tokens once**: The admin UI shows the full token only immediately after creation/regeneration.
- **Enforce HTTPS**: Edge functions should be accessed via HTTPS only; Supabase enforces this in production.
- **Principle of least privilege**: Tokens have optional `allowed_endpoints` to limit access (future-proof). Extend the Edge Function to enforce endpoint whitelists when needed.
- **Audit trails**: `integration_token_usage` stores IP, user-agent, status codes, response times, and payload samples for forensics.
- **Rate limiting**: Enforced at validation time; consider adding additional safeguards via WAF/CDN.
- **Token expiry**: Prefer short-lived tokens with rotation policies. Automate reminders using the `expires_at` field.

## Rolling Out to Production

1. Apply the SQL migration (ideally via scripted migration pipeline).
2. Deploy the Edge Function with production environment variables.
3. Assign the `admin` role to staff who should manage tokens.
4. Use the Flutter admin screen to create tokens for partner systems.
5. Distribute integration tokens over secure channels; they cannot be retrieved later.
6. Monitor usage via the admin UI or directly from `integration_token_usage`.

## Troubleshooting

| Symptom | Possible Cause | Resolution |
| ------- | -------------- | ---------- |
| HTTP 401 "Invalid token" | Token disabled, revoked, or incorrect | Regenerate token, ensure client uses updated secret |
| HTTP 429 "Rate limit exceeded" | Hourly limit reached | Increase `rate_limit_per_hour` or slow client down |
| HTTP 500 from Edge Function | Missing environment variables; RPC permissions | Verify service role key, check function logs with `supabase functions logs` |
| Tickets not visible in app | RLS prevents viewing | Ensure owning user has access or assign ticket to support staff |

## Next Steps

- Extend `allowed_endpoints` enforcement in the Edge Function for granular permissions.
- Add webhook notifications to inform clients about status changes.
- Schedule token rotation reminders using Supabase cron or external tooling.
