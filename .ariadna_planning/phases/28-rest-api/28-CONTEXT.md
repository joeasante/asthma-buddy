# Phase 28: REST API — Context

## Decisions (Locked)

### API Key Storage: Columns on User
- One API key per user (matches requirements: "an API key", "their API key")
- Columns: `api_key_digest` (string, SHA-256 hash), `api_key_created_at` (datetime)
- Plaintext shown once on generation, never stored
- No separate model — YAGNI for personal data export use case

### Pagination: Page-Based
- `?page=2&per_page=25` pattern
- Default per_page: 25, max: 100
- Simple, familiar to API consumers

### JSON Response Format: Simple Envelope
- `{ data: [...], meta: { page: 1, per_page: 25, total: 42 } }`
- Consistent error format: `{ error: { status: 422, message: "...", details: [...] } }`
- No JSON:API spec overhead

## Claude's Discretion

- API controller inheritance hierarchy (Api::V1::BaseController pattern)
- Rate limit thresholds (e.g., 60/min per key)
- Filter parameter design (date_from/date_to vs created_after/created_before)
- Whether to use Jbuilder or plain `render json:`

## Deferred Ideas

- Multiple API keys per user (separate ApiKey model)
- Cursor-based pagination
- JSON:API spec compliance
- OAuth2 / JWT tokens
