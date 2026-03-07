---
status: pending
priority: p2
issue_id: "054"
tags: [code-review, performance, n-plus-one, json-api]
dependencies: []
---

# N+1 in `symptom_logs_json` — JSON Path Omits `includes(:rich_text_notes)`

## Problem Statement

The HTML path for `SymptomLogsController#index` uses `.includes(:rich_text_notes)` to eager-load ActionText rich text. The JSON path passes the base relation without includes, then calls `log.notes.to_plain_text` per record in `symptom_logs_json`. With 25 records per page, this fires 25 extra queries on every JSON response.

## Findings

**Flagged by:** performance-oracle (Priority 1)

**Location:** `app/controllers/symptom_logs_controller.rb`

```ruby
# HTML branch — correctly eager loads
base_relation = Current.user.symptom_logs
                       .chronological
                       .in_date_range(@start_date, @end_date)
                       .includes(:rich_text_notes)  # ✓ present

# JSON branch — passes base_relation WITHOUT includes
format.json { render json: symptom_logs_json(base_relation) }  # ✗ N+1

# The serializer touches notes per record:
def symptom_log_json(log)
  log.as_json(...).merge(notes: log.notes.to_plain_text)  # lazy loads per record
end
```

## Proposed Solutions

### Solution A: Add includes to the relation before the respond_to block (Recommended)

```ruby
base_relation = Current.user.symptom_logs
                       .chronological
                       .in_date_range(@start_date, @end_date)
                       .includes(:rich_text_notes)  # apply to both HTML and JSON paths
```

Both `format.html` and `format.json` then use the same eager-loaded relation.

- **Effort:** Tiny (1-line change)
- **Risk:** None — reduces queries from N+1 to 1

### Solution B: Add includes only in the JSON branch

```ruby
format.json do
  json_logs = base_relation.includes(:rich_text_notes)
  render json: symptom_logs_json(json_logs)
end
```

- **Effort:** Small
- **Risk:** None

## Acceptance Criteria

- [ ] `GET /symptom_logs.json` with 25 records fires ≤ 3 queries (user lookup, symptom_logs, rich_text_notes)
- [ ] No N+1 warnings in test log for JSON format
- [ ] Bullet gem (if added to dev) confirms no N+1

## Work Log

- 2026-03-07: Created from performance review. performance-oracle Priority 1.
