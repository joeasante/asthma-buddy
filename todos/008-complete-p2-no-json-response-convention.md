---
status: pending
priority: p2
issue_id: "008"
tags: [code-review, agent-native, architecture, api]
dependencies: []
---

# No JSON Response Convention Established for Future Endpoints

## Problem Statement

Phase 2+ will add `POST /session`, `POST /users`, `POST /symptom_logs`, etc. Without a decided JSON response strategy, each controller will handle non-HTML requests inconsistently (or not at all). Controllers with no `respond_to` block will raise `ActionController::UnknownFormat` for `Accept: application/json` requests. This blocks agent access to all data endpoints. Deciding now costs almost nothing; retrofitting across 6+ controllers later costs significantly more.

## Findings

**Flagged by:** agent-native-reviewer (WARNING — must decide before Phase 2)

**Location:** `app/controllers/application_controller.rb` (no JSON convention established)

The `jbuilder` gem is already in the Gemfile, signaling JSON views are anticipated — but no guidance exists for whether controllers use jbuilder views, `render json:`, or `respond_to` blocks.

## Proposed Solutions

### Option A — `respond_to` blocks in every controller with jbuilder views (Recommended)
Each resource controller uses `respond_to` and has a `.json.jbuilder` view alongside the `.html.erb` view.

```ruby
def create
  @log = SymptomLog.create!(symptom_log_params)
  respond_to do |format|
    format.html { redirect_to @log }
    format.json { render :show, status: :created }
  end
end
```

**Pros:** Clean separation; jbuilder views are explicit and testable; agent-friendly.
**Cons:** More files per feature.
**Effort:** Small per controller (document the convention now, implement in each phase)
**Risk:** None

### Option B — API module / namespace with dedicated JSON controllers
Create `api/v1/` namespace for all agent-facing endpoints.

**Pros:** Clean separation of concerns.
**Cons:** Doubles the controller count; over-engineered for this app scale.
**Effort:** Large
**Risk:** Medium

### Option C — `render json:` inline in each action
No jbuilder views; just `render json: @record` in the respond_to block.

**Pros:** Simple; no extra files.
**Cons:** Couples JSON shape to controller; hard to customize or version.
**Effort:** Small
**Risk:** Low

## Recommended Action

Option A — `respond_to` + jbuilder views. Document the convention in a project conventions file so every Phase 2–8 plan includes jbuilder views as a first-class deliverable.

## Technical Details

**Affected files:**
- `app/controllers/application_controller.rb` (add convention comment or concern)
- Each future controller

**Acceptance Criteria:**
- [ ] JSON response strategy documented (in `docs/conventions.md` or `CLAUDE.md`)
- [ ] Phase 2 plan includes jbuilder views for session and user endpoints
- [ ] An agent can call `POST /session` with `Accept: application/json` and receive a structured response

## Work Log

- 2026-03-06: Identified by agent-native-reviewer. Decision needed before Phase 2 planning.
