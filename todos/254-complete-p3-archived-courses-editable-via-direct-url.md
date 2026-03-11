---
status: pending
priority: p3
issue_id: "254"
tags: [code-review, architecture, rails, authorization]
dependencies: []
---

# Archived Courses Editable via Direct URL — No Controller Guard

## Problem Statement

The UI intentionally hides the Edit link from archived course rows in `_past_courses.html.erb`. However, the controller's `edit` and `update` actions have no guard checking `course? && !course_active?`. A technically savvy user can navigate directly to `/settings/medications/:id/edit` for an archived course and modify its `ends_on` to a future date, silently "reactivating" it. The product decision on whether reactivation should be permitted is not encoded in the server layer.

Additionally, once #247 is fixed the update stream will render the correct partial, but the underlying policy gap remains.

## Findings

`app/views/settings/medications/_past_courses.html.erb` line 33: overflow menu shows only Remove, no Edit — correct UI behavior.

`app/controllers/settings/medications_controller.rb` `set_medication` (line ~81): `Current.user.medications.find(params[:id])` — scoped to user only, no course-active check.

`edit` and `update` actions: no guard for archived state.

Confirmed by: architecture-strategist, agent-native-reviewer.

## Proposed Solutions

### Option A — Add controller guard returning 404/redirect for archived courses *(Recommended)*

```ruby
before_action :ensure_course_not_archived, only: %i[edit update]

def ensure_course_not_archived
  return unless @medication.course? && !@medication.course_active?
  redirect_to settings_medications_path, notice: "Archived courses cannot be edited."
end
```

Pros: server enforces the UI contract; consistent for browser and API callers
Cons: prevents intentional reactivation (can be loosened later)

### Option B — Add Edit back to archived rows and handle the reactivation case

Accept that archived courses can be reactivated by editing `ends_on` and make this explicit in the UI.

Pros: matches clinical reality (doctors extend courses)
Cons: requires product decision; also requires #247 fix to render correct partial on update

### Option C — Document the gap and defer

Add a comment in the controller noting the implicit policy.

Pros: zero risk, no code
Cons: the gap remains exploitable; implicit rather than explicit

## Recommended Action

Option A — it's a one-method guard that costs nothing and can be removed when/if reactivation is intentionally supported.

## Technical Details

- **Affected file:** `app/controllers/settings/medications_controller.rb`

## Acceptance Criteria

- [ ] `before_action :ensure_course_not_archived` added to `edit` and `update`
- [ ] Attempting to GET `/settings/medications/:archived_course_id/edit` redirects with a notice
- [ ] Controller test added: edit/update on archived course returns redirect
- [ ] Regular medication and active course edit still work normally

## Work Log

- 2026-03-10: Found by architecture-strategist and agent-native-reviewer during Phase 18 code review
