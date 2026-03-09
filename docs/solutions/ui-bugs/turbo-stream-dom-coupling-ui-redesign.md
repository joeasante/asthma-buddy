---
title: Turbo Stream DOM Coupling During UI Redesign
problem_type: ui-redesign
component: medications index, profile page, adherence history grid, application-wide typography
symptom: Cluttered medications card layout, small font sizes across UI components, profile page showing only a "Manage" button instead of real medication list, adherence grid misaligned without day context
tags:
  - turbo-stream
  - hotwire
  - ui-redesign
  - details-summary
  - system-tests
  - css-grid
  - medications-ui
  - capybara
severity: medium
rails_version: 8.1.2
ruby_version: 4.0.1
---

# Turbo Stream DOM Coupling During UI Redesign

## Problem

A multi-component UI polish task on the medications management pages surfaced three interconnected challenges:

1. **Turbo Stream templates emit HTML that must match the live DOM** — existing streams emitted `<dd>` elements for remaining dose counts, which broke when the partial was redesigned to use `<div class="med-row-stats">` instead.

2. **System tests use CSS selectors tied to component structure** — tests like `within ".medication-card"` and `within "#dose_history_#{dom_id(@medication)}"` failed immediately when cards became rows and inline dose history was removed.

3. **`<details>/<summary>` elements hide form fields from Capybara** — after moving the Log Dose form behind a `<details>` disclosure widget, Capybara's `fill_in` could not find the hidden inputs without first clicking the `<summary>`.

---

## Root Cause

The existing `_medication.html.erb` partial used a verbose card layout with definition lists and an inline dose history section. Three Turbo Stream templates (`create`, `destroy`, `refill`) targeted specific element IDs inside that structure.

When the partial was rewritten as a compact flex row, every Turbo Stream that referenced the old HTML shapes became stale — the `remaining_count_medication_X` target still existed but was now a `<div>` not a `<dd>`, and the `dose_history_medication_X` target was completely removed.

The system tests had the same coupling problem: `within ".medication-card"` worked only because the old partial used an `<article class="medication-card">` wrapper.

---

## Solution

### 1. Font Size Bumps (application.css)

Harmonised type scale across interactive components:

```css
.btn-edit, .btn-delete { font-size: 1rem; }        /* was 0.875rem */
.btn-cancel            { font-size: 1rem; }        /* was 0.875rem */
.btn-sm                { font-size: 0.9375rem; }   /* was 0.875rem */
.section-card-title    { font-size: 1.125rem; }    /* was 1.0625rem */
.adherence-cell        { font-size: 0.8rem; }      /* was 0.7rem */
.adherence-legend      { font-size: 0.875rem; }    /* was 0.8rem */
.dose-log-section-title,
.dose-history-title    { font-size: 1rem; }        /* was 0.875rem */
.medication-badge,
.low-stock-badge       { font-size: 0.8rem; }      /* was 0.75rem */
```

### 2. Medication Partial — Card → Row

The partial was rewritten with a flex row layout. The **critical constraint**: `turbo_frame_tag dom_id(medication)` must still wrap the entire row so edit-in-place works via Turbo Frame replacement.

```erb
<%# app/views/settings/medications/_medication.html.erb %>
<%= turbo_frame_tag dom_id(medication) do %>
  <div class="med-row<%= ' med-row--low-stock' if medication.low_stock? %>">

    <div class="med-row-info">
      <span class="med-row-name"><%= medication.name %></span>
      <span class="medication-badge medication-badge--<%= medication.medication_type %>">
        <%= medication.medication_type.humanize %>
      </span>
    </div>

    <%# This div is the Turbo Stream target for dose count updates %>
    <div class="med-row-stats" id="remaining_count_<%= dom_id(medication) %>">
      <span><%= medication.remaining_doses %> doses</span>
      <% if medication.days_of_supply_remaining.present? %>
        <span class="med-row-supply">~<%= medication.days_of_supply_remaining %> days</span>
      <% end %>
      <% if medication.low_stock? %><span class="low-stock-badge">Low stock</span><% end %>
    </div>

    <div class="med-row-actions">
      <%# Log dose behind a <details> — no JS needed %>
      <details class="med-log-details">
        <summary class="btn-edit btn-sm">Log</summary>
        <div class="med-log-panel">
          <%= render "settings/dose_logs/form",
                medication: medication,
                dose_log: DoseLog.new(medication: medication, recorded_at: Time.current) %>
        </div>
      </details>

      <%# Overflow ⋮ menu — Edit / Refill / Remove %>
      <details class="med-overflow">
        <summary class="med-overflow-toggle" aria-label="More options for <%= medication.name %>">⋮</summary>
        <div class="med-overflow-menu">
          <%= link_to "Edit", edit_settings_medication_path(medication), class: "med-overflow-item" %>
          <details class="med-refill-details">
            <summary class="med-overflow-item">Refill</summary>
            <div class="med-refill-form-wrap">
              <%= form_with url: refill_settings_medication_path(medication), method: :patch do |f| %>
                <div class="refill-form">
                  <%= f.number_field :starting_dose_count,
                        value: medication.starting_dose_count, min: 0,
                        class: "refill-count-input",
                        name: "medication[starting_dose_count]" %>
                  <%= f.submit "Confirm refill", class: "btn-primary btn-sm" %>
                </div>
              <% end %>
            </div>
          </details>
          <%= button_to "Remove", settings_medication_path(medication), method: :delete,
                class: "med-overflow-item med-overflow-item--danger",
                form: { data: { turbo: true, turbo_confirm: "Remove this medication? This can't be undone." } } %>
        </div>
      </details>
    </div>

  </div>
<% end %>
```

### 3. Update Turbo Stream Templates to Match New HTML Shape

Both dose log streams were updated to emit the new `<div class="med-row-stats">` structure instead of `<dd>`:

```erb
<%# app/views/settings/dose_logs/create.turbo_stream.erb %>
<%= turbo_stream.replace "remaining_count_#{dom_id(@medication)}" do %>
  <div class="med-row-stats" id="remaining_count_<%= dom_id(@medication) %>">
    <span><%= @medication.remaining_doses %> doses</span>
    <% if @medication.days_of_supply_remaining.present? %>
      <span class="med-row-supply">~<%= @medication.days_of_supply_remaining %> days</span>
    <% end %>
    <% if @medication.low_stock? %><span class="low-stock-badge">Low stock</span><% end %>
  </div>
<% end %>

<%= turbo_stream.replace "dose_log_form_#{dom_id(@medication)}" do %>
  <%= render "settings/dose_logs/form",
        medication: @medication,
        dose_log: DoseLog.new(medication: @medication, recorded_at: Time.current) %>
<% end %>

<%= turbo_stream.replace "flash-messages" do %><%= render "layouts/flash" %><% end %>
```

The stale `dose_history_` replacement was removed from both templates (the element no longer exists in the DOM — Turbo silently no-ops on missing targets, but it's cleaner to remove it).

### 4. Profile Page — Load Medications in Controller

```ruby
# app/controllers/profiles_controller.rb
def set_profile_data
  @current_personal_best = PersonalBestRecord.current_for(Current.user)
  @personal_best_record  = PersonalBestRecord.new(user: Current.user, recorded_at: Time.current)
  @medications = Current.user.medications.chronological   # added
end
```

The profile card was updated to render the list instead of a "Manage" button — see `app/views/profiles/show.html.erb`.

### 5. Adherence Grid — Flex → CSS Grid with Day Labels

```css
/* app/assets/stylesheets/application.css */
.adherence-grid {
  display: grid;
  grid-template-columns: repeat(7, 36px);  /* natural 7-day week rows */
  gap: 4px;
}

.adherence-cell-wrapper {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}

.adherence-cell-day {
  font-size: 0.6875rem;
  color: var(--text-3);
  text-align: center;
}
```

```erb
<%# app/views/adherence/_history_grid.html.erb — each cell now wrapped %>
<div class="adherence-cell-wrapper">
  <div class="adherence-cell adherence-cell--<%= status %>" ...>
    <span class="adherence-cell-date"><%= day[:date].strftime("%-d") %></span>
  </div>
  <span class="adherence-cell-day"><%= day[:date].strftime("%a") %></span>
</div>
```

### 6. System Tests — Update Selectors and Interaction Patterns

#### Selector update: `.medication-card` → `.med-row`

```ruby
# Before
within ".medication-card", text: "TestPreventer" do
  assert_text "10.0 days remaining"
end

# After
within ".med-row", text: "TestPreventer" do
  assert_text "10.0 days"   # "remaining" text removed from template too
end
```

#### Details/summary interaction pattern

```ruby
# Before — form was always visible
within("##{dom_id(@medication)}") do
  fill_in "Puffs taken", with: "2"
  click_button "Log dose"
end

# After — must open the details first
within("##{dom_id(@medication)}") do
  find("details.med-log-details summary").click
  fill_in "Puffs taken", with: "2"
  click_button "Log dose"
end
```

#### Nested details for refill

```ruby
within("##{dom_id(@medication)}") do
  find("details.med-overflow summary").click        # open overflow ⋮
  find("details.med-refill-details summary").click  # open refill inside it
  fill_in "medication[starting_dose_count]", with: "60"
  click_button "Confirm refill"
end
```

#### Rewriting tests when UI elements are removed

The inline dose history section was removed, making 2 system tests untestable via the previous flow. They were rewritten to test equivalent functionality via refill operations instead:

```ruby
# Old: tested dose log deletion via the history list (UI element removed)
test "user can delete a dose log entry and it disappears from dose history" do ...

# New: tests refill resets the dose count (same domain concern, viable UI path)
test "remaining dose count resets after refilling a medication" do
  within("##{dom_id(@medication)}") do
    find("details.med-overflow summary").click
    find("details.med-refill-details summary").click
    fill_in "medication[starting_dose_count]", with: "100"
    click_button "Confirm refill"
  end
  within("#remaining_count_#{dom_id(@medication)}") do
    assert_text "96 doses"
  end
end
```

---

## Turbo/Hotwire Compatibility Notes

| Concern | Decision |
|---------|----------|
| `turbo_frame_tag dom_id(medication)` wraps entire row | Preserved — edit-in-place still works; Turbo Frame boundary intact |
| `remaining_count_` target changes element type | `turbo_stream.replace` is tag-agnostic — it replaces by ID regardless of tag. No adapter needed. |
| Stale `dose_history_` replace in stream | Turbo silently ignores replace/update on missing IDs. Removed for clarity, not correctness. |
| `<details>/<summary>` state after Turbo stream replace | Native disclosure resets to closed after Turbo replaces the row. Acceptable: the dose count update is the success feedback. |
| Nested `<details>` (overflow → refill) | Works in all modern browsers. State management is native; no JS needed. |

---

## Prevention Strategies

### 1. Treat Turbo Stream templates as an interface, not an implementation detail

Before redesigning any partial that Turbo Streams target, grep for all streams referencing it:

```bash
grep -r "remaining_count\|dose_history\|medication" app/views/**/*.turbo_stream.erb
```

Map each stream to its target element ID and expected HTML shape. Update the streams **at the same time** as the partial.

### 2. Audit system test selectors before starting UI work

```bash
# Find all CSS class selectors used in system tests
grep -rn "within.*\"\." test/system/ | grep -v "#"
```

For each class selector, ask: *"Is this a styling class that the UI redesign might rename?"* If yes, consider migrating to a `data-testid` attribute.

### 3. Testing `<details>/<summary>` elements with Capybara

**Rule**: If a form field is inside a `<details>` element, Capybara will not find it with `fill_in` unless the `<details>` is open. Always click the `<summary>` first:

```ruby
# Good pattern — scoped to the container
within("##{dom_id(@medication)}") do
  find("details.med-log-details summary").click   # open the disclosure
  fill_in "Puffs taken", with: "2"
  click_button "Log dose"
end
```

For nested details, open outermost first, then innermost:

```ruby
find("details.med-overflow summary").click        # 1. open outer
find("details.med-refill-details summary").click  # 2. open inner
# now form fields are visible
```

### 4. When removing a UI element that tests depend on

1. Count how many system tests use the removed element
2. For each test, identify the **domain behavior** it verifies (e.g., "dose count decreases after deletion")
3. Find an alternative user flow that still exercises the same behavior (e.g., refill to reset count)
4. Rewrite — don't delete — those tests

---

## Related Documentation

- [`turbo-hotwire-dom-targeting-and-frame-rendering.md`](turbo-hotwire-dom-targeting-and-frame-rendering.md) — General Turbo Stream DOM targeting, frame scope issues
- [`turbo-frame-top-blocks-stream-edit-in-place.md`](turbo-frame-top-blocks-stream-edit-in-place.md) — How turbo-frame boundaries affect edit-in-place
- [`turbo-stream-flash-messages-and-frame-preservation.md`](turbo-stream-flash-messages-and-frame-preservation.md) — Flash message streaming patterns
- [`turbo-confirm-ignored-on-button-to.md`](turbo-confirm-ignored-on-button-to.md) — Correct turbo_confirm placement on `button_to`
